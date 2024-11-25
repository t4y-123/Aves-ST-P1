import 'package:aves/model/fgw/filters_set.dart';
import 'package:aves/model/presentation/base_bridge_row.dart';
import 'package:aves/widgets/settings/presentation/common/config_actions.dart';
import 'package:aves/widgets/settings/presentation/foreground_wallpaper/sub_page/filter_set_item_page.dart';
import 'package:flutter/material.dart';

class FiltersSetConfigActions extends BridgeConfigActions<FiltersSetRow> {
  FiltersSetConfigActions({
    required super.context,
    required super.setState,
  }) : super(
          presentationRows: filtersSets,
        );

  @override
  FiltersSetRow incrementRowWithActive(int incrementNum, FiltersSetRow srcItem, bool active) {
    return srcItem.copyWith(orderNum: incrementNum, isActive: active);
  }

  @override
  Widget getItemPage(FiltersSetRow item) {
    return FiltersSetItemPage(item: item);
  }

  @override
  Future<FiltersSetRow> makeNewRow() async {
    return filtersSets.newRow(1, type: PresentationRowType.bridgeAll);
  }
}
