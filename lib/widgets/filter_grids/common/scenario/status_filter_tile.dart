import 'package:aves/app_mode.dart';
import 'package:aves/model/filters/album.dart';
import 'package:aves/model/filters/filters.dart';
import 'package:aves/model/filters/scenario.dart';
import 'package:aves/model/scenario/enum/scenario_item.dart';
import 'package:aves/model/selection.dart';
import 'package:aves/model/settings/settings.dart';
import 'package:aves/model/vaults/vaults.dart';
import 'package:aves/widgets/common/action_mixins/feedback.dart';
import 'package:aves/widgets/common/action_mixins/vault_aware.dart';
import 'package:aves/widgets/common/extensions/build_context.dart';
import 'package:aves/widgets/common/grid/scaling.dart';
import 'package:aves/widgets/common/identity/aves_filter_chip.dart';
import 'package:aves/widgets/filter_grids/common/covered_filter_chip.dart';
import 'package:aves/widgets/filter_grids/common/filter_chip_grid_decorator.dart';
import 'package:aves/widgets/filter_grids/common/list_details.dart';
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
    extends State<StatusInteractiveStatusFilterTile<T>> with FeedbackMixin, VaultAwareMixin {
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
                  // first remove pinned exclude type of scenario filter.
                  if (filter.scenario.loadType == ScenarioLoadType.excludeEach) {
                    final removeFilters = settings.scenarioPinnedFilters
                        .where((e) => e is ScenarioFilter && e.scenario.loadType == ScenarioLoadType.excludeEach)
                        .toSet();
                    settings.scenarioPinnedFilters = settings.scenarioPinnedFilters..removeAll(removeFilters);
                    settings.scenarioPinnedFilters = settings.scenarioPinnedFilters..add(filter);
                  } else if (settings.scenarioPinnedFilters.contains(filter)) {
                    settings.scenarioPinnedFilters = settings.scenarioPinnedFilters..remove(filter);
                    // debugPrint(
                    //     '$runtimeType _StatusInteractiveStatusFilterTileState  settings.scenarioPinnedFilters.remove(filter)'
                    //     '${settings.scenarioPinnedFilters} [$filter]');
                  } else {
                    settings.scenarioPinnedFilters = settings.scenarioPinnedFilters..add(filter);
                    // debugPrint(
                    //     '$runtimeType _StatusInteractiveStatusFilterTileState  settings.scenarioPinnedFilters.add(filter)'
                    //     '${settings.scenarioPinnedFilters} [$filter]');
                  }
                  // debugPrint(
                  //    '$runtimeType _StatusInteractiveStatusFilterTileState scenario change:${settings.scenarioPinnedFilters}');
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
