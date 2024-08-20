import 'package:aves/model/covers.dart';
import 'package:aves/model/filters/filters.dart';
import 'package:aves/model/scenario/enum/scenario_item.dart';
import 'package:aves/model/scenario/scenario.dart';
import 'package:aves/model/settings/settings.dart';
import 'package:aves/model/source/collection_source.dart';
import 'package:aves/model/source/scenario.dart';
import 'package:aves/theme/icons.dart';
import 'package:aves/widgets/common/extensions/build_context.dart';
import 'package:aves/widgets/common/identity/empty.dart';
import 'package:aves/widgets/filter_grids/common/filter_nav_page.dart';
import 'package:aves/widgets/filter_grids/common/section_keys.dart';
import 'package:aves_model/aves_model.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../model/filters/scenario.dart';
import 'common/scenario/scenario_action_set.dart';
import 'common/scenario/status_filter_nav_page.dart';

class ScenarioListPage extends StatelessWidget {
  static const routeName = '/scenario';

  const ScenarioListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final source = context.read<CollectionSource>();
    return Selector<
        Settings,
        (
          ScenarioChipGroupFactor,
          ChipSortFactor,
          bool,
          Set<CollectionFilter>,
          Set<CollectionFilter>,
          Set<CollectionFilter>,
          bool,
        )>(
      selector: (context, s) => (
        s.scenarioGroupFactor,
        s.scenarioSortFactor,
        s.scenarioSortReverse,
        s.scenarioPinnedExcludeFilters,
        s.scenarioPinnedIntersectFilters,
        s.scenarioPinnedUnionFilters,
        s.scenarioLock,
      ),
      shouldRebuild: (t1, t2) {
        // `Selector` by default uses `DeepCollectionEquality`, which does not go deep in collections within records
        const eq = DeepCollectionEquality();
        return !(eq.equals(t1.$1, t2.$1) &&
            eq.equals(t1.$2, t2.$2) &&
            eq.equals(t1.$3, t2.$3) &&
            eq.equals(t1.$4, t2.$4) &&
            eq.equals(t1.$5, t2.$5) &&
            eq.equals(t1.$6, t2.$6) &&
            eq.equals(t1.$7, t2.$7));
      },
      builder: (context, s, child) {
        return StreamBuilder(
          stream: source.eventBus.on<ScenariosChangedEvent>(),
          builder: (context, snapshot) {
            final gridItems = getScenarioGridItems(context, source);
            return StreamBuilder<Set<CollectionFilter>?>(
              // to update sections by tier
              stream: covers.packageChangeStream,
              builder: (context, snapshot) => StatusFilterNavigationPage<ScenarioFilter, ScenarioChipSetActionDelegate>(
                source: source,
                title: context.l10n.scenarioPageTitle,
                sortFactor: settings.scenarioSortFactor,
                showHeaders: true,
                actionDelegate: ScenarioChipSetActionDelegate(gridItems),
                filterSections: groupToSections(context, source, gridItems),
                newFilters: source.getNewScenarioFilters(context),
                applyQuery: applyQuery,
                emptyBuilder: () => EmptyContent(
                  icon: AIcons.album,
                  text: context.l10n.albumEmpty,
                ),
              ),
            );
          },
        );
      },
    );
  }

  // common with album selection page to move/copy entries

  static List<FilterGridItem<ScenarioFilter>> applyQuery(
      BuildContext context, List<FilterGridItem<ScenarioFilter>> filters, String query) {
    return filters.where((item) => (item.filter.displayName).toUpperCase().contains(query)).toList();
  }

  static List<FilterGridItem<ScenarioFilter>> getScenarioGridItems(BuildContext context, CollectionSource source) {
    final filters = scenarios.all
        .where((e) => e.isActive)
        .map((scenario) => ScenarioFilter(scenario.id, scenario.labelName))
        .toSet();
    filters.add(ScenarioFilter(ScenarioFilter.scenarioSettingId, context.l10n.scenarioFilterSettingTitle));
    filters.add(ScenarioFilter(ScenarioFilter.scenarioAddNewItemId, context.l10n.scenarioFilterAddNewTitle));
    filters.add(ScenarioFilter(ScenarioFilter.scenarioOpId, context.l10n.scenarioFilterOpTitle));
    filters.add(ScenarioFilter(ScenarioFilter.scenarioLockUnlockId,
        settings.scenarioLock ? context.l10n.scenarioFilterUnlockTitle : context.l10n.scenarioFilterLockTitle));
    debugPrint('getScenarioGridItems filters $filters');
    return FilterNavigationPage.sort(settings.scenarioSortFactor, settings.scenarioSortReverse, source, filters);
  }

  static Map<ChipSectionKey, List<FilterGridItem<ScenarioFilter>>> groupToSections(
      BuildContext context, CollectionSource source, Iterable<FilterGridItem<ScenarioFilter>> sortedMapEntries) {
    final newFilters = source.getNewScenarioFilters(context);
    final pinned = [
      ...settings.scenarioPinnedExcludeFilters.whereType<ScenarioFilter>(),
      ...settings.scenarioPinnedIntersectFilters.whereType<ScenarioFilter>(),
      ...settings.scenarioPinnedUnionFilters.whereType<ScenarioFilter>(),
    ];
    debugPrint('getScenarioGridItems pinned $pinned');
    final List<FilterGridItem<ScenarioFilter>> newMapEntries = [],
        funcMapEntries = [],
        pinnedMapEntries = [],
        unpinnedMapEntries = [];
    for (final item in sortedMapEntries) {
      final filter = item.filter;
      if (newFilters.contains(filter)) {
        newMapEntries.add(item);
      }
      if (pinned.contains(filter)) {
        pinnedMapEntries.add(item);
      }
      if (filter.scenarioId < 0) {
        funcMapEntries.add(item);
      } else {
        unpinnedMapEntries.add(item);
      }
      //t4y: in scenario, use pinned to well-marked that what scenarios is active.
    }
    debugPrint('getScenarioGridItems unpinnedMapEntries $unpinnedMapEntries');
    debugPrint('getScenarioGridItems pinnedMapEntries $pinnedMapEntries');
    var sections = <ChipSectionKey, List<FilterGridItem<ScenarioFilter>>>{};
    final funcPinnedKey = ScenarioImportanceSectionKey.funcPinned(context);
    final activePinnedKey = ScenarioImportanceSectionKey.activePinned(context);
    final excludeUniqueKey = ScenarioImportanceSectionKey.excludeUnique(context);
    final intersectAndKey = ScenarioImportanceSectionKey.intersectAnd(context);
    final unionOrKey = ScenarioImportanceSectionKey.unionOr(context);
    sections = groupBy<FilterGridItem<ScenarioFilter>, ChipSectionKey>(unpinnedMapEntries, (kv) {
      switch ((kv.filter.scenario?.loadType)) {
        case ScenarioLoadType.excludeUnique:
          return excludeUniqueKey;
        case ScenarioLoadType.intersectAnd:
          return intersectAndKey;
        case ScenarioLoadType.unionOr:
          return unionOrKey;
        default:
          return activePinnedKey;
      }
    });

    switch (settings.scenarioGroupFactor) {
      case ScenarioChipGroupFactor.intersectBeforeUnion:
        sections = {
          // group ordering
          if (sections.containsKey(funcPinnedKey)) activePinnedKey: sections[funcPinnedKey]!,
          if (sections.containsKey(activePinnedKey)) activePinnedKey: sections[activePinnedKey]!,
          if (sections.containsKey(excludeUniqueKey)) excludeUniqueKey: sections[excludeUniqueKey]!,
          if (sections.containsKey(intersectAndKey)) intersectAndKey: sections[intersectAndKey]!,
          if (sections.containsKey(unionOrKey)) unionOrKey: sections[unionOrKey]!,
        };
      case ScenarioChipGroupFactor.unionBeforeIntersect:
        sections = {
          // group ordering
          if (sections.containsKey(funcPinnedKey)) activePinnedKey: sections[funcPinnedKey]!,
          if (sections.containsKey(activePinnedKey)) activePinnedKey: sections[activePinnedKey]!,
          if (sections.containsKey(excludeUniqueKey)) excludeUniqueKey: sections[excludeUniqueKey]!,
          if (sections.containsKey(unionOrKey)) unionOrKey: sections[unionOrKey]!,
          if (sections.containsKey(intersectAndKey)) intersectAndKey: sections[intersectAndKey]!,
        };
    }

    if (pinnedMapEntries.isNotEmpty) {
      sections = Map.fromEntries([
        ...sections.entries,
        MapEntry(ScenarioImportanceSectionKey.activePinned(context), pinnedMapEntries),
      ]);
    }

    if (funcMapEntries.isNotEmpty) {
      sections = Map.fromEntries([
        MapEntry(ScenarioImportanceSectionKey.funcPinned(context), funcMapEntries),
        ...sections.entries,
      ]);
    }

    debugPrint('getScenarioGridItems sections $sections');
    return sections;
  }
}
