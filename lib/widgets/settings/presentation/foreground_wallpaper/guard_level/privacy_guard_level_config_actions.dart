import 'package:aves/widgets/common/extensions/build_context.dart';
import 'package:flutter/material.dart';

import '../../../../../model/foreground_wallpaper/fgw_schedule_group_helper.dart';
import '../../../../../model/foreground_wallpaper/privacy_guard_level.dart';
import '../../../../../model/foreground_wallpaper/wallpaper_schedule.dart';
import '../../../../common/action_mixins/feedback.dart';
import 'guard_level_setting_page.dart';

class PrivacyGuardLevelConfigActions with FeedbackMixin {
  final BuildContext context;
  final Function setState;

  PrivacyGuardLevelConfigActions({
    required this.context,
    required this.setState,
  });

  Color privacyItemColor(PrivacyGuardLevelRow? item){
    return item?.color ?? Theme.of(context).primaryColor;
  }
  // PrivacyGuardLevelConfig
  void applyPrivacyGuardLevelReorder(BuildContext context, List<PrivacyGuardLevelRow?> allItems, Set<PrivacyGuardLevelRow?> activeItems) {
    setState(() {
      // First, remove items not exist.      // remove relate schedules too.
      final currentItems = privacyGuardLevels.bridgeAll;
      final itemsToRemove = currentItems.where((item) => !allItems.contains(item)).toSet();
      final removeLevelIds =itemsToRemove.map((e)=>e.privacyGuardLevelID).toSet();
      privacyGuardLevels.removeEntries(itemsToRemove,type: LevelRowType.bridgeAll);
      final removedSchedules = wallpaperSchedules.bridgeAll.where((e)=>removeLevelIds.contains(e.privacyGuardLevelId)).toSet();
      wallpaperSchedules.removeEntries(removedSchedules,type: ScheduleRowType.bridgeAll);

      // according to order in allItems, reorder the data .active items first.
      int guardLevelIndex = 1;
      allItems.where((item) => activeItems.contains(item)).forEach((item) {
        privacyGuardLevels.set(
          privacyGuardLevelID: item!.privacyGuardLevelID,
          guardLevel: guardLevelIndex++,
          labelName: item.labelName,
          color: item.color!,
          isActive: true,
          type: LevelRowType.bridgeAll,
        );
      });
      // Process reordered items that are not in active items
      allItems.where((item) => !activeItems.contains(item)).forEach((item) {
        privacyGuardLevels.set(
          privacyGuardLevelID: item!.privacyGuardLevelID,
          guardLevel: guardLevelIndex++,
          labelName: item.labelName,
          color: item.color!,
          isActive: false,
          type: LevelRowType.bridgeAll,
        );
      });
      //sync bridgeRows to privacy
      privacyGuardLevels.syncBridgeToRows();
      wallpaperSchedules.syncBridgeToRows();
      allItems.sort();
      //
      showFeedback(context, FeedbackType.info, context.l10n.applyCompletedFeedback);
    });
  }

  // when add a new level, temp add to bridge. in add process,
  // it should not effect the real value, but a bridge value.
  // the bridge value will be sync to real value after tap the apply button call above apply action.
  Future<void> addPrivacyGuardLevel(BuildContext context, List<PrivacyGuardLevelRow?> allItems, Set<PrivacyGuardLevelRow?> activeItems) async {
    // add a new item to bridge.
    final newLevel = await privacyGuardLevels.newRow(1,type: LevelRowType.bridgeAll);
    debugPrint('addPrivacyGuardLevel newLevel $newLevel\n');
    await privacyGuardLevels.add({newLevel},type:LevelRowType.bridgeAll);

    // add a new group of schedule to schedules bridge.
    final bridgeSchedules =  await foregroundWallpaperHelper.newSchedulesGroup(newLevel,rowsType: ScheduleRowType.bridgeAll);
    await wallpaperSchedules.add(bridgeSchedules.toSet(),type: ScheduleRowType.bridgeAll);

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
        //final newRow = newItem as PrivacyGuardLevelRow;
        setState(() {
          // not sync until tap apply button.
          // privacyGuardLevels.syncBridgeToRows();
          final updateItem = privacyGuardLevels.bridgeAll.firstWhere((e)=> e.privacyGuardLevelID == newLevel.privacyGuardLevelID);
          allItems.add(updateItem);
          if(updateItem.isActive)activeItems.add(updateItem);
          allItems.sort();
          // privacyGuardLevels.add({newItem});
          // allItems.add(newItem);
          // if (newItem.isActive) {
          //   activeItems.add(newItem);
          // }
          // allItems.sort();
        });
      }else{
        privacyGuardLevels.removeEntries({newLevel},type:LevelRowType.bridgeAll);
        wallpaperSchedules.removeEntries(bridgeSchedules.toSet(),type: ScheduleRowType.bridgeAll);
      }
    });
  }

  Future<void> editPrivacyGuardLevel(
      BuildContext context,
      PrivacyGuardLevelRow? item,
      List<PrivacyGuardLevelRow?> allItems,
      Set<PrivacyGuardLevelRow?> activeItems) async {
    //t4y: for the all items in Config page will not be the latest data.
    final PrivacyGuardLevelRow currentLevel = privacyGuardLevels.all.firstWhere((i) => i.privacyGuardLevelID == item!.privacyGuardLevelID);
    // add a new group of schedule to schedules bridge.
    final bridgeSchedules =  wallpaperSchedules.bridgeAll.where((e)=>e.privacyGuardLevelId == currentLevel.privacyGuardLevelID);
    await Navigator.push(
      context,
        MaterialPageRoute(
        builder: (context) => GuardLevelSettingPage(
      item: currentLevel,
      schedules: bridgeSchedules.toSet(),
    ),
      // MaterialPageRoute(
      //   builder: (context) => PrivacyGuardLevelWithScheduleConfigPage(
      //     item: currentItem,
      //     allItems: allItems,
      //     activeItems: activeItems,
      //   ),
      ),
    ).then((updatedItem) async {
      if (updatedItem != null) {
        setState(() {
          final index = allItems.indexWhere(
                  (i) => i?.privacyGuardLevelID == updatedItem.privacyGuardLevelID);
          if (index != -1) {
            allItems[index] = updatedItem;
          } else {
            allItems.add(updatedItem);
          }
          if (updatedItem.isActive) {
            activeItems.add(updatedItem);
          }else{
            activeItems.remove(updatedItem);
          }
          privacyGuardLevels.setRows({updatedItem},type: LevelRowType.bridgeAll);
        });
      }
    });
  }
}
