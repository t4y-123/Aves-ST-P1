import 'package:aves/model/fgw/enum/fgw_schedule_item.dart';
import 'package:aves/model/fgw/guard_level.dart';
import 'package:aves/model/fgw/wallpaper_schedule.dart';
import 'package:aves/model/presentation/base_bridge_row.dart';
import 'package:aves/widgets/common/action_mixins/feedback.dart';
import 'package:aves/widgets/common/extensions/build_context.dart';
import 'package:aves/widgets/settings/presentation/foreground_wallpaper/guard_level/guard_level_schedules_sub_page.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';

class WallpaperScheduleConfigActions with FeedbackMixin {
  final BuildContext context;
  final Function setState;

  WallpaperScheduleConfigActions({
    required this.context,
    required this.setState,
  });

  // WallpaperScheduleConfig
  void applyChanges(BuildContext context, List<FgwScheduleRow?> allItems, Set<FgwScheduleRow?> activeItems) {
    setState(() {
      // First, remove items not exist.

      final currentItems = fgwSchedules.bridgeAll;
      final itemsToRemove = currentItems.where((item) => !allItems.contains(item)).toSet();
      fgwSchedules.removeRows(itemsToRemove);
      // Group items by privacyGuardLevelId
      final groupedItems = <int, List<FgwScheduleRow>>{};
      for (var item in allItems.whereType<FgwScheduleRow>()) {
        groupedItems.putIfAbsent(item.guardLevelId, () => []).add(item);
      }

      // Check and update items in the same sub-group
      for (var group in groupedItems.values) {
        final homeOrLockActive = group.any((item) =>
            (item.updateType == WallpaperUpdateType.home || item.updateType == WallpaperUpdateType.lock) &&
            activeItems.contains(item));

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
        final newRow = item?.copyWith(orderNum: orderNum++, isActive: true);
        fgwSchedules.set(
          newRow!,
          type: PresentationRowType.bridgeAll,
        );
      });

      // Process reordered items that are not in active items
      allItems.where((item) => !activeItems.contains(item)).forEach((item) {
        final newRow = item?.copyWith(orderNum: orderNum++, isActive: false);
        fgwSchedules.set(
          newRow!,
          type: PresentationRowType.bridgeAll,
        );
      });
      allItems.sort();
      fgwSchedules.syncBridgeToRows();
      //
      showFeedback(context, FeedbackType.info, context.l10n.applyCompletedFeedback);
    });
  }

  void editItem(
      BuildContext context, FgwScheduleRow? item, List<FgwScheduleRow?> allItems, Set<FgwScheduleRow?> activeItems) {
    //t4y: for the all items in Config page will not be the latest data.
    final FgwScheduleRow currentItem = fgwSchedules.bridgeAll.firstWhere((i) => i.id == item!.id);
    final curLevel = fgwGuardLevels.bridgeAll.firstWhereOrNull((e) => e.id == currentItem.guardLevelId);
    if (curLevel != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => GuardLevelScheduleSubPage(
            item: curLevel,
            schedule: currentItem,
          ),
        ),
      ).then((updatedItem) {
        final FgwScheduleRow currentItem = fgwSchedules.bridgeAll.firstWhere((i) => i.id == item!.id);
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
              // Handle WallpaperScheduleRow specific logic
              final row = updatedItem as FgwScheduleRow;
              if (row.updateType == WallpaperUpdateType.home || row.updateType == WallpaperUpdateType.lock) {
                // Remove items with the same privacyGuardLevelId
                activeItems.removeWhere((element) =>
                    element is FgwScheduleRow &&
                    element.guardLevelId == row.guardLevelId &&
                    (element.updateType == WallpaperUpdateType.both));
              } else if (row.updateType == WallpaperUpdateType.both) {
                // Remove items with the same privacyGuardLevelId and updateType is home or lock
                activeItems.removeWhere((element) =>
                    element is FgwScheduleRow &&
                    element.guardLevelId == row.guardLevelId &&
                    (element.updateType == WallpaperUpdateType.home || element.updateType == WallpaperUpdateType.lock));
              }
              activeItems.add(updatedItem);
            } else {
              activeItems.remove(updatedItem);
            }
          });
        }
      });
    }
  }
}
