import 'package:aves/app_mode.dart';
import 'package:aves/model/filters/album.dart';
import 'package:aves/model/filters/filters.dart';
import 'package:aves/model/filters/scenario.dart';
import 'package:aves/model/presentation/base_bridge_row.dart';
import 'package:aves/model/scenario/enum/scenario_item.dart';
import 'package:aves/model/scenario/scenario.dart';
import 'package:aves/model/scenario/scenario_step.dart';
import 'package:aves/model/scenario/scenarios_helper.dart';
import 'package:aves/model/selection.dart';
import 'package:aves/model/settings/settings.dart';
import 'package:aves/model/vaults/vaults.dart';
import 'package:aves/widgets/common/action_mixins/feedback.dart';
import 'package:aves/widgets/common/action_mixins/scenario_aware.dart';
import 'package:aves/widgets/common/action_mixins/vault_aware.dart';
import 'package:aves/widgets/common/extensions/build_context.dart';
import 'package:aves/widgets/common/grid/scaling.dart';
import 'package:aves/widgets/common/identity/aves_filter_chip.dart';
import 'package:aves/widgets/filter_grids/common/covered_filter_chip.dart';
import 'package:aves/widgets/filter_grids/common/filter_chip_grid_decorator.dart';
import 'package:aves/widgets/filter_grids/common/list_details.dart';
import 'package:aves/widgets/settings/presentation/scenario/scenario_edit_page.dart';
import 'package:aves/widgets/settings/presentation/scenario/scenario_operation_page.dart';
import 'package:aves/widgets/settings/presentation/scenario/sub_page/scenario_item_page.dart';
import 'package:aves_model/aves_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class StatusInteractiveStatusFilterTile<T extends CollectionFilter> extends StatefulWidget {
  final FilterGridItem<T> gridItem;
  final double chipExtent, thumbnailExtent;
  final TileLayout tileLayout;
  final String? banner;
  final HeroType heroType;

  const StatusInteractiveStatusFilterTile({
    super.key,
    required this.gridItem,
    required this.chipExtent,
    required this.thumbnailExtent,
    required this.tileLayout,
    this.banner,
    required this.heroType,
  });

  @override
  State<StatusInteractiveStatusFilterTile<T>> createState() => _StatusInteractiveStatusFilterTileState<T>();
}

class _StatusInteractiveStatusFilterTileState<T extends CollectionFilter>
    extends State<StatusInteractiveStatusFilterTile<T>> with FeedbackMixin, VaultAwareMixin, ScenarioAwareMixin {
  HeroType? _heroTypeOverride;

  FilterGridItem<T> get gridItem => widget.gridItem;

  HeroType get effectiveHeroType => _heroTypeOverride ?? widget.heroType;

  @override
  Widget build(BuildContext context) {
    final filter = gridItem.filter;

    Future<void> onTap() async {
      if (!await unlockFilter(context, filter)) return;

      final appMode = context.read<ValueNotifier<AppMode>?>()?.value;
      switch (appMode) {
        case AppMode.main:
        case AppMode.pickCollectionFiltersExternal:
        case AppMode.pickSingleMediaExternal:
        case AppMode.pickMultipleMediaExternal:
          final selection = context.read<Selection<FilterGridItem<T>>?>();
          if (selection != null && selection.isSelecting) {
            selection.toggleSelection(gridItem);
          } else {
            switch (filter) {
              case ScenarioFilter filter:
                {
                  bool tapUnlock = false;
                  if (settings.scenarioLock) {
                    if (!await unlockScenarios(context)) return;
                    tapUnlock = true;
                  }
                  if (filter.scenarioId >= 0) {
                    switch (filter.scenario!.loadType) {
                      case ScenarioLoadType.excludeUnique:
                        // final removeFilters = settings.scenarioPinnedExcludeFilters
                        //     .where((e) => e is ScenarioFilter && e.scenario?.loadType == ScenarioLoadType.excludeUnique)
                        //     .toSet();
                        // settings.scenarioPinnedExcludeFilters = settings.scenarioPinnedExcludeFilters
                        //   ..removeAll(removeFilters)
                        //   ..add(filter);
                        scenariosHelper.setExcludeScenarioFilterSetting(filter);
                        break;
                      case ScenarioLoadType.unionOr:
                        if (settings.scenarioPinnedUnionFilters.contains(filter)) {
                          settings.scenarioPinnedUnionFilters = settings.scenarioPinnedUnionFilters..remove(filter);
                        } else {
                          settings.scenarioPinnedUnionFilters = settings.scenarioPinnedUnionFilters..add(filter);
                        }
                        break;
                      case ScenarioLoadType.intersectAnd:
                        if (settings.scenarioPinnedIntersectFilters.contains(filter)) {
                          settings.scenarioPinnedIntersectFilters = settings.scenarioPinnedIntersectFilters
                            ..remove(filter);
                        } else {
                          settings.scenarioPinnedIntersectFilters = settings.scenarioPinnedIntersectFilters
                            ..add(filter);
                        }
                        break;
                    }
                  } else if (filter.scenarioId == ScenarioFilter.scenarioSettingId) {
                    await Navigator.maybeOf(context)?.push(
                      MaterialPageRoute(
                        settings: const RouteSettings(name: ScenarioEditSettingPage.routeName),
                        builder: (context) => const ScenarioEditSettingPage(),
                      ),
                    );
                  } else if (filter.scenarioId == ScenarioFilter.scenarioOpId) {
                    await Navigator.maybeOf(context)?.push(
                      MaterialPageRoute(
                        settings: const RouteSettings(name: ScenariosOperationPage.routeName),
                        builder: (context) => const ScenariosOperationPage(),
                      ),
                    );
                  } else if (filter.scenarioId == ScenarioFilter.scenarioLockUnlockId) {
                    if (!tapUnlock) {
                      // only when the unlock mode is not unlock by now need to lock scenario.
                      settings.scenarioLock = true;
                    }
                  } else if (filter.scenarioId == ScenarioFilter.scenarioAddNewItemId) {
                    await scenarios.syncRowsToBridge();
                    await scenarioSteps.syncRowsToBridge();

                    final newItem = await scenarios.newRow(1, type: PresentationRowType.bridgeAll);
                    debugPrint('addScenarioBase newItem $newItem\n');
                    await scenarios.add({newItem}, type: PresentationRowType.bridgeAll);

                    // add a new group of schedule to schedules bridge.
                    final bridgeSubItems =
                        await scenariosHelper.newScenarioStepsGroup(newItem, rowsType: PresentationRowType.bridgeAll);
                    await scenarioSteps.add(bridgeSubItems.toSet(), type: PresentationRowType.bridgeAll);

                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ScenarioItemPage(
                          item: newItem,
                        ),
                      ),
                    ).then((newItem) {
                      if (newItem != null) {
                        //final newRow = newItem as ScenarioBaseRow;
                        setState(() {
                          // not sync until tap apply button.
                          // scenarios.syncBridgeToRows();
                          //sync bridgeRows to privacy
                          scenarios.syncBridgeToRows();
                          scenarioSteps.syncBridgeToRows();
                        });
                      } else {
                        scenarios.removeRows({newItem}, type: PresentationRowType.bridgeAll);
                        scenarioSteps.removeRows(bridgeSubItems.toSet(), type: PresentationRowType.bridgeAll);
                      }
                    });
                  }
                }
              default:
              //do nothing.
            }
            // _goToCollection(context, filter);
          }
        case AppMode.pickFilterInternal:
          Navigator.maybeOf(context)?.pop<T>(filter);
        default:
          break;
      }
    }

    return MetaData(
      metaData: ScalerMetadata(gridItem),
      child: StatusFilterTile(
        gridItem: gridItem,
        chipExtent: widget.chipExtent,
        thumbnailExtent: widget.thumbnailExtent,
        tileLayout: widget.tileLayout,
        banner: widget.banner,
        selectable: true,
        highlightable: true,
        onTap: onTap,
        heroType: effectiveHeroType,
      ),
    );
  }
}

class StatusFilterTile<T extends CollectionFilter> extends StatelessWidget {
  final FilterGridItem<T> gridItem;
  final double chipExtent, thumbnailExtent;
  final TileLayout tileLayout;
  final String? banner;
  final bool selectable, highlightable;
  final VoidCallback? onTap;
  final HeroType heroType;

  const StatusFilterTile({
    super.key,
    required this.gridItem,
    required this.chipExtent,
    required this.thumbnailExtent,
    required this.tileLayout,
    this.banner,
    this.selectable = false,
    this.highlightable = false,
    this.onTap,
    this.heroType = HeroType.never,
  });

  @override
  Widget build(BuildContext context) {
    final filter = gridItem.filter;
    final pinned = settings.pinnedFilters.contains(filter);
    final locked = filter is AlbumFilter && vaults.isLocked(filter.album);
    final onChipTap = onTap != null ? (filter) => onTap?.call() : null;

    switch (tileLayout) {
      case TileLayout.mosaic:
      case TileLayout.grid:
        return FilterChipGridDecorator<T, FilterGridItem<T>>(
          gridItem: gridItem,
          extent: chipExtent,
          selectable: selectable,
          highlightable: highlightable,
          child: CoveredFilterChip(
            filter: filter,
            extent: chipExtent,
            thumbnailExtent: thumbnailExtent,
            showText: true,
            pinned: pinned,
            locked: locked,
            banner: banner,
            onTap: onChipTap,
            heroType: heroType,
          ),
        );
      case TileLayout.list:
        Widget child = Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FilterChipGridDecorator<T, FilterGridItem<T>>(
              gridItem: gridItem,
              extent: chipExtent,
              selectable: selectable,
              highlightable: highlightable,
              child: CoveredFilterChip(
                filter: filter,
                extent: chipExtent,
                thumbnailExtent: thumbnailExtent,
                showText: false,
                locked: locked,
                banner: banner,
                onTap: onChipTap,
                heroType: heroType,
              ),
            ),
            Expanded(
              child: FilterListDetails(
                gridItem: gridItem,
                pinned: pinned,
                locked: locked,
              ),
            ),
          ],
        );
        if (onTap != null) {
          // larger than the chip corner radius, so ink effects will be effectively clipped from the leading chip corners
          const radius = Radius.circular(123);
          child = InkWell(
            // as of Flutter v2.8.1, `InkWell` does not use `BorderRadiusGeometry`
            borderRadius: context.isRtl
                ? const BorderRadius.only(topRight: radius, bottomRight: radius)
                : const BorderRadius.only(topLeft: radius, bottomLeft: radius),
            onTap: onTap,
            child: child,
          );
        }
        return child;
    }
  }
}
