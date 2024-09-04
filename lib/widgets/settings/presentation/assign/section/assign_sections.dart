import 'package:aves/model/assign/assign_entries.dart';
import 'package:aves/model/assign/assign_record.dart';
import 'package:aves/model/presentation/base_bridge_row.dart';
import 'package:aves/model/source/collection_source.dart';
import 'package:aves/widgets/common/extensions/build_context.dart';
import 'package:aves/widgets/settings/common/item_tiles.dart';
import 'package:aves/widgets/settings/presentation/assign/sub_page/single_record_assign_entry_edit_page.dart';
import 'package:aves/widgets/settings/presentation/common/section.dart';
import 'package:aves/widgets/viewer/entry_viewer_page.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AssignEntrySubPageTile extends ItemSettingsTile<AssignEntryRow> {
  @override
  String title(BuildContext context) {
    return '${context.l10n.settingsAssignEntrySubPagePrefix} ${item.entryId}: ';
  }

  AssignEntrySubPageTile({
    required super.item,
  });

  @override
  Widget build(BuildContext context) {
    final AssignEntryRow? curItem = assignEntries.bridgeAll.firstWhereOrNull((i) => i.id == item.id);
    final source = context.read<CollectionSource>();
    final curEntry = source.allEntries.firstWhereOrNull((e) => e.id == curItem?.entryId);
    if (curEntry != null) {
      return ItemSettingsSubPageTile<AssignEntries>(
        title: title(context),
        subtitleSelector: (context, s) {
          final titlePost = curEntry.bestTitle;
          return titlePost ?? 'null';
        },
        routeName: EntryViewerPage.routeName,
        builder: (context) => EntryViewerPage(
          collection: null,
          initialEntry: curEntry,
          //t4y: for the all items in Config page will not be the latest data.
        ),
      );
    } else {
      return const Text('null');
    }
  }
}

class AssignRecordEditTile<AssignRecordRow> extends ItemSettingsTile {
  @override
  String title(BuildContext context) => context.l10n.applyTooltip;

  AssignRecordEditTile({
    required super.item,
  });

  @override
  Widget build(BuildContext context) => ListTile(
        title: null,
        trailing: ElevatedButton(
          onPressed: () async {
            final tileItem = assignRecords.bridgeAll.firstWhereOrNull((e) => e.id == item.id);
            if (tileItem != null) {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SingleAssignRecordEditEntriesPage(
                    item: tileItem,
                  ),
                ),
              );
            }
          },
          child: Text(context.l10n.settingsAssignEditEntries),
        ),
      );
}

class AssignEntryItemPageTile extends ItemSettingsTile<AssignEntryRow> {
  AssignEntryItemPageTile({required super.item});

  @override
  String title(BuildContext context) {
    final curRow = assignEntries.bridgeAll.firstWhereOrNull((e) => e.id == item.id);
    return curRow != null ? '${context.l10n.settingsAssignEntrySubPagePrefix}: ${curRow.id}' : 'null';
  }

  @override
  Widget build(BuildContext context) => ItemSettingsSubPageTile<AssignEntryRow>(
      title: title(context),
      subtitleSelector: (context, s) {
        final subItem = assignEntries.bridgeAll.firstWhereOrNull((e) => e.id == item.id);
        final titlePost = subItem != null ? PresentRow.formatItemMap(subItem.toMap()) : 'null';
        return titlePost.toString();
      },
      routeName: EntryViewerPage.routeName,
      builder: (context) {
        final AssignEntryRow? curItem = assignEntries.bridgeAll.firstWhereOrNull((i) => i.id == item.id);
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
      });
}
