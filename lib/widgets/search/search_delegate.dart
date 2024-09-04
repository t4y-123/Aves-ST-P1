import 'package:aves/model/assign/assign_record.dart';
import 'package:aves/model/filters/album.dart';
import 'package:aves/model/filters/aspect_ratio.dart';
import 'package:aves/model/filters/assign.dart';
import 'package:aves/model/filters/date.dart';
import 'package:aves/model/filters/favourite.dart';
import 'package:aves/model/filters/fgw_used.dart';
import 'package:aves/model/filters/filters.dart';
import 'package:aves/model/filters/location.dart';
import 'package:aves/model/filters/mime.dart';
import 'package:aves/model/filters/missing.dart';
import 'package:aves/model/filters/path.dart';
import 'package:aves/model/filters/query.dart';
import 'package:aves/model/filters/rating.dart';
import 'package:aves/model/filters/recent.dart';
import 'package:aves/model/filters/tag.dart';
import 'package:aves/model/filters/type.dart';
import 'package:aves/model/scenario/enum/scenario_item.dart';
import 'package:aves/model/settings/settings.dart';
import 'package:aves/model/source/album.dart';
import 'package:aves/model/source/collection_lens.dart';
import 'package:aves/model/source/collection_source.dart';
import 'package:aves/model/source/location/country.dart';
import 'package:aves/model/source/location/place.dart';
import 'package:aves/model/source/tag.dart';
import 'package:aves/ref/mime_types.dart';
import 'package:aves/widgets/collection/collection_page.dart';
import 'package:aves/widgets/common/action_mixins/feedback.dart';
import 'package:aves/widgets/common/action_mixins/vault_aware.dart';
import 'package:aves/widgets/common/basic/tv_edge_focus.dart';
import 'package:aves/widgets/common/expandable_filter_row.dart';
import 'package:aves/widgets/common/extensions/build_context.dart';
import 'package:aves/widgets/common/identity/aves_filter_chip.dart';
import 'package:aves/widgets/common/search/delegate.dart';
import 'package:aves/widgets/common/search/page.dart';
import 'package:aves/widgets/filter_grids/common/action_delegates/chip.dart';
import 'package:aves/widgets/search/fgw_filter_make_dialog.dart';
import 'package:aves/widgets/search/query_helper_dialog.dart';
import 'package:aves/widgets/settings/privacy/file_picker/file_picker_page.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CollectionSearchDelegate extends AvesSearchDelegate with FeedbackMixin, VaultAwareMixin {
  final CollectionSource source;
  final CollectionLens? parentCollection;
  final ValueNotifier<String?> _expandedSectionNotifier = ValueNotifier(null);
  final FocusNode _suggestionsTopFocusNode = FocusNode();
  final ScrollController _suggestionsScrollController = ScrollController();

  @override
  FocusNode? get suggestionsFocusNode => _suggestionsTopFocusNode;

  @override
  ScrollController get suggestionsScrollController => _suggestionsScrollController;

  static const int searchHistoryCount = 10;
  static final typeFilters = [
    FavouriteFilter.instance,
    MimeFilter.image,
    MimeFilter.video,
    TypeFilter.animated,
    TypeFilter.motionPhoto,
    AspectRatioFilter.portrait,
    AspectRatioFilter.landscape,
    TypeFilter.panorama,
    TypeFilter.sphericalVideo,
    TypeFilter.geotiff,
    TypeFilter.hdr,
    TypeFilter.raw,
    MimeFilter(MimeTypes.svg),
  ];

  static final _monthFilters = List.generate(12, (i) => DateFilter(DateLevel.m, DateTime(1, i + 1)));

  CollectionSearchDelegate({
    required super.searchFieldLabel,
    required super.searchFieldStyle,
    required this.source,
    this.parentCollection,
    super.canPop,
    String? initialQuery,
  }) : super(
          routeName: SearchPage.routeName,
        ) {
    query = initialQuery ?? '';
  }

  @override
  void dispose() {
    _expandedSectionNotifier.dispose();
    _suggestionsTopFocusNode.dispose();
    _suggestionsScrollController.dispose();
    super.dispose();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final upQuery = query.trim().toUpperCase();
    bool containQuery(String s) => s.toUpperCase().contains(upQuery);
    return SafeArea(
      child: NotificationListener<FilterNotification>(
        onNotification: (notification) {
          _select(context, notification.filter);
          return true;
        },
        child: ValueListenableBuilder<String?>(
          valueListenable: _expandedSectionNotifier,
          builder: (context, expandedSection, child) {
            final queryFilter = _buildQueryFilter(false);
            return Selector<Settings, Set<CollectionFilter>>(
              selector: (context, s) => s.hiddenFilters,
              builder: (context, hiddenFilters, child) {
                bool notHidden(CollectionFilter filter) => !hiddenFilters.contains(filter);

                final visibleTypeFilters = typeFilters.where(notHidden).toList();
                if (hiddenFilters.contains(MimeFilter.video)) {
                  [MimeFilter.image, TypeFilter.sphericalVideo].forEach(visibleTypeFilters.remove);
                }

                final history = settings.searchHistory.where(notHidden).toList();

                return ListView(
                  controller: _suggestionsScrollController,
                  padding: const EdgeInsets.only(top: 8),
                  children: [
                    TvEdgeFocus(
                      focusNode: _suggestionsTopFocusNode,
                    ),
                    _buildFilterRow(
                      context: context,
                      filters: [
                        queryFilter,
                        ...visibleTypeFilters,
                      ].whereNotNull().where((f) => containQuery(f.getLabel(context))).toList(),
                      // usually perform hero animation only on tapped chips,
                      // but we also need to animate the query chip when it is selected by submitting the search query
                      heroTypeBuilder: (filter) => filter == queryFilter ? HeroType.always : HeroType.onTap,
                    ),
                    if (upQuery.isEmpty && history.isNotEmpty)
                      _buildFilterRow(
                        context: context,
                        title: context.l10n.searchRecentSectionTitle,
                        filters: history,
                      ),
                    _buildHelperQueryFilters(context, containQuery),
                    _buildDateFilters(context, containQuery),
                    _buildAlbumFilters(containQuery),
                    _buildCountryFilters(containQuery),
                    _buildStateFilters(containQuery),
                    _buildPlaceFilters(containQuery),
                    _buildTagFilters(containQuery),
                    _buildRatingFilters(context, containQuery),
                    _buildMetadataFilters(context, containQuery),
                    if (assignRecords.all.isNotEmpty) _buildAssignFilters(context, containQuery),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildFilterRow({
    required BuildContext context,
    String? title,
    required List<CollectionFilter> filters,
    HeroType Function(CollectionFilter filter)? heroTypeBuilder,
  }) {
    void onTap(filter) => _select(context, filter is QueryFilter ? QueryFilter(filter.query) : filter);
    const onLongPress = AvesFilterChip.showDefaultLongPressMenu;
    return title != null
        ? TitledExpandableFilterRow(
            title: title,
            filters: filters,
            expandedNotifier: _expandedSectionNotifier,
            heroTypeBuilder: heroTypeBuilder,
            onTap: onTap,
            onLongPress: onLongPress,
          )
        : ExpandableFilterRow(
            filters: filters,
            isExpanded: false,
            heroTypeBuilder: heroTypeBuilder,
            onTap: onTap,
            onLongPress: onLongPress,
          );
  }

  Widget _buildQueryHelpDialogFilterRow({
    required BuildContext context,
    String? title,
    required List<CollectionFilter> filters,
    HeroType Function(CollectionFilter filter)? heroTypeBuilder,
  }) {
    void onTap(filter) => _makeRealQuery(context, filter.query);
    return title != null
        ? TitledExpandableFilterRow(
            title: title,
            filters: filters,
            expandedNotifier: _expandedSectionNotifier,
            heroTypeBuilder: heroTypeBuilder,
            onTap: onTap,
            onLongPress: null,
          )
        : ExpandableFilterRow(
            filters: filters,
            isExpanded: false,
            heroTypeBuilder: heroTypeBuilder,
            onTap: onTap,
            onLongPress: null,
          );
  }

  Future<void> _makeRealQuery(BuildContext context, String? queryKey) async {
    if (queryKey == null) {
      goBack(context);
      return;
    }
    //display the FilePickerPage as a modal bottom sheet.
    // To keeps the search page alive in the background
    // and allows the user to interact with the subpage as if it were a dialog.
    if (queryKey == QueryHelperType.path.getName(context)) {
      final path = await showModalBottomSheet<String>(
        context: context,
        builder: (context) => const FilePickerPage(),
        isScrollControlled: true,
      );

      if (path != null && path.isNotEmpty) {
        await _select(context, PathFilter(path));
        return;
      } else {
        goBack(context);
        return;
      }
    } else if (queryKey == QueryHelperType.keyContentFgwUsed.getName(context)) {
      final FgwUsedFilter? filter = await showDialog<FgwUsedFilter>(
        context: context,
        builder: (context) {
          return const FgwUsedFilterDialog();
        },
      );

      if (filter != null) {
        await _select(context, filter);
      } else {
        goBack(context);
      }
      return;
    }
    // else, build a real query filter.
    String keyContent;

    if (queryKey == QueryHelperType.keyContentTime2Now.getName(context)) {
      keyContent = QueryFilter.keyContentTime2Now;
    } else if (queryKey == QueryHelperType.keyContentSize.getName(context)) {
      keyContent = QueryFilter.keyContentSize;
    } else if (queryKey == QueryHelperType.keyContentWidth.getName(context)) {
      keyContent = QueryFilter.keyContentWidth;
    } else if (queryKey == QueryHelperType.keyContentHeight.getName(context)) {
      keyContent = QueryFilter.keyContentHeight;
    } else if (queryKey == QueryHelperType.keyContentDay.getName(context)) {
      keyContent = QueryFilter.keyContentDay;
    } else if (queryKey == QueryHelperType.keyContentMonth.getName(context)) {
      keyContent = QueryFilter.keyContentMonth;
    } else if (queryKey == QueryHelperType.keyContentYear.getName(context)) {
      keyContent = QueryFilter.keyContentYear;
    } else if (queryKey == QueryHelperType.keyContentId.getName(context)) {
      keyContent = QueryFilter.keyContentId;
    } else {
      keyContent = '';
      goBack(context);
      return;
    }

    String operator = '<';
    if (keyContent == QueryFilter.keyContentSize ||
        keyContent == QueryFilter.keyContentHeight ||
        keyContent == QueryFilter.keyContentWidth) {
      operator = '>';
    }
    final finalQuery = await showDialog<String>(
      context: context,
      builder: (context) {
        return QueryFilterDialog(
          queryKey: keyContent,
          operator: operator,
        );
      },
    );

    if (finalQuery == null) return;

    final realQueryFilter = QueryFilter(finalQuery);
    await _select(context, realQueryFilter);
  }

  Widget _buildHelperQueryFilters(BuildContext context, _ContainQuery containQuery) {
    final _helperQueryFilters = [
      QueryFilter(QueryHelperType.path.getName(context)),
      QueryFilter(QueryHelperType.keyContentTime2Now.getName(context)),
      QueryFilter(QueryHelperType.keyContentSize.getName(context)),
      QueryFilter(QueryHelperType.keyContentFgwUsed.getName(context)),
      QueryFilter(QueryHelperType.keyContentWidth.getName(context)),
      QueryFilter(QueryHelperType.keyContentHeight.getName(context)),
      QueryFilter(QueryHelperType.keyContentDay.getName(context)),
      QueryFilter(QueryHelperType.keyContentMonth.getName(context)),
      QueryFilter(QueryHelperType.keyContentYear.getName(context)),
      QueryFilter(QueryHelperType.keyContentId.getName(context)),
    ];
    final filters = [
      ..._helperQueryFilters,
    ].where((f) => containQuery(f.getLabel(context))).toList();
    return _buildQueryHelpDialogFilterRow(
      context: context,
      title: context.l10n.searchQueryHelperSectionTitle,
      filters: filters,
    );
  }

  Widget _buildDateFilters(BuildContext context, _ContainQuery containQuery) {
    final filters = [
      DateFilter.onThisDay,
      RecentlyAddedFilter.instance,
      ..._monthFilters,
    ].where((f) => containQuery(f.getLabel(context))).toList();
    return _buildFilterRow(
      context: context,
      title: context.l10n.searchDateSectionTitle,
      filters: filters,
    );
  }

  Widget _buildAssignFilters(BuildContext context, _ContainQuery containQuery) {
    final _assignFilter =
        assignRecords.all.where((e) => e.isActive).map((item) => AssignFilter(item.id, item.labelName)).toList();

    return _buildFilterRow(
      context: context,
      title: context.l10n.searchAssignSectionTitle,
      filters: _assignFilter,
    );
  }

  Widget _buildAlbumFilters(_ContainQuery containQuery) {
    return StreamBuilder(
      stream: source.eventBus.on<AlbumsChangedEvent>(),
      builder: (context, snapshot) {
        final filters = source.rawAlbums
            .map((album) => AlbumFilter(
                  album,
                  source.getAlbumDisplayName(context, album),
                ))
            .where((filter) => containQuery(filter.displayName ?? filter.album))
            .toList()
          ..sort();
        return _buildFilterRow(
          context: context,
          title: context.l10n.searchAlbumsSectionTitle,
          filters: filters,
        );
      },
    );
  }

  Widget _buildCountryFilters(_ContainQuery containQuery) {
    return StreamBuilder(
      stream: source.eventBus.on<CountriesChangedEvent>(),
      builder: (context, snapshot) {
        return _buildFilterRow(
          context: context,
          title: context.l10n.searchCountriesSectionTitle,
          filters:
              source.sortedCountries.where(containQuery).map((s) => LocationFilter(LocationLevel.country, s)).toList(),
        );
      },
    );
  }

  Widget _buildStateFilters(_ContainQuery containQuery) {
    return StreamBuilder(
      stream: source.eventBus.on<PlacesChangedEvent>(),
      builder: (context, snapshot) {
        return _buildFilterRow(
          context: context,
          title: context.l10n.searchStatesSectionTitle,
          filters: source.sortedStates.where(containQuery).map((s) => LocationFilter(LocationLevel.state, s)).toList(),
        );
      },
    );
  }

  Widget _buildPlaceFilters(_ContainQuery containQuery) {
    return StreamBuilder(
      stream: source.eventBus.on<PlacesChangedEvent>(),
      builder: (context, snapshot) {
        return _buildFilterRow(
          context: context,
          title: context.l10n.searchPlacesSectionTitle,
          filters: source.sortedPlaces.where(containQuery).map((s) => LocationFilter(LocationLevel.place, s)).toList(),
        );
      },
    );
  }

  Widget _buildTagFilters(_ContainQuery containQuery) {
    return StreamBuilder(
      stream: source.eventBus.on<TagsChangedEvent>(),
      builder: (context, snapshot) {
        return _buildFilterRow(
          context: context,
          title: context.l10n.searchTagsSectionTitle,
          filters: source.sortedTags.where(containQuery).map(TagFilter.new).toList(),
        );
      },
    );
  }

  Widget _buildRatingFilters(BuildContext context, _ContainQuery containQuery) {
    return _buildFilterRow(
      context: context,
      title: context.l10n.searchRatingSectionTitle,
      filters: [5, 4, 3, 2, 1, -1].map(RatingFilter.new).where((f) => containQuery(f.getLabel(context))).toList(),
    );
  }

  Widget _buildMetadataFilters(BuildContext context, _ContainQuery containQuery) {
    return _buildFilterRow(
      context: context,
      title: context.l10n.searchMetadataSectionTitle,
      filters: [
        MissingFilter.date,
        LocationFilter.unlocated,
        MissingFilter.fineAddress,
        TagFilter(''),
        RatingFilter(0),
        MissingFilter.title,
      ].where((f) => containQuery(f.getLabel(context))).toList(),
    );
  }

  var _selectingFromQuery = false;

  @override
  Widget buildResults(BuildContext context) {
    // guard against multiple build calls
    if (!_selectingFromQuery) {
      _selectingFromQuery = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // `buildResults` is called in the build phase,
        // so we post the call that will filter the collection
        // and possibly trigger a rebuild here
        _select(context, _buildQueryFilter(true));
      });
    }
    return const SizedBox();
  }

  QueryFilter? _buildQueryFilter(bool colorful) {
    final cleanQuery = query.trim();
    return cleanQuery.isNotEmpty ? QueryFilter(cleanQuery, colorful: colorful) : null;
  }

  Future<void> _select(BuildContext context, CollectionFilter? filter) async {
    if (filter == null) {
      goBack(context);
      return;
    }

    if (!await unlockFilter(context, filter)) return;

    if (settings.saveSearchHistory) {
      final history = settings.searchHistory
        ..remove(filter)
        ..insert(0, filter);
      settings.searchHistory = history.take(searchHistoryCount).toList();
    }
    if (parentCollection != null) {
      _applyToParentCollectionPage(context, filter);
    } else {
      _jumpToCollectionPage(context, {filter});
    }
  }

  void _applyToParentCollectionPage(BuildContext context, CollectionFilter filter) {
    parentCollection!.addFilter(filter);
    if (Navigator.canPop(context)) {
      // We delay closing the current page after applying the filter selection
      // so that hero animation target is ready in the `FilterBar`,
      // even when the target is a child of an `AnimatedList`.
      // Do not use `WidgetsBinding.instance.addPostFrameCallback`,
      // as it may not trigger if there is no subsequent build.
      Future.delayed(const Duration(milliseconds: 100), () => goBack(context));
    } else {
      _jumpToCollectionPage(context, parentCollection!.filters);
    }
  }

  void _jumpToCollectionPage(BuildContext context, Set<CollectionFilter> filters) {
    clean();
    Navigator.maybeOf(context)?.pushAndRemoveUntil(
      MaterialPageRoute(
        settings: const RouteSettings(name: CollectionPage.routeName),
        builder: (context) => CollectionPage(
          source: source,
          filters: filters,
        ),
      ),
      (route) => false,
    );
  }
}

typedef _ContainQuery = bool Function(String s);
