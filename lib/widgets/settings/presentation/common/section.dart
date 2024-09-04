import 'package:aves/model/filters/mime.dart';
import 'package:aves/model/presentation/base_bridge_row.dart';
import 'package:aves/theme/colors.dart';
import 'package:aves/widgets/common/basic/list_tiles/color.dart';
import 'package:aves/widgets/common/extensions/build_context.dart';
import 'package:aves/widgets/settings/common/collection_tile.dart';
import 'package:aves/widgets/settings/common/item_tiles.dart';
import 'package:aves/widgets/settings/settings_definition.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

abstract class ItemSettingsTile<T> extends SettingsTile {
  final T item;

  ItemSettingsTile({required this.item});
}

class PresentInfoTile<T extends PresentRow<T>, S extends PresentationRows<T>> extends ItemSettingsTile<T> {
  final S items;

  @override
  String title(BuildContext context) => context.l10n.presentInfoTileTitle;

  PresentInfoTile({required super.item, required this.items});

  @override
  Widget build(BuildContext context) => ItemInfoListTile<S>(
        tileTitle: title(context),
        selector: (context, items) {
          if (items is PresentationRows<T>) {
            // debugPrint('$runtimeType PresentSettingTile\n'
            //     'item: $item \n'
            //     'rows ${items.all} \n'
            //     'bridges ${items.bridgeAll}\n');
            final row = items.bridgeAll.firstWhereOrNull((e) => e.id == item.id);
            return row != null ? PresentRow.formatItemMap(row.toMap()) : 'null';
          } else {
            return 'Unknown item type';
          }
        },
      );
}

class PresentLabelNameTile<T extends PresentRow<T>, S extends PresentationRows<T>> extends ItemSettingsTile<T> {
  final S items;
  PresentLabelNameTile({required super.item, required this.items});

  @override
  Widget build(BuildContext context) => ItemSettingsLabelNameListTile<S>(
        tileTitle: title(context),
        selector: (context, S) {
          debugPrint('$items PresentLabelNameTile\n'
              'item: $items \n'
              'rows ${items.all} \n'
              'bridges ${items.bridgeAll}\n');
          final row = items.bridgeAll.firstWhereOrNull((e) => e.id == item.id);
          return row?.labelName ?? 'Error';
        },
        onChanged: (value) async {
          debugPrint('$runtimeType PresentLabelNameTile\n'
              'row.labelName ${item.labelName} \n'
              'to value $value\n');
          final T newRow = items.bridgeAll.firstWhere((e) => e.id == item.id).copyWith(labelName: value);
          await items.setRows({newRow}, type: PresentationRowType.bridgeAll);
        },
      );

  @override
  String title(BuildContext context) => context.l10n.renameLabelNameTileTitle;
}

//t4y: not all sub class of  PresentRow have the value color.
class PresentColorPickTile<T extends PresentRow<T>, S extends PresentationRows<T>> extends ItemSettingsTile<T> {
  final S items;
  PresentColorPickTile({required super.item, required this.items});

  @override
  Widget build(BuildContext context) {
    if (!_hasColorProperty(item)) {
      throw FlutterError(
        'PresentColorPickTile: The item of type ${item.runtimeType} does not have a color property.',
      );
    }

    return Selector<S, Color?>(
      selector: (context, s) {
        final row = s.bridgeAll.firstWhereOrNull((e) => e.id == item.id) as dynamic;
        return row?.color ?? Colors.transparent;
      },
      builder: (context, currentColor, child) => ListTile(
        title: Text(title(context)),
        trailing: GestureDetector(
          onTap: () => _pickColor(context),
          child: Container(
            width: 24,
            height: 24,
            color: currentColor,
          ),
        ),
      ),
    );
  }

  bool _hasColorProperty(T item) {
    try {
      final color = (item as dynamic).color;
      return color != null;
    } catch (e) {
      return false;
    }
  }

  Future<void> _pickColor(BuildContext context) async {
    final color = await showDialog<Color>(
      context: context,
      builder: (context) => ColorPickerDialog(
        initialValue: (item as dynamic).color ?? AColors.getRandomColor(),
      ),
    );

    if (color != null) {
      final newRow = (items.bridgeAll.firstWhere((e) => e.id == item.id) as dynamic).copyWith(color: color);
      await items.setRows({newRow}, type: PresentationRowType.bridgeAll);
    }
  }

  @override
  String title(BuildContext context) => context.l10n.settingsItemSelectColor;
}

class PresentActiveListTile<T extends PresentRow<T>, S extends PresentationRows<T>> extends ItemSettingsTile<T> {
  final S items;

  PresentActiveListTile({
    required super.item,
    required this.items,
  });

  @override
  Widget build(BuildContext context) => ItemSettingsSwitchListTile<S>(
        selector: (context, s) => s.bridgeAll.firstWhereOrNull((e) => e.id == item.id)?.isActive ?? item.isActive,
        onChanged: (value) async {
          final newRow = items.bridgeAll.firstWhere((e) => e.id == item.id).copyWith(isActive: value);
          await items.setRows({newRow}, type: PresentationRowType.bridgeAll);
        },
        title: title(context),
      );

  @override
  String title(BuildContext context) => context.l10n.settingsActiveTitle;
}

class PresentCollectionFiltersTile<T extends PresentRow<T>, S extends PresentationRows<T>> extends ItemSettingsTile<T> {
  final S items;
  PresentCollectionFiltersTile({
    required super.item,
    required this.items,
  });

  @override
  Widget build(BuildContext context) => Selector<S, T?>(
        selector: (context, s) {
          final curRow = s.bridgeAll.firstWhereOrNull((e) => e.id == item.id) as dynamic;
          return curRow;
        },
        builder: (context, current, child) {
          final curFilters = (current as dynamic).filters;
          return SettingsCollectionTile(
              filters: curFilters ?? {MimeFilter.image},
              onSelection: (v) async {
                final curRow = items.bridgeAll.firstWhere((e) => e.id == item.id) as dynamic;
                final newRow = curRow.copyWith(filters: v);
                await items.setRows({newRow}, type: PresentationRowType.bridgeAll);
              });
        },
      );

  @override
  String title(BuildContext context) => '';
}
