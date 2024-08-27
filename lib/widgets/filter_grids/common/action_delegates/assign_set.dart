import 'package:aves/app_mode.dart';
import 'package:aves/model/assign/assign_record.dart';
import 'package:aves/model/filters/assign.dart';
import 'package:aves/model/filters/filters.dart';
import 'package:aves/model/settings/settings.dart';
import 'package:aves/services/common/services.dart';
import 'package:aves/widgets/common/action_mixins/feedback.dart';
import 'package:aves/widgets/common/extensions/build_context.dart';
import 'package:aves/widgets/dialogs/aves_dialog.dart';
import 'package:aves/widgets/dialogs/filter_editors/rename_album_dialog.dart';
import 'package:aves/widgets/filter_grids/assign_page.dart';
import 'package:aves/widgets/filter_grids/common/action_delegates/chip_set.dart';
import 'package:aves_model/aves_model.dart';
import 'package:flutter/material.dart';

class AssignChipSetActionDelegate extends ChipSetActionDelegate<AssignFilter> {
  final Iterable<FilterGridItem<AssignFilter>> _items;

  AssignChipSetActionDelegate(Iterable<FilterGridItem<AssignFilter>> items) : _items = items;

  @override
  Iterable<FilterGridItem<AssignFilter>> get allItems => _items;

  @override
  ChipSortFactor get sortFactor => settings.tagSortFactor;

  @override
  set sortFactor(ChipSortFactor factor) => settings.tagSortFactor = factor;

  @override
  bool get sortReverse => settings.tagSortReverse;

  @override
  set sortReverse(bool value) => settings.tagSortReverse = value;

  @override
  TileLayout get tileLayout => settings.getTileLayout(AssignListPage.routeName);

  @override
  set tileLayout(TileLayout tileLayout) => settings.setTileLayout(AssignListPage.routeName, tileLayout);

  @override
  bool isVisible(
    ChipSetAction action, {
    required AppMode appMode,
    required bool isSelecting,
    required int itemCount,
    required Set<AssignFilter> selectedFilters,
  }) {
    final isMain = appMode == AppMode.main;

    switch (action) {
      case ChipSetAction.rename:
        if (selectedFilters.length != 1) return false;
        return true;
      case ChipSetAction.delete:
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
  void onActionSelected(BuildContext context, ChipSetAction action) {
    reportService.log('$action');
    switch (action) {
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

  Future<void> _delete(BuildContext context) async {
    final filters = getSelectedFilters(context);
    final todoAssignIds = filters.map((v) => v.assignId).toSet();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AvesDialog(
        content: Text(context.l10n.chipRemoveAssignFiltersMessage),
        actions: [
          const CancelButton(),
          TextButton(
            onPressed: () => Navigator.maybeOf(context)?.pop(true),
            child: Text(context.l10n.applyButtonLabel),
          ),
        ],
      ),
      routeSettings: const RouteSettings(name: AvesDialog.warningRouteName),
    );
    if (confirmed == null || !confirmed) return;

    await assignRecords.removeIds(todoAssignIds);

    browse(context);
  }

  Future<void> _rename(BuildContext context) async {
    final l10n = context.l10n;
    final filters = getSelectedFilters(context);
    final filter = filters.first;
    final newName = await showDialog<String>(
      context: context,
      builder: (context) => RenameAlbumDialog(album: filter.displayName),
      routeSettings: const RouteSettings(name: RenameAlbumDialog.routeName),
    );
    if (newName == null || newName.isEmpty) return;

    final newItem = filter.assignRecord!.copyWith(labelName: newName);
    await assignRecords.setRows({newItem});
    showFeedback(context, FeedbackType.info, l10n.applyCompletedFeedback);
  }
}
