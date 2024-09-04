import 'package:aves/model/fgw/filters_set.dart';
import 'package:aves/model/presentation/base_bridge_row.dart';
import 'package:aves/widgets/common/extensions/build_context.dart';
import 'package:aves/widgets/settings/common/collection_tile.dart';
import 'package:aves/widgets/settings/settings_definition.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class FiltersCollectionTile extends SettingsTile {
  @override
  String title(BuildContext context) => '${context.l10n.filterSetNamePrefix}:';

  final FiltersSetRow item;

  FiltersCollectionTile({
    required this.item,
  });

  @override
  Widget build(BuildContext context) => Selector<FiltersSet, FiltersSetRow?>(
        selector: (context, s) => s.bridgeAll.firstWhereOrNull((e) => e.id == item.id),
        builder: (context, current, child) {
          return current != null
              ? SettingsCollectionTile(
                  filters: current.filters!,
                  onSelection: (v) {
                    final newRow = filtersSets.bridgeAll.firstWhere((e) => e.id == item.id).copyWith(filters: v);
                    filtersSets.setRows({newRow}, type: PresentationRowType.bridgeAll);
                  },
                )
              : Text(context.l10n.itemEmpty);
        },
      );
}
