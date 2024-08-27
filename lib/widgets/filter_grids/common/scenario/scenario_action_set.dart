import 'package:aves/app_mode.dart';
import 'package:aves/model/filters/filters.dart';
import 'package:aves/model/scenario/enum/scenario_item.dart';
import 'package:aves/model/scenario/scenario.dart';
import 'package:aves/model/settings/settings.dart';
import 'package:aves/services/common/services.dart';
import 'package:aves/theme/durations.dart';
import 'package:aves/view/view.dart';
import 'package:aves/widgets/common/action_mixins/entry_storage.dart';
import 'package:aves/widgets/common/action_mixins/feedback.dart';
import 'package:aves/widgets/common/action_mixins/scenario_aware.dart';
import 'package:aves/widgets/common/extensions/build_context.dart';
import 'package:aves/widgets/common/tile_extent_controller.dart';
import 'package:aves/widgets/dialogs/aves_confirmation_dialog.dart';
import 'package:aves/widgets/dialogs/aves_dialog.dart';
import 'package:aves/widgets/dialogs/filter_editors/rename_album_dialog.dart';
import 'package:aves/widgets/dialogs/tile_view_dialog.dart';
import 'package:aves/widgets/filter_grids/common/action_delegates/chip_set.dart';
import 'package:aves/widgets/filter_grids/scenario_page.dart';
import 'package:aves_model/aves_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';

import '../../../../model/filters/scenario.dart';

class ScenarioChipSetActionDelegate extends ChipSetActionDelegate<ScenarioFilter>
    with EntryStorageMixin, ScenarioAwareMixin {
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
      case ChipSetAction.hide:
        return false;
      case ChipSetAction.delete:
      case ChipSetAction.rename:
        return isMain && isSelecting && !settings.isReadOnly;
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
    final l10n = context.l10n;
    final filters = getSelectedFilters(context);
    // can not remove func scenario filter.
    if (filters is Set<ScenarioFilter> && filters.any((e) => e.scenarioId <= 0)) {
      await showDialog<void>(
        context: context,
        builder: (context) => AvesDialog(
          content: Text(l10n.canNotRemoveFuncScenarioFiltersMessage),
          actions: [
            TextButton(
              onPressed: () => Navigator.maybeOf(context)?.pop(),
              child: Text(context.l10n.continueButtonLabel),
            ),
          ],
        ),
        routeSettings: const RouteSettings(name: AvesDialog.warningRouteName),
      );
      return;
    }

    // can not remove func scenario filter.
    final todoExcludeFilterCount =
        filters.where((e) => e is ScenarioFilter && e.scenario?.loadType == ScenarioLoadType.excludeUnique).length;
    final allExcludeFilterCount =
        scenarios.all.where((e) => e.isActive && e.loadType == ScenarioLoadType.excludeUnique).length;

    if (todoExcludeFilterCount >= allExcludeFilterCount) {
      await showDialog<void>(
        context: context,
        builder: (context) => AvesDialog(
          content: Text(l10n.canNotRemoveAllExcludeScenarioFiltersMessage),
          actions: [
            TextButton(
              onPressed: () => Navigator.maybeOf(context)?.pop(),
              child: Text(context.l10n.continueButtonLabel),
            ),
          ],
        ),
        routeSettings: const RouteSettings(name: AvesDialog.warningRouteName),
      );
      return;
    }

    if (settings.scenarioLock && !await unlockScenarios(context)) return;
    if (!await showSkippableConfirmationDialog(
      context: context,
      type: ConfirmationDialog.chipRemoveScenario,
      message: l10n.chipRemoveScenarioFiltersMessage,
      confirmationButtonLabel: l10n.deleteButtonLabel,
    )) return;

    final scenarioIds = filters.map((e) => e.scenarioId).toSet();
    await scenarios.removeIds(scenarioIds);

    browse(context);
  }

  Future<void> _rename(BuildContext context) async {
    final l10n = context.l10n;
    final filters = getSelectedFilters(context);
    if (filters is Set<ScenarioFilter> && filters.any((e) => e.scenarioId <= 0)) {
      await showDialog<void>(
        context: context,
        builder: (context) => AvesDialog(
          content: Text(l10n.canNotRenameFuncScenarioFiltersMessage),
          actions: [
            TextButton(
              onPressed: () => Navigator.maybeOf(context)?.pop(),
              child: Text(context.l10n.continueButtonLabel),
            ),
          ],
        ),
        routeSettings: const RouteSettings(name: AvesDialog.warningRouteName),
      );
      return;
    }
    if (filters.isEmpty || filters.first.scenario == null) return;
    final filter = filters.first;
    if (settings.scenarioLock && !await unlockScenarios(context)) return;

    final newName = await showDialog<String>(
      context: context,
      builder: (context) => RenameAlbumDialog(album: filter.displayName),
      routeSettings: const RouteSettings(name: RenameAlbumDialog.routeName),
    );
    if (newName == null || newName.isEmpty) return;

    final newScenario = filter.scenario!.copyWith(labelName: newName);
    await scenarios.setRows({newScenario});
    showFeedback(context, FeedbackType.info, context.l10n.applyCompletedFeedback);
  }
}
