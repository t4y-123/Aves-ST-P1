import 'package:aves/model/assign/assign_entries.dart';
import 'package:aves/model/assign/assign_record.dart';
import 'package:aves/model/presentation/base_bridge_row.dart';
import 'package:aves/model/source/collection_source.dart';
import 'package:aves/widgets/common/action_mixins/feedback.dart';
import 'package:aves/widgets/common/extensions/build_context.dart';
import 'package:aves/widgets/settings/presentation/common/config_actions.dart';
import 'package:aves/widgets/viewer/entry_viewer_page.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AssignEntriesActions extends BridgeConfigActions<AssignEntryRow> {
  AssignEntriesActions({
    required super.context,
    required super.setState,
  }) : super(
          presentationRows: assignEntries,
        );

  @override
  AssignEntryRow incrementRowWithActive(int incrementNum, AssignEntryRow srcItem, bool active) {
    return srcItem.copyWith(orderNum: incrementNum, isActive: active);
  }

  @override
  Widget getItemPage(AssignEntryRow item) {
    final AssignEntryRow? curItem = presentationRows.bridgeAll.firstWhereOrNull((i) => i.id == item.id);
    final source = context.read<CollectionSource>();
    final curEntry = source.allEntries.firstWhereOrNull((e) => e.id == curItem?.entryId);
    if (curEntry != null) {
      return EntryViewerPage(
        collection: null,
        initialEntry: curEntry,
        //t4y: for the all items in Config page will not be the latest data.
      );
    } else {
      return const Text('null');
    }
  }

  @override
  Future<AssignEntryRow> makeNewRow() {
    // TODO: implement makeNewRow
    throw UnimplementedError();
  }
}

class SingleAssignEntriesActions extends BridgeConfigActions<AssignEntryRow> {
  final AssignRecordRow item;

  SingleAssignEntriesActions({
    required this.item,
    required super.context,
    required super.setState,
  }) : super(
          presentationRows: assignEntries,
        );

  @override
  AssignEntryRow incrementRowWithActive(int incrementNum, AssignEntryRow srcItem, bool active) {
    return srcItem.copyWith(orderNum: incrementNum, isActive: active);
  }

  @override
  void applyChanges(BuildContext context, List<AssignEntryRow?> allItems, Set<AssignEntryRow?> activeItems) {
    setState(() {
      // First, remove items not existing.
      final currentItems = presentationRows.bridgeAll.where((e) => e.assignId == item.id);
      final itemsToRemove = currentItems.where((e) => !allItems.contains(e)).toSet();
      presentationRows.removeRows(itemsToRemove, type: PresentationRowType.bridgeAll);

      // Process reordered active items
      int incrementNum = 1;
      allItems.where((e) => activeItems.contains(e)).forEach((e) {
        final newRow = incrementRowWithActive(incrementNum++, e!, true);
        presentationRows.set(newRow, type: PresentationRowType.bridgeAll);
      });

      // Process reordered inactive items
      allItems.where((e) => !activeItems.contains(e)).forEach((e) {
        final newRow = incrementRowWithActive(incrementNum++, e!, false);
        presentationRows.set(newRow, type: PresentationRowType.bridgeAll);
      });
      // in parent to sync.
      // presentationRows.syncBridgeToRows();
      allItems.sort();
      showFeedback(context, FeedbackType.info, context.l10n.applyCompletedFeedback);
    });
  }

  @override
  Widget getItemPage(AssignEntryRow item) {
    final AssignEntryRow? curItem = presentationRows.bridgeAll.firstWhereOrNull((i) => i.id == item.id);
    final source = context.read<CollectionSource>();
    final curEntry = source.allEntries.firstWhereOrNull((e) => e.id == curItem?.entryId);
    if (curEntry != null) {
      return EntryViewerPage(
        collection: null,
        initialEntry: curEntry,
        //t4y: for the all items in Config page will not be the latest data.
      );
    } else {
      return const Text('null');
    }
  }

  @override
  Future<AssignEntryRow> makeNewRow() {
    // TODO: implement makeNewRow
    throw UnimplementedError();
  }
}
