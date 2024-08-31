import 'package:aves/model/fgw/filters_set.dart';
import 'package:aves/model/presentation/base_bridge_row.dart';
import 'package:aves/widgets/common/extensions/build_context.dart';
import 'package:aves/widgets/settings/common/collection_tile.dart';
import 'package:aves/widgets/settings/common/item_tiles.dart';
import 'package:aves/widgets/settings/settings_definition.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';

class FiltersSetTitleTile extends SettingsTile {
  @override
  String title(BuildContext context) => '${context.l10n.filterSetNamePrefix}:${item.orderNum}';

  final FiltersSetRow item;

  FiltersSetTitleTile({
    required this.item,
  });

  @override
  Widget build(BuildContext context) => ItemInfoListTile<FiltersSet>(
        tileTitle: title(context),
        selector: (context, levels) {
          debugPrint('$runtimeType FiltersSetLabelNameModifiedTile\n'
              'item: $item \n'
              'rows ${levels.all} \n'
              'bridges ${levels.bridgeAll}\n');
          return ('id:${item.id}');
        },
      );
}

class FiltersCollectionTile extends SettingsTile {
  @override
  String title(BuildContext context) => '${context.l10n.filterSetNamePrefix}:';

  final FiltersSetRow item;

  FiltersCollectionTile({
    required this.item,
  });

  @override
  Widget build(BuildContext context) => SettingsCollectionTile(
        filters: item.filters!,
        onSelection: (v) {
          final newRow = item.copyWith(filters: v);
          filtersSets.setRows({newRow}, type: PresentationRowType.bridgeAll);
        },
      );
}

class FiltersSetLabelNameModifiedTile extends SettingsTile {
  @override
  String title(BuildContext context) => context.l10n.renameLabelNameTileTitle;
  final FiltersSetRow item;

  FiltersSetLabelNameModifiedTile({
    required this.item,
  });

  @override
  Widget build(BuildContext context) => ItemSettingsLabelNameListTile<FiltersSet>(
        tileTitle: title(context),
        selector: (context, levels) {
          debugPrint('$runtimeType FiltersSetLabelNameModifiedTile\n'
              'item: $item \n'
              'rows ${levels.all} \n'
              'bridges ${levels.bridgeAll}\n');
          final row = levels.bridgeAll.firstWhereOrNull((e) => e.id == item.id);
          if (row != null) {
            return row.labelName;
          } else {
            return 'Error';
          }
        },
        onChanged: (value) {
          debugPrint('$runtimeType FiltersSetSectionBaseSection\n'
              'row.labelName ${item.labelName} \n'
              'to value $value\n');

          if (filtersSets.bridgeAll.map((e) => e.id).contains(item.id)) {
            final newRow = item.copyWith(labelName: value);
            filtersSets.setRows({newRow}, type: PresentationRowType.bridgeAll);
          }
          ;
        },
      );
}

class FiltersSetActiveListTile extends SettingsTile {
  @override
  String title(BuildContext context) => context.l10n.settingsActiveTitle;

  final FiltersSetRow item;

  FiltersSetActiveListTile({
    required this.item,
  });

  @override
  Widget build(BuildContext context) => ItemSettingsSwitchListTile<FiltersSet>(
        selector: (context, s) => s.bridgeAll.firstWhereOrNull((e) => e.id == item.id)?.isActive ?? item.isActive,
        onChanged: (v) async {
          final newRow = item.copyWith(isActive: v);
          await filtersSets.setRows({newRow}, type: PresentationRowType.bridgeAll);
        },
        title: title(context),
      );
}
