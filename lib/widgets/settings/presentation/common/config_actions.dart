import 'package:aves/model/presentation/base_bridge_row.dart';
import 'package:aves/widgets/common/action_mixins/feedback.dart';
import 'package:aves/widgets/common/extensions/build_context.dart';
import 'package:flutter/material.dart';

abstract class BridgeConfigActions<T extends PresentRow> with FeedbackMixin {
  final BuildContext context;
  final Function setState;
  final PresentationRows<T> presentationRows;

  BridgeConfigActions({
    required this.context,
    required this.setState,
    required this.presentationRows,
  });

  T incrementRowWithActive(int incrementNum, T srcItem, bool active);

  void applyChanges(BuildContext context, List<T?> allItems, Set<T?> activeItems) {
    setState(() {
      // First, remove items not existing.
      final currentItems = presentationRows.bridgeAll;
      final itemsToRemove = currentItems.where((item) => !allItems.contains(item)).toSet();
      presentationRows.removeRows(itemsToRemove, type: PresentationRowType.bridgeAll);

      // Process reordered active items
      int incrementNum = 1;
      allItems.where((item) => activeItems.contains(item)).forEach((item) {
        final newRow = incrementRowWithActive(incrementNum++, item!, true);
        presentationRows.set(newRow, type: PresentationRowType.bridgeAll);
      });

      // Process reordered inactive items
      allItems.where((item) => !activeItems.contains(item)).forEach((item) {
        final newRow = incrementRowWithActive(incrementNum++, item!, false);
        presentationRows.set(newRow, type: PresentationRowType.bridgeAll);
      });

      presentationRows.syncBridgeToRows();
      allItems.sort();
      showFeedback(context, FeedbackType.info, context.l10n.applyCompletedFeedback);
    });
  }

  void resetChanges(BuildContext context, List<T?> allItems, Set<T?> activeItems) {
    setState(() {
      // First, reset Rows
      presentationRows.syncRowsToBridge();
      allItems.sort();
      showFeedback(context, FeedbackType.info, context.l10n.applyCompletedFeedback);
    });
  }

  Future<T> makeNewRow();

  Future<void> removeRelateRow(T item) async {}
  Future<void> resetRelateRow(T item) async {}

  Future<void> opItem(BuildContext context, [T? item]) async {
    // add a new item to bridge.
    bool isAdded = false;

    if (item == null) {
      item = await makeNewRow();
      isAdded = true;
      //await presentationRows.newRow(1, type: PresentationRowType.bridgeAll);
      debugPrint('add new item $item\n');
      await presentationRows.add({item}, type: PresentationRowType.bridgeAll);
    }
    final originRow = item;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => getItemPage(item!),
      ),
    ).then((result) {
      if (result != true) {
        if (isAdded) {
          presentationRows.removeRows({item!}, type: PresentationRowType.bridgeAll);
          removeRelateRow(item);
        } else {
          presentationRows.setRows({originRow}, type: PresentationRowType.bridgeAll);
          resetRelateRow(item!);
        }
      }
      setState(() {});
    });
  }

  Future<void> activeItem(BuildContext context, [T? item]) async {
    if (item != null) {
      final newRow = item.copyWith(isActive: !item.isActive);
      await presentationRows.set(newRow, type: PresentationRowType.bridgeAll);
    }
  }

  Future<void> removeItem(BuildContext context, [T? item]) async {
    if (item != null) {
      await presentationRows.removeRows({item}, type: PresentationRowType.bridgeAll);
    }
  }

  Widget getItemPage(T item);
}
