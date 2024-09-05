import 'package:aves/model/assign/assign_entries.dart';
import 'package:aves/model/assign/assign_record.dart';
import 'package:aves/model/presentation/base_bridge_row.dart';
import 'package:aves/widgets/common/action_mixins/feedback.dart';
import 'package:aves/widgets/common/extensions/build_context.dart';
import 'package:aves/widgets/settings/presentation/assign/sub_page/assign_record_item_page.dart';
import 'package:aves/widgets/settings/presentation/common/config_actions.dart';
import 'package:flutter/material.dart';

class AssignRecordActions extends BridgeConfigActions<AssignRecordRow> {
  Set<AssignEntryRow>? relateItems;

  AssignRecordActions({
    required super.context,
    required super.setState,
  }) : super(
          presentationRows: assignRecords,
        );

  @override
  void applyChanges(BuildContext context, List<AssignRecordRow?> allItems, Set<AssignRecordRow?> activeItems) {
    // First, remove relate schedules too.
    final currentItems = assignRecords.bridgeAll;
    final itemsToRemove = currentItems.where((item) => !allItems.contains(item)).toSet();
    final removeLevelIds = itemsToRemove.map((e) => e.id).toSet();
    assignRecords.removeRows(itemsToRemove, type: PresentationRowType.bridgeAll);
    //
    final removedSchedules = assignEntries.bridgeAll.where((e) => removeLevelIds.contains(e.assignId)).toSet();
    assignEntries.removeRows(removedSchedules, type: PresentationRowType.bridgeAll);
    // then call the super to apply changes to guard level
    super.applyChanges(context, allItems, activeItems);
    assignEntries.syncBridgeToRows();
  }

  @override
  void resetChanges(BuildContext context, List<AssignRecordRow?> allItems, Set<AssignRecordRow?> activeItems) {
    setState(() {
      // First, reset Rows
      assignRecords.syncRowsToBridge();
      assignEntries.syncRowsToBridge();
      allItems.sort();
      showFeedback(context, FeedbackType.info, context.l10n.applyCompletedFeedback);
    });
  }

  @override
  AssignRecordRow incrementRowWithActive(int incrementNum, AssignRecordRow srcItem, bool active) {
    return srcItem.copyWith(orderNum: incrementNum, isActive: active);
  }

  @override
  Widget getItemPage(AssignRecordRow item) {
    return AssignRecordItemPage(item: item);
  }

  @override
  Future<void> opItem(BuildContext context, [AssignRecordRow? item]) async {
    if (item != null) {
      relateItems = assignEntries.bridgeAll.where((e) => e.assignId == item.id).toSet();
    }
    await super.opItem(context, item);
  }

  @override
  Future<void> removeRelateRow(AssignRecordRow item) async {
    if (relateItems != null) {
      await assignEntries.removeRows(relateItems!, type: PresentationRowType.bridgeAll);
    }
  }

  @override
  Future<void> resetRelateRow(AssignRecordRow item) async {
    if (relateItems != null) {
      await assignEntries.setRows(relateItems!, type: PresentationRowType.bridgeAll);
    }
  }

  @override
  Future<AssignRecordRow> makeNewRow() {
    // TODO: implement makeNewRow
    throw UnimplementedError();
  }
}
