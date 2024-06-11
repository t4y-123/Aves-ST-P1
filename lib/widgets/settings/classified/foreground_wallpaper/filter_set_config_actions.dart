import 'package:aves/model/foreground_wallpaper/filterSet.dart';
import 'package:flutter/material.dart';
import '../../../common/action_mixins/feedback.dart';
import 'filter_set_config_page.dart';

class FilterSetConfigActions with FeedbackMixin {
  final BuildContext context;
  final Function setState;

  FilterSetConfigActions({
    required this.context,
    required this.setState,
  });

  // FilterSet
  void applyFilterSet(BuildContext context, List<FilterSetRow?> allItems, Set<FilterSetRow?> activeItems) {
    setState(() {
      // First, remove items not exist.
      final currentItems = filterSet.all;
      final itemsToRemove = currentItems.where((item) => !allItems.contains(item)).toSet();
      filterSet.removeEntries(itemsToRemove);
      // Second, should use allItems to keep the reorder level.
      int filterSetNum = 1;
      allItems.where((item) => activeItems.contains(item)).forEach((item) {
        filterSet.set(
          filterSetId: item!.filterSetId,
          filterSetNum: filterSetNum++,
          aliasName: item.aliasName,
          filters: item.filters,
        );
      });
      showFeedback(context, FeedbackType.info, 'Apply Change completely');
    });
  }

  void addFilterSet(BuildContext context, List<FilterSetRow?> allItems, Set<FilterSetRow?> activeItems) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FilterSetConfigPage(
          item: null, // Pass null to create a new item
          allItems: allItems,
          activeItems: activeItems,
        ),
      ),
    ).then((newItem) {
      if (newItem != null) {
        //final newRow = newItem as FilterSetRow;
        setState(() {
          filterSet.add({newItem});
          allItems.add(newItem);
          activeItems.add(newItem);
          allItems.sort();
        });
      }
    });
  }

  void editFilterSet(
      BuildContext context,
      FilterSetRow? item,
      List<FilterSetRow?> allItems,
      Set<FilterSetRow?> activeItems) {
    //t4y: for the all items in Config page will not be the latest data.
    final FilterSetRow currentItem = filterSet.all.firstWhere((i) => i?.filterSetId == item!.filterSetId);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FilterSetConfigPage(
          item: currentItem,
          allItems: allItems,
          activeItems: activeItems,
        ),
      ),
    ).then((updatedItem) {
      if (updatedItem != null) {
        setState(() {
          final index = allItems.indexWhere(
                  (i) => i?.filterSetId == updatedItem.filterSetId);
          if (index != -1) {
            allItems[index] = updatedItem;
          } else {
            allItems.add(updatedItem);
          }
          activeItems.add(updatedItem);
          filterSet.setRows({updatedItem});
        });
      }
    });
  }
}
