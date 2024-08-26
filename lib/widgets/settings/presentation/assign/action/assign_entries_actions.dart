import 'package:aves/model/assign/assign_entries.dart';
import 'package:aves/model/source/collection_source.dart';
import 'package:aves/widgets/common/action_mixins/feedback.dart';
import 'package:aves/widgets/common/extensions/build_context.dart';
import 'package:aves/widgets/viewer/entry_viewer_page.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AssignEntryActions with FeedbackMixin {
  final BuildContext context;
  final Function setState;

  AssignEntryActions({
    required this.context,
    required this.setState,
  });
  // AssignEntry
  void applyScenarioBaseReorder(
      BuildContext context, List<AssignEntryRow?> allItems, Set<AssignEntryRow?> activeItems) {
    setState(() {
      // First, remove items not exist.      // remove relate schedules too.
      final currentItems = assignEntries.bridgeAll;
      final itemsToRemove = currentItems.where((item) => !allItems.contains(item)).toSet();
      // remove assignEntries
      final removeItems = itemsToRemove.map((e) => e.id).toSet();
      assignEntries.removeEntries(itemsToRemove, type: AssignEntryRowsType.bridgeAll);

      // according to order in allItems, reorder the data .active items first.
      allItems.where((item) => activeItems.contains(item)).forEach((item) {
        assignEntries.set(
          id: item!.id,
          assignId: item.assignId,
          entryId: item.entryId,
          isActive: true,
          dateMillis: item.dateMillis,
          type: AssignEntryRowsType.bridgeAll,
        );
      });
      // Process reordered items that are not in active items
      allItems.where((item) => !activeItems.contains(item)).forEach((item) {
        assignEntries.set(
          id: item!.id,
          assignId: item.assignId,
          entryId: item.entryId,
          isActive: false,
          dateMillis: item.dateMillis,
          type: AssignEntryRowsType.bridgeAll,
        );
      });
      //sync bridgeRows to privacy
      assignEntries.syncBridgeToRows();
      assignEntries.syncBridgeToRows();
      allItems.sort();
      //
      showFeedback(context, FeedbackType.info, context.l10n.applyCompletedFeedback);
    });
  }

  Future<void> editSelectedItem(BuildContext context, AssignEntryRow? item, List<AssignEntryRow?> allItems,
      Set<AssignEntryRow?> activeItems) async {
    //t4y: for the all items in Config page will not be the latest data.
    final source = context.read<CollectionSource>();
    //t4y: for the all items in Config page will not be the latest data.
    final AssignEntryRow curItem = assignEntries.bridgeAll.firstWhere((i) => i.id == item!.id);
    final curEntry = source.allEntries.firstWhereOrNull((e) => e.id == item?.entryId);
    if (curEntry != null) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => EntryViewerPage(
            collection: null,
            initialEntry: curEntry,
          ),
        ),
      );
    } else {
      showFeedback(context, FeedbackType.info, context.l10n.settingsAssignEntryNotExistWarn);
    }
  }
}
