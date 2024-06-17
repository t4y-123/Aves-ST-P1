import 'package:aves/widgets/settings/classified/foreground_wallpaper/schedule/wallpaper_schedule_config_page.dart';
import 'package:flutter/material.dart';

import '../../../../../model/foreground_wallpaper/wallpaperSchedule.dart';
import '../../../../common/action_mixins/feedback.dart';

class WallpaperScheduleConfigActions with FeedbackMixin {
  final BuildContext context;
  final Function setState;

  WallpaperScheduleConfigActions({
    required this.context,
    required this.setState,
  });

  // WallpaperScheduleConfig
  void applyWallpaperScheduleReorder(BuildContext context, List<WallpaperScheduleRow?> allItems, Set<WallpaperScheduleRow?> activeItems) {
    setState(() {
      // First, remove items not exist.
      final currentItems = wallpaperSchedules.all;
      final itemsToRemove = currentItems.where((item) => !allItems.contains(item)).toSet();
      wallpaperSchedules.removeEntries(itemsToRemove);

      // Second, should use allItems to keep the reorder level.
      int guardLevelIndex = 1;
      allItems.where((item) => activeItems.contains(item)).forEach((item) {
        // wallpaperSchedules.set(
        //   id: item!.id,
        //   aliasName: item.aliasName,
        //   scheduleNum: guardLevelIndex++,
        //   isActive: true,
        // );
      });

      // Process reordered items that are not in active items
      allItems.where((item) => !activeItems.contains(item)).forEach((item) {
      //   wallpaperSchedules.set(
      //     id: item!.id,
      //     aliasName: item.aliasName,
      //     scheduleNum: guardLevelIndex++,
      //     isActive: false,
      //   );
      });
      allItems.sort();
      //
      showFeedback(context, FeedbackType.info, 'Apply Change completely');
    });
  }

  void addWallpaperSchedule(BuildContext context, List<WallpaperScheduleRow?> allItems, Set<WallpaperScheduleRow?> activeItems) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WallpaperScheduleConfigPage(
          item: null, // Pass null to create a new item
          allItems: allItems,
          activeItems: activeItems,
        ),
      ),
    ).then((newItem) {
      if (newItem != null) {
        //final newRow = newItem as WallpaperScheduleRow;
        setState(() {
          wallpaperSchedules.add({newItem});
          allItems.add(newItem);
          if (newItem.isActive) {
            activeItems.add(newItem);
          }
          allItems.sort();
        });
      }
    });
  }

  void editWallpaperSchedule(
      BuildContext context,
      WallpaperScheduleRow? item,
      List<WallpaperScheduleRow?> allItems,
      Set<WallpaperScheduleRow?> activeItems) {
    //t4y: for the all items in Config page will not be the latest data.
    final WallpaperScheduleRow currentItem = wallpaperSchedules.all.firstWhere((i) => i?.id == item!.id);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WallpaperScheduleConfigPage(
          item: currentItem,
          allItems: allItems,
          activeItems: activeItems,
        ),
      ),
    ).then((updatedItem) {
      if (updatedItem != null) {
        setState(() {
          final index = allItems.indexWhere(
                  (i) => i?.id == updatedItem.id);
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
          wallpaperSchedules.setRows({updatedItem});
        });
      }
    });
  }
}
