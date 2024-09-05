import 'package:aves/model/fgw/filters_set.dart';
import 'package:aves/model/fgw/wallpaper_schedule.dart';
import 'package:aves/model/presentation/base_bridge_row.dart';
import 'package:aves/widgets/settings/presentation/common/config_actions.dart';
import 'package:aves/widgets/settings/presentation/foreground_wallpaper/sub_page/schedule_item_page.dart';
import 'package:flutter/material.dart';

class FgwScheduleActions extends BridgeConfigActions<FgwScheduleRow> {
  FgwScheduleActions({
    required super.context,
    required super.setState,
  }) : super(
          presentationRows: fgwSchedules,
        );

  @override
  FgwScheduleRow incrementRowWithActive(int incrementNum, FgwScheduleRow srcItem, bool active) {
    return srcItem.copyWith(orderNum: incrementNum, isActive: active);
  }

  @override
  void applyChanges(BuildContext context, List<FgwScheduleRow?> allItems, Set<FgwScheduleRow?> activeItems) {
    filtersSets.syncBridgeToRows();
    // then call the super to apply changes to guard level
    super.applyChanges(context, allItems, activeItems);
    filtersSets.syncBridgeToRows();
    fgwSchedules.syncBridgeToRows();
  }

  @override
  Widget getItemPage(FgwScheduleRow item) {
    return FgwScheduleItemPage(item: item);
  }

  @override
  Future<void> activeItem(BuildContext context, [FgwScheduleRow? item]) async {
    if (item != null) {
      final newRow = item.copyWith(isActive: !item.isActive);
      await fgwSchedules.setWithDealConflictUpdateType({newRow}, type: PresentationRowType.bridgeAll);
    }
  }

  @override
  Future<FgwScheduleRow> makeNewRow() {
    // can not add a new schedule without add a guard level.
    throw UnimplementedError();
  }
}
