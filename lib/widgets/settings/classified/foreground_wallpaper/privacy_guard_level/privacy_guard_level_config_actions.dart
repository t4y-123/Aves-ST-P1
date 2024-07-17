import 'package:aves/widgets/settings/classified/foreground_wallpaper/privacy_guard_level/privacy_guard_level_with_schedule_config_page.dart';
import 'package:flutter/material.dart';

import '../../../../../model/foreground_wallpaper/privacy_guard_level.dart';
import '../../../../common/action_mixins/feedback.dart';

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
      // First, remove items not exist.
      final currentItems = privacyGuardLevels.all;
      final itemsToRemove = currentItems.where((item) => !allItems.contains(item)).toSet();
      privacyGuardLevels.removeEntries(itemsToRemove);

      // Second, should use allItems to keep the reorder level.
      int guardLevelIndex = 1;
      allItems.where((item) => activeItems.contains(item)).forEach((item) {
        privacyGuardLevels.set(
          privacyGuardLevelID: item!.privacyGuardLevelID,
          guardLevel: guardLevelIndex++,
          labelName: item.labelName,
          color: item.color!,
          isActive: true,
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
        );
      });
      allItems.sort();
      //
      showFeedback(context, FeedbackType.info, 'Apply Change completely');
    });
  }

  void addPrivacyGuardLevel(BuildContext context, List<PrivacyGuardLevelRow?> allItems, Set<PrivacyGuardLevelRow?> activeItems) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PrivacyGuardLevelWithScheduleConfigPage(
          item: null, // Pass null to create a new item
          allItems: allItems,
          activeItems: activeItems,
        ),
      ),
    ).then((newItem) {
      if (newItem != null) {
        //final newRow = newItem as PrivacyGuardLevelRow;
        setState(() {
          privacyGuardLevels.add({newItem});
          allItems.add(newItem);
          if (newItem.isActive) {
            activeItems.add(newItem);
          }
          allItems.sort();
        });
      }
    });
  }

  void editPrivacyGuardLevel(
      BuildContext context,
      PrivacyGuardLevelRow? item,
      List<PrivacyGuardLevelRow?> allItems,
      Set<PrivacyGuardLevelRow?> activeItems) {
    //t4y: for the all items in Config page will not be the latest data.
    final PrivacyGuardLevelRow currentItem = privacyGuardLevels.all.firstWhere((i) => i.privacyGuardLevelID == item!.privacyGuardLevelID);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PrivacyGuardLevelWithScheduleConfigPage(
          item: currentItem,
          allItems: allItems,
          activeItems: activeItems,
        ),
      ),
    ).then((updatedItem) {
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
          privacyGuardLevels.setRows({updatedItem});
        });
      }
    });
  }
}
