import 'package:aves/model/fgw/fgw_rows_helper.dart';
import 'package:aves/model/fgw/fgw_schedule_helper.dart';
import 'package:aves/model/fgw/filters_set.dart';
import 'package:aves/model/fgw/guard_level.dart';
import 'package:aves/model/fgw/wallpaper_schedule.dart';
import 'package:aves/model/presentation/base_bridge_row.dart';
import 'package:aves/widgets/common/action_mixins/feedback.dart';
import 'package:aves/widgets/common/extensions/build_context.dart';
import 'package:aves/widgets/settings/presentation/common/config_actions.dart';
import 'package:aves/widgets/settings/presentation/foreground_wallpaper/sub_page/guard_level_item_page.dart';
import 'package:flutter/material.dart';

class GuardLevelActions extends BridgeConfigActions<FgwGuardLevelRow> {
  Set<FgwScheduleRow>? relateSchedules;
  Set<FiltersSetRow>? relateFiltersSets;

  GuardLevelActions({
    required super.context,
    required super.setState,
  }) : super(
          presentationRows: fgwGuardLevels,
        );

  Color privacyItemColor(BuildContext context, FgwGuardLevelRow? item) {
    return item?.color ?? Theme.of(context).primaryColor;
  }

  @override
  void applyChanges(BuildContext context, List<FgwGuardLevelRow?> allItems, Set<FgwGuardLevelRow?> activeItems) {
    // First, remove relate schedules too.
    final currentItems = fgwGuardLevels.bridgeAll;
    final itemsToRemove = currentItems.where((item) => !allItems.contains(item)).toSet();
    final removeLevelIds = itemsToRemove.map((e) => e.id).toSet();
    fgwGuardLevels.removeRows(itemsToRemove, type: PresentationRowType.bridgeAll);
    final removedSchedules = fgwSchedules.bridgeAll.where((e) => removeLevelIds.contains(e.guardLevelId)).toSet();
    fgwSchedules.removeRows(removedSchedules, type: PresentationRowType.bridgeAll);
    // then call the super to apply changes to guard level
    super.applyChanges(context, allItems, activeItems);

    filtersSets.syncBridgeToRows();
    fgwSchedules.syncBridgeToRows();
    fgwGuardLevels.syncBridgeToRows();
  }

  @override
  void resetChanges(BuildContext context, List<FgwGuardLevelRow?> allItems, Set<FgwGuardLevelRow?> activeItems) {
    setState(() {
      // First, reset Rows
      fgwGuardLevels.syncRowsToBridge();
      filtersSets.syncRowsToBridge();
      fgwSchedules.syncRowsToBridge();
      allItems.sort();
      showFeedback(context, FeedbackType.info, context.l10n.applyCompletedFeedback);
    });
  }

  @override
  FgwGuardLevelRow incrementRowWithActive(int incrementNum, FgwGuardLevelRow srcItem, bool active) {
    return srcItem.copyWith(guardLevel: incrementNum, isActive: active);
  }

  @override
  Widget getItemPage(FgwGuardLevelRow item) {
    return GuardLevelItemPage(item: item);
  }

  @override
  Future<void> opItem(BuildContext context, [FgwGuardLevelRow? item]) async {
    if (item != null) {
      relateSchedules = await fgwScheduleHelper.getGuardLevelSchedules(
          curFgwGuardLevel: item, rowsType: PresentationRowType.bridgeAll);
    }
    await super.opItem(context, item);
  }

  @override
  Future<void> removeRelateRow(FgwGuardLevelRow item) async {
    if (relateSchedules != null) {
      await fgwSchedules.removeRows(relateSchedules!, type: PresentationRowType.bridgeAll);
    }
    if (relateFiltersSets != null) {
      await filtersSets.removeRows(relateFiltersSets!, type: PresentationRowType.bridgeAll);
    }
  }

  @override
  Future<void> resetRelateRow(FgwGuardLevelRow item) async {
    if (relateSchedules != null) {
      await fgwSchedules.setWithDealConflictUpdateType(relateSchedules!, type: PresentationRowType.bridgeAll);
    }
    if (relateFiltersSets != null) {
      await filtersSets.setRows(relateFiltersSets!, type: PresentationRowType.bridgeAll);
    }
  }

  @override
  Future<FgwGuardLevelRow> makeNewRow() async {
    final newRow = await fgwGuardLevels.newRow(1, type: PresentationRowType.bridgeAll);
    await fgwGuardLevels.add({newRow}, type: PresentationRowType.bridgeAll);

    final newMap = await fgwRowsHelper.newSchedulesGroup(newRow, rowsType: PresentationRowType.bridgeAll);

    List<FiltersSetRow> newFilters = newMap[FgwRowsHelper.newFilters] as List<FiltersSetRow>;
    List<FgwScheduleRow> newSchedule = newMap[FgwRowsHelper.newSchedules] as List<FgwScheduleRow>;

    relateSchedules = newSchedule.toSet();
    relateFiltersSets = newFilters.toSet();

    await filtersSets.add(newFilters.toSet(), type: PresentationRowType.bridgeAll);
    await fgwSchedules.add(newSchedule.toSet(), type: PresentationRowType.bridgeAll);
    return newRow;
  }
}
