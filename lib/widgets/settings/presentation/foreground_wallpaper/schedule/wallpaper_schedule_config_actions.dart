import 'package:aves/model/foreground_wallpaper/privacy_guard_level.dart';
import 'package:aves/widgets/common/extensions/build_context.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';

import '../../../../../model/foreground_wallpaper/enum/fgw_schedule_item.dart';
import '../../../../../model/foreground_wallpaper/wallpaper_schedule.dart';
import '../../../../common/action_mixins/feedback.dart';
import '../guard_level/guard_level_schedules_sub_page.dart';

class WallpaperScheduleConfigActions with FeedbackMixin {
  final BuildContext context;
  final Function setState;

  WallpaperScheduleConfigActions({
    required this.context,
    required this.setState,
  });

  // WallpaperScheduleConfig
  void applyWallpaperScheduleReorder(BuildContext context, List<WallpaperScheduleRow?> allItems,
      Set<WallpaperScheduleRow?> activeItems) {
    setState(() {
      // First, remove items not exist.

      final currentItems = wallpaperSchedules.bridgeAll;
      final itemsToRemove = currentItems.where((item) => !allItems.contains(item)).toSet();
      wallpaperSchedules.removeEntries(itemsToRemove);
      // Group items by privacyGuardLevelId
      final groupedItems = <int, List<WallpaperScheduleRow>>{};
      for (var item in allItems.whereType<WallpaperScheduleRow>()) {
        groupedItems.putIfAbsent(item.privacyGuardLevelId, () => []).add(item);
      }

      // Check and update items in the same sub-group
      for (var group in groupedItems.values) {
        final homeOrLockActive = group.any((item) =>
        (item.updateType == WallpaperUpdateType.home || item.updateType == WallpaperUpdateType.lock)
            && activeItems.contains(item));

        if (homeOrLockActive) {
          for (var item in group) {
            if (item.updateType == WallpaperUpdateType.both && activeItems.contains(item)) {
              allItems.remove(item);
              activeItems.remove(item);
            allItems.add(item.copyWith(isActive: false));
            }
          }
        }
      }

      // Second, should use allItems to keep the reorder level.
      int orderNum = 1;
      allItems.where((item) => activeItems.contains(item)).forEach((item) {
        wallpaperSchedules.set(
          id: item!.id,
          isActive: true,
          orderNum: orderNum++,
          labelName: '',
          privacyGuardLevelId: item.privacyGuardLevelId,
          filtersSetId: item.filtersSetId,
          updateType: item.updateType,
          widgetId: item.widgetId,
          displayType: item.displayType,
          intervalTime: item.interval,
          type: ScheduleRowType.bridgeAll,
        );
      });

      // Process reordered items that are not in active items
      allItems.where((item) => !activeItems.contains(item)).forEach((item) {
        wallpaperSchedules.set(
          id: item!.id,
          isActive: false,
          orderNum: orderNum++,
          labelName: '',
          privacyGuardLevelId: item.privacyGuardLevelId,
          filtersSetId: item.filtersSetId,
          updateType: item.updateType,
          widgetId: item.widgetId,
          displayType: item.displayType,
          intervalTime: item.interval,
          type: ScheduleRowType.bridgeAll,
        );
      });
      allItems.sort();
      wallpaperSchedules.syncBridgeToRows();
      //
      showFeedback(context, FeedbackType.info, context.l10n.applyCompletedFeedback);
    });
  }

  Future<void> addWallpaperSchedule(BuildContext context, List<WallpaperScheduleRow?> allItems,
      Set<WallpaperScheduleRow?> activeItems) async {
    // await showDialog(
    //   context: context,
    //   builder: (context) {
    //     return AlertDialog(
    //       title: Text('$action Action'),
    //       content: Text('Widget not defined for $action action'),
    //       actions: [
    //         TextButton(
    //           onPressed: () => Navigator.of(context).pop(),
    //           child: const Text('OK'),
    //         ),
    //       ],
    //     );
    //   },
    // );
    // Navigator.push(
    //   context,
    //   MaterialPageRoute(
    //     builder: (context) => WallpaperScheduleConfigPage(
    //       item: null, // Pass null to create a new item
    //       allItems: allItems,
    //       activeItems: activeItems,
    //     ),
    //   ),
    // ).then((newItem) {
    //
    //   if (newItem != null) {
    //     //final newRow = newItem as WallpaperScheduleRow;
    //     setState(() {
    //       wallpaperSchedules.add({newItem});
    //       allItems.add(newItem);
    //       if (newItem.isActive) {
    //         activeItems.add(newItem);
    //       }
    //       allItems.sort();
    //     });
    //   }
    // });
  }

  void editWallpaperSchedule(BuildContext context, WallpaperScheduleRow? item, List<WallpaperScheduleRow?> allItems,
      Set<WallpaperScheduleRow?> activeItems) {
    //t4y: for the all items in Config page will not be the latest data.
    final WallpaperScheduleRow currentItem = wallpaperSchedules.bridgeAll.firstWhere((i) => i?.id == item!.id);
    final curLevel =
    privacyGuardLevels.bridgeAll.firstWhereOrNull((e) => e.privacyGuardLevelID == currentItem.privacyGuardLevelId);
    if (curLevel != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              GuardLevelScheduleSubPage(
                item: curLevel,
                schedule: currentItem!,
              ),
        ),
      ).then((updatedItem) {
        final WallpaperScheduleRow currentItem = wallpaperSchedules.bridgeAll.firstWhere((i) => i?.id == item!.id);
        updatedItem = currentItem;
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
            wallpaperSchedules.setRows({updatedItem});
          });
        }
      });
    }
  }
}
