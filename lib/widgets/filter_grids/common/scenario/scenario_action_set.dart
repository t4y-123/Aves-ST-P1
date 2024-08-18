import 'package:aves/app_mode.dart';
import 'package:aves/model/filters/filters.dart';
import 'package:aves/model/scenario/enum/scenario_item.dart';
import 'package:aves/model/settings/settings.dart';
import 'package:aves/services/common/services.dart';
import 'package:aves/theme/durations.dart';
import 'package:aves/view/view.dart';
import 'package:aves/widgets/common/action_mixins/entry_storage.dart';
import 'package:aves/widgets/common/tile_extent_controller.dart';
import 'package:aves/widgets/dialogs/tile_view_dialog.dart';
import 'package:aves/widgets/filter_grids/common/action_delegates/chip_set.dart';
import 'package:aves/widgets/filter_grids/scenario_page.dart';
import 'package:aves_model/aves_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';

import '../../../../model/filters/scenario.dart';

class ScenarioChipSetActionDelegate extends ChipSetActionDelegate<ScenarioFilter> with EntryStorageMixin {
  final Iterable<FilterGridItem<ScenarioFilter>> _items;

  ScenarioChipSetActionDelegate(Iterable<FilterGridItem<ScenarioFilter>> items) : _items = items;

  @override
  Iterable<FilterGridItem<ScenarioFilter>> get allItems => _items;

  @override
  ChipSortFactor get sortFactor => settings.scenarioSortFactor;

  @override
  set sortFactor(ChipSortFactor factor) => settings.scenarioSortFactor = factor;

  @override
  bool get sortReverse => settings.scenarioSortReverse;

  @override
  set sortReverse(bool value) => settings.scenarioSortReverse = value;

  @override
  TileLayout get tileLayout => settings.getTileLayout(ScenarioListPage.routeName);

  @override
  set tileLayout(TileLayout tileLayout) => settings.setTileLayout(ScenarioListPage.routeName, tileLayout);

  static const _groupOptions = [
    // ScenarioChipGroupFactor.none,
    // ScenarioChipGroupFactor.importance,
    ScenarioChipGroupFactor.unionBeforeIntersect,
    ScenarioChipGroupFactor.intersectBeforeUnion,
  ];

  @override
  bool isVisible(
    ChipSetAction action, {
    required AppMode appMode,
    required bool isSelecting,
    required int itemCount,
    required Set<ScenarioFilter> selectedFilters,
  }) {
    final selectedSingleItem = selectedFilters.length == 1;
    final isMain = appMode == AppMode.main;

    final canCreate = !settings.isReadOnly && appMode.canCreateFilter && !isSelecting;
    switch (action) {
      case ChipSetAction.createAlbum:
      case ChipSetAction.createVault:
      case ChipSetAction.configureVault:
      case ChipSetAction.lockVault:
        return false;
      case ChipSetAction.delete:
      case ChipSetAction.rename:
        return isMain && isSelecting && !settings.isReadOnly;
      case ChipSetAction.hide:
        return isMain;
      default:
        return super.isVisible(
          action,
          appMode: appMode,
          isSelecting: isSelecting,
          itemCount: itemCount,
          selectedFilters: selectedFilters,
        );
    }
  }

  @override
  bool canApply(
    ChipSetAction action, {
    required bool isSelecting,
    required int itemCount,
    required Set<ScenarioFilter> selectedFilters,
  }) {
    switch (action) {
      case ChipSetAction.rename:
        if (selectedFilters.length != 1) return false;
        return true;
      case ChipSetAction.hide:
        return false;
      default:
        return super.canApply(
          action,
          isSelecting: isSelecting,
          itemCount: itemCount,
          selectedFilters: selectedFilters,
        );
    }
  }

  @override
  void onActionSelected(BuildContext context, ChipSetAction action) {
    reportService.log('$action');
    switch (action) {
      // general
      // single/multiple filters
      case ChipSetAction.delete:
        _delete(context);
      // single filter
      case ChipSetAction.rename:
        _rename(context);
      default:
        break;
    }
    super.onActionSelected(context, action);
  }

  @override
  Future<void> configureView(BuildContext context) async {
    final initialValue = (
      sortFactor,
      settings.scenarioGroupFactor,
      tileLayout,
      sortReverse,
    );
    final extentController = context.read<TileExtentController>();
    final value = await showDialog<(ChipSortFactor?, ScenarioChipGroupFactor?, TileLayout?, bool)>(
      context: context,
      builder: (context) {
        return TileViewDialog<ChipSortFactor, ScenarioChipGroupFactor, TileLayout>(
          initialValue: initialValue,
          sortOptions: ChipSetActionDelegate.sortOptions
              .map((v) => TileViewDialogOption(value: v, title: v.getName(context), icon: v.icon))
              .toList(),
          groupOptions: _groupOptions
              .map((v) => TileViewDialogOption(value: v, title: v.getName(context), icon: v.icon))
              .toList(),
          layoutOptions: ChipSetActionDelegate.layoutOptions
              .map((v) => TileViewDialogOption(value: v, title: v.getName(context), icon: v.icon))
              .toList(),
          sortOrder: (factor, reverse) => factor.getOrderName(context, reverse),
          tileExtentController: extentController,
        );
      },
      routeSettings: const RouteSettings(name: TileViewDialog.routeName),
    );
    // wait for the dialog to hide as applying the change may block the UI
    await Future.delayed(ADurations.dialogTransitionAnimation * timeDilation);
    if (value != null && initialValue != value) {
      sortFactor = value.$1!;
      settings.scenarioGroupFactor = value.$2!;
      tileLayout = value.$3!;
      sortReverse = value.$4;
    }
  }

  Future<void> _delete(BuildContext context) async {
    // t4y: todo:
    browse(context);
  }

  Future<void> _doDelete({
    required BuildContext context,
    required Set<ScenarioFilter> filters,
    required bool enableBin,
  }) async {
    // t4y: todo:
  }

  Future<void> _rename(BuildContext context) async {
    // t4y: todo:
  }

  Future<void> _doRename(BuildContext context, ScenarioFilter filter, String newName) async {
    // t4y: todo:
  }
}
