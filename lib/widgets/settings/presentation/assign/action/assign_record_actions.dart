import 'package:aves/model/assign/assign_entries.dart';
import 'package:aves/model/assign/assign_record.dart';
import 'package:aves/widgets/common/action_mixins/feedback.dart';
import 'package:aves/widgets/common/extensions/build_context.dart';
import 'package:aves/widgets/settings/presentation/assign/sub_page/assign_record_edit_page.dart';
import 'package:flutter/material.dart';

class AssignRecordActions with FeedbackMixin {
  final BuildContext context;
  final Function setState;

  AssignRecordActions({
    required this.context,
    required this.setState,
  });

  Color privacyItemColor(AssignRecordRow? item) {
    return item?.color ?? Theme.of(context).primaryColor;
  }

  // AssignRecord
  void applyScenarioBaseReorder(
      BuildContext context, List<AssignRecordRow?> allItems, Set<AssignRecordRow?> activeItems) {
    setState(() {
      // First, remove items not exist.      // remove relate schedules too.
      final currentItems = assignRecords.bridgeAll;
      final itemsToRemove = currentItems.where((item) => !allItems.contains(item)).toSet();
      // remove assignRecords
      final removeBaseIds = itemsToRemove.map((e) => e.id).toSet();
      assignRecords.removeRows(itemsToRemove, type: AssignRecordRowsType.bridgeAll);
      // remove assign entries record
      final removeEntries = assignEntries.bridgeAll.where((e) => removeBaseIds.contains(e.assignId)).toSet();
      assignEntries.removeRows(removeEntries, type: AssignEntryRowsType.bridgeAll);

      // according to order in allItems, reorder the data .active items first.
      int starOrderNum = 1;
      allItems.where((item) => activeItems.contains(item)).forEach((item) {
        assignRecords.set(
          id: item!.id,
          orderNum: starOrderNum++,
          labelName: item.labelName,
          assignType: item.assignType,
          color: item.color!,
          isActive: true,
          dateMillis: item.dateMillis,
          type: AssignRecordRowsType.bridgeAll,
        );
      });
      // Process reordered items that are not in active items
      allItems.where((item) => !activeItems.contains(item)).forEach((item) {
        assignRecords.set(
          id: item!.id,
          orderNum: starOrderNum++,
          labelName: item.labelName,
          assignType: item.assignType,
          color: item.color!,
          isActive: false,
          dateMillis: item.dateMillis,
          type: AssignRecordRowsType.bridgeAll,
        );
      });
      //sync bridgeRows to privacy
      assignRecords.syncBridgeToRows();
      assignEntries.syncBridgeToRows();
      allItems.sort();
      //
      showFeedback(context, FeedbackType.info, context.l10n.applyCompletedFeedback);
    });
  }

  // when add a new item, temp add to bridge. in add process,
  // it should not effect the real value, but a bridge value.
  // the bridge value will be sync to real value after tap the apply button call above apply action.

  Future<void> editSelectedItem(BuildContext context, AssignRecordRow? item, List<AssignRecordRow?> allItems,
      Set<AssignRecordRow?> activeItems) async {
    //t4y: for the all items in Config page will not be the latest data.
    final AssignRecordRow curItem = assignRecords.bridgeAll.firstWhere((i) => i.id == item!.id);

    final subItems = assignEntries.bridgeAll.where((e) => e.assignId == curItem.id).toSet();
    // add a new group of schedule to schedules bridge.
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AssignRecordSettingPage(
          item: curItem,
          subItems: subItems,
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
          assignRecords.setRows({updatedItem}, type: AssignRecordRowsType.bridgeAll);
        });
      }
    });
  }
}
