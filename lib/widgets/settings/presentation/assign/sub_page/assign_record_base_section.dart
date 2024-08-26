import 'package:aves/model/assign/assign_entries.dart';
import 'package:aves/model/assign/assign_record.dart';
import 'package:aves/model/assign/enum/assign_item.dart';
import 'package:aves/model/source/collection_source.dart';
import 'package:aves/widgets/common/action_mixins/feedback.dart';
import 'package:aves/widgets/common/basic/list_tiles/color.dart';
import 'package:aves/widgets/common/extensions/build_context.dart';
import 'package:aves/widgets/settings/common/item_tiles.dart';
import 'package:aves/widgets/settings/settings_definition.dart';
import 'package:aves/widgets/viewer/entry_viewer_page.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AssignRecordPreInfoTitleTile extends SettingsTile {
  @override
  String title(BuildContext context) => '${context.l10n.settingsAssignNamePrefix}:${item.id}';

  final AssignRecordRow item;

  AssignRecordPreInfoTitleTile({
    required this.item,
  });

  @override
  Widget build(BuildContext context) => ItemInfoListTile<AssignRecord>(
        tileTitle: title(context),
        selector: (context, levels) {
          debugPrint('$runtimeType AssignRecordLabelNameModifiedTile\n'
              'item: $item \n'
              'rows ${levels.all} \n'
              'bridges ${levels.bridgeAll}\n');
          return ('id:${item.id} date:${DateTime.fromMillisecondsSinceEpoch(item.dateMillis)}');
        },
      );
}

class AssignRecordLabelNameModifiedTile extends SettingsTile {
  @override
  String title(BuildContext context) => context.l10n.renameLabelNameTileTitle;
  final AssignRecordRow item;

  AssignRecordLabelNameModifiedTile({
    required this.item,
  });

  @override
  Widget build(BuildContext context) => ItemSettingsLabelNameListTile<AssignRecord>(
        tileTitle: title(context),
        selector: (context, levels) {
          debugPrint('$runtimeType AssignRecordLabelNameModifiedTile\n'
              'item: $item \n'
              'rows ${levels.all} \n'
              'bridges ${levels.bridgeAll}\n');
          final row = assignRecords.bridgeAll.firstWhereOrNull((e) => e.id == item.id);
          if (row != null) {
            return row.labelName;
          } else {
            return 'Error';
          }
        },
        onChanged: (value) {
          debugPrint('$runtimeType AssignRecordSectionBaseSection\n'
              'row.labelName ${item.labelName} \n'
              'to value $value\n');
          if (assignRecords.bridgeAll.map((e) => e.id).contains(item.id)) {
            assignRecords.setExistRows(
                rows: {item}, newValues: {AssignRecordRow.propLabelName: value}, type: AssignRecordRowsType.bridgeAll);
          }
          ;
        },
      );
}

class AssignRecordColorPickerTile extends SettingsTile {
  @override
  String title(BuildContext context) => context.l10n.settingsItemTileColor;
  final AssignRecordRow item;

  AssignRecordColorPickerTile({
    required this.item,
  });

  @override
  Widget build(BuildContext context) => Selector<AssignRecord, Color>(
        selector: (context, s) => s.bridgeAll.firstWhereOrNull((e) => e.id == item.id)?.color ?? Colors.transparent,
        builder: (context, current, child) => ListTile(
          title: Text(title(context)),
          trailing: GestureDetector(
            onTap: () {
              _pickColor(context);
            },
            child: Container(
              width: 24,
              height: 24,
              color: current,
            ),
          ),
        ),
      );

  Future<void> _pickColor(BuildContext context) async {
    final color = await showDialog<Color>(
      context: context,
      builder: (context) => ColorPickerDialog(
        initialValue: item.color ?? assignRecords.getRandomColor(),
      ),
      routeSettings: const RouteSettings(name: ColorPickerDialog.routeName),
    );
    if (color != null) {
      if (assignRecords.bridgeAll.map((e) => e.id).contains(item.id)) {
        await assignRecords.setExistRows(
            rows: {item}, newValues: {AssignRecordRow.propColor: color}, type: AssignRecordRowsType.bridgeAll);
      }
      ;
    }
  }
}

class AssignRecordTypeSwitchTile extends SettingsTile with FeedbackMixin {
  @override
  String title(BuildContext context) => context.l10n.settingsTileAssignType;
  final AssignRecordRow item;

  AssignRecordTypeSwitchTile({
    required this.item,
  });

  @override
  Widget build(BuildContext context) => ItemSettingsSelectionListTile<AssignRecord, AssignRecordType>(
        values: AssignRecordType.values,
        getName: (context, v) => v.getName(context),
        selector: (context, s) => s.bridgeAll.firstWhereOrNull((e) => e.id == item.id)?.assignType ?? item.assignType,
        onSelection: (v) async {
          debugPrint('$runtimeType AssignRecordTypeSwitchTile\n'
              'AssignRecordTypeSwitchTile onSelection v :$item \n');
          final curItems = assignRecords.bridgeAll.firstWhereOrNull((e) => e.id == item.id) ?? item;
          await assignRecords.setExistRows(
              rows: {curItems}, newValues: {AssignRecordRow.propAssignType: v}, type: AssignRecordRowsType.bridgeAll);
          // t4y:TODO：　after copy, reset all related items.
        },
        tileTitle: title(context),
        dialogTitle: context.l10n.settingsTileAssignType,
      );
}

class AssignRecordActiveListTile extends SettingsTile {
  @override
  String title(BuildContext context) => context.l10n.settingsActiveTitle;

  final AssignRecordRow item;

  AssignRecordActiveListTile({
    required this.item,
  });

  @override
  Widget build(BuildContext context) => ItemSettingsSwitchListTile<AssignRecord>(
        selector: (context, s) => s.bridgeAll.firstWhereOrNull((e) => e.id == item.id)?.isActive ?? item.isActive,
        onChanged: (v) async {
          final curItem = assignRecords.bridgeAll.firstWhereOrNull((e) => e.id == item.id) ?? item;
          await assignRecords.setExistRows(
            rows: {curItem},
            newValues: {
              AssignRecordRow.propIsActive: v,
            },
            type: AssignRecordRowsType.bridgeAll,
          );
        },
        title: title(context),
      );
}

class AssignEntrySubPageTile extends SettingsTile {
  @override
  String title(BuildContext context) {
    return '${context.l10n.settingsAssignEntrySubPagePrefix} ${subItem.entryId}: ';
  }

  final AssignRecordRow item;
  final AssignEntryRow subItem;

  AssignEntrySubPageTile({
    required this.item,
    required this.subItem,
  });

  @override
  Widget build(BuildContext context) {
    final AssignEntryRow? curItem = assignEntries.bridgeAll.firstWhereOrNull((i) => i.id == subItem.id);
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
