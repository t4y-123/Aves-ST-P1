import 'package:aves/model/fgw/fgw_schedule_group_helper.dart';
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
  GuardLevelActions({
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
  Future<FgwGuardLevelRow> makeNewRow() async {
    final newRow = await fgwGuardLevels.newRow(1, type: PresentationRowType.bridgeAll);
    await presentationRows.add({newRow}, type: PresentationRowType.bridgeAll);
    final bridgeSchedules =
        await foregroundWallpaperHelper.newSchedulesGroup(newRow, rowsType: PresentationRowType.bridgeAll);
    await fgwSchedules.add(bridgeSchedules.toSet(), type: PresentationRowType.bridgeAll);
    return newRow;
  }
}
