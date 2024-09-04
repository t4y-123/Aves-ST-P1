import 'package:aves/model/assign/assign_entries.dart';
import 'package:aves/model/source/collection_source.dart';
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
