import 'package:aves/model/foreground_wallpaper/filtersSet.dart';
import 'package:flutter/material.dart';
import '../../../../common/action_mixins/feedback.dart';
import 'filter_set_config_page.dart';

class FilterSetConfigActions with FeedbackMixin {
  final BuildContext context;
  final Function setState;

  FilterSetConfigActions({
    required this.context,
    required this.setState,
  });

  // FilterSet
  void applyFilterSet(BuildContext context, List<FiltersSetRow?> allItems, Set<FiltersSetRow?> activeItems) {
    setState(() {
      // First, remove items not exist.
      final currentItems = filtersSets.all;
      final itemsToRemove = currentItems.where((item) => !allItems.contains(item)).toSet();
      filtersSets.removeEntries(itemsToRemove);
      // Second, should use allItems to keep the reorder level.
      int filterSetNum = 1;
      allItems.where((item) => activeItems.contains(item)).forEach((item) {
        filtersSets.set(
          id: item!.id,
          orderNum: filterSetNum++,
          labelName: item.labelName,
          filters: item.filters,
          isActive: true,
        );
      });

      allItems.where((item) => !activeItems.contains(item)).forEach((item) {
        filtersSets.set(
          id: item!.id,
          orderNum: filterSetNum++,
          labelName: item.labelName,
          filters: item.filters,
          isActive: false,
        );
      });
      allItems.sort();
      showFeedback(context, FeedbackType.info, 'Apply Change completely');
    });
  }

  void addFilterSet(BuildContext context, List<FiltersSetRow?> allItems, Set<FiltersSetRow?> activeItems) {
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
          filtersSets.add({newItem});
          allItems.add(newItem);
          if (newItem.isActive) {
            activeItems.add(newItem);
          }
          allItems.sort();
        });
      }
    });
  }

  void editFilterSet(
      BuildContext context,
      FiltersSetRow? item,
      List<FiltersSetRow?> allItems,
      Set<FiltersSetRow?> activeItems) {
    //t4y: for the all items in Config page will not be the latest data.
    final FiltersSetRow currentItem = filtersSets.all.firstWhere((i) => i?.id == item!.id);
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
          filtersSets.setRows({updatedItem});
        });
      }
    });
  }
}
