import 'package:aves/model/fgw/fgw_schedule_group_helper.dart';
import 'package:aves/model/fgw/guard_level.dart';
import 'package:aves/model/fgw/wallpaper_schedule.dart';
import 'package:aves/model/presentation/base_bridge_row.dart';
import 'package:aves/widgets/common/action_mixins/feedback.dart';
import 'package:aves/widgets/common/extensions/build_context.dart';
import 'package:aves/widgets/settings/presentation/foreground_wallpaper/guard_level/guard_level_setting_page.dart';
import 'package:flutter/material.dart';

class PrivacyGuardLevelConfigActions with FeedbackMixin {
  final BuildContext context;
  final Function setState;

  PrivacyGuardLevelConfigActions({
    required this.context,
    required this.setState,
  });

  Color privacyItemColor(FgwGuardLevelRow? item) {
    return item?.color ?? Theme.of(context).primaryColor;
  }

  // PrivacyGuardLevelConfig
  void applyChanges(BuildContext context, List<FgwGuardLevelRow?> allItems, Set<FgwGuardLevelRow?> activeItems) {
    setState(() {
      // First, remove items not exist.      // remove relate schedules too.
      final currentItems = fgwGuardLevels.bridgeAll;
      final itemsToRemove = currentItems.where((item) => !allItems.contains(item)).toSet();
      final removeLevelIds = itemsToRemove.map((e) => e.id).toSet();
      fgwGuardLevels.removeRows(itemsToRemove, type: PresentationRowType.bridgeAll);
      final removedSchedules = fgwSchedules.bridgeAll.where((e) => removeLevelIds.contains(e.guardLevelId)).toSet();
      fgwSchedules.removeRows(removedSchedules, type: PresentationRowType.bridgeAll);

      // according to order in allItems, reorder the data .active items first.
      int guardLevelIndex = 1;
      allItems.where((item) => activeItems.contains(item)).forEach((item) {
        final newRow = item?.copyWith(guardLevel: guardLevelIndex++, isActive: true);
        fgwGuardLevels.set(newRow!, type: PresentationRowType.bridgeAll);
      });
      // Process reordered items that are not in active items
      allItems.where((item) => !activeItems.contains(item)).forEach((item) {
        final newRow = item?.copyWith(guardLevel: guardLevelIndex++, isActive: false);
        fgwGuardLevels.set(newRow!, type: PresentationRowType.bridgeAll);
      });
      //sync bridgeRows to privacy
      fgwGuardLevels.syncBridgeToRows();
      fgwSchedules.syncBridgeToRows();
      allItems.sort();
      //
      showFeedback(context, FeedbackType.info, context.l10n.applyCompletedFeedback);
    });
  }

  // when add a new level, temp add to bridge. in add process,
  // it should not effect the real value, but a bridge value.
  // the bridge value will be sync to real value after tap the apply button call above apply action.
  Future<void> addNewItem(
      BuildContext context, List<FgwGuardLevelRow?> allItems, Set<FgwGuardLevelRow?> activeItems) async {
    // add a new item to bridge.
    final newLevel = await fgwGuardLevels.newRow(1, type: PresentationRowType.bridgeAll);
    debugPrint('addPrivacyGuardLevel newLevel $newLevel\n');
    await fgwGuardLevels.add({newLevel}, type: PresentationRowType.bridgeAll);

    // add a new group of schedule to schedules bridge.
    final bridgeSchedules =
        await foregroundWallpaperHelper.newSchedulesGroup(newLevel, rowsType: PresentationRowType.bridgeAll);
    await fgwSchedules.add(bridgeSchedules.toSet(), type: PresentationRowType.bridgeAll);

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GuardLevelSettingPage(
          item: newLevel,
          schedules: bridgeSchedules.toSet(),
        ),
        // builder: (context) => PrivacyGuardLevelWithScheduleConfigPage(
        //   item: null, // Pass null to create a new item
        //   allItems: allItems,
        //   activeItems: activeItems,
        // ),
      ),
    ).then((newItem) {
      if (newItem != null) {
        //final newRow = newItem as FgwGuardLevelRow;
        setState(() {
          // not sync until tap apply button.
          // fgwGuardLevels.syncBridgeToRows();
          final updateItem = fgwGuardLevels.bridgeAll.firstWhere((e) => e.id == newLevel.id);
          allItems.add(updateItem);
          if (updateItem.isActive) activeItems.add(updateItem);
          allItems.sort();
          // fgwGuardLevels.add({newItem});
          // allItems.add(newItem);
          // if (newItem.isActive) {
          //   activeItems.add(newItem);
          // }
          // allItems.sort();
        });
      } else {
        fgwGuardLevels.removeRows({newLevel}, type: PresentationRowType.bridgeAll);
        fgwSchedules.removeRows(bridgeSchedules.toSet(), type: PresentationRowType.bridgeAll);
      }
    });
  }

  Future<void> editItem(BuildContext context, FgwGuardLevelRow? item, List<FgwGuardLevelRow?> allItems,
      Set<FgwGuardLevelRow?> activeItems) async {
    //t4y: for the all items in Config page will not be the latest data.
    final FgwGuardLevelRow currentLevel = fgwGuardLevels.all.firstWhere((i) => i.id == item!.id);
    // add a new group of schedule to schedules bridge.
    final bridgeSchedules = fgwSchedules.bridgeAll.where((e) => e.guardLevelId == currentLevel.id);
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GuardLevelSettingPage(
          item: currentLevel,
          schedules: bridgeSchedules.toSet(),
        ),
      ),
    ).then((updatedItem) async {
      if (updatedItem != null) {
        setState(() {
          final index = allItems.indexWhere((i) => i?.id == updatedItem.id);
          if (index != -1) {
            allItems[index] = updatedItem;
          } else {
            allItems.add(updatedItem);
          }
          if (updatedItem.isActive) {
            activeItems.add(updatedItem);
          } else {
            activeItems.remove(updatedItem);
          }
          fgwGuardLevels.setRows({updatedItem}, type: PresentationRowType.bridgeAll);
        });
      }
    });
  }
}
