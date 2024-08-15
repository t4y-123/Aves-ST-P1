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
    return Selector<Settings, (ScenarioChipGroupFactor, ChipSortFactor, bool, Set<CollectionFilter>)>(
      selector: (context, s) =>
          (s.scenarioGroupFactor, s.scenarioSortFactor, s.scenarioSortReverse, s.scenarioPinnedFilters),
      shouldRebuild: (t1, t2) {
        // `Selector` by default uses `DeepCollectionEquality`, which does not go deep in collections within records
        const eq = DeepCollectionEquality();
        return !(eq.equals(t1.$1, t2.$1) &&
            eq.equals(t1.$2, t2.$2) &&
            eq.equals(t1.$3, t2.$3) &&
            eq.equals(t1.$4, t2.$4));
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
                showHeaders: settings.scenarioGroupFactor != ScenarioChipGroupFactor.none,
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
    return filters
        .where((item) => (item.filter.displayName ?? item.filter.scenario.labelName).toUpperCase().contains(query))
        .toList();
  }

  static List<FilterGridItem<ScenarioFilter>> getScenarioGridItems(BuildContext context, CollectionSource source) {
    final filters = scenarios.all.map((scenario) => ScenarioFilter(scenario.id, scenario.labelName)).toSet();
    debugPrint('getScenarioGridItems filters $filters');
    return FilterNavigationPage.sort(settings.scenarioSortFactor, settings.scenarioSortReverse, source, filters);
  }

  static Map<ChipSectionKey, List<FilterGridItem<ScenarioFilter>>> groupToSections(
      BuildContext context, CollectionSource source, Iterable<FilterGridItem<ScenarioFilter>> sortedMapEntries) {
    final newFilters = source.getNewScenarioFilters(context);
    final pinned = settings.scenarioPinnedFilters.whereType<ScenarioFilter>();

    final List<FilterGridItem<ScenarioFilter>> newMapEntries = [], pinnedMapEntries = [], unpinnedMapEntries = [];
    for (final item in sortedMapEntries) {
      final filter = item.filter;
      if (newFilters.contains(filter)) {
        newMapEntries.add(item);
      } else if (pinned.contains(filter)) {
        pinnedMapEntries.add(item);
      }
      //t4y: in scenario, use pinned to well-marked that what scenarios is active.
      unpinnedMapEntries.add(item);
      debugPrint('getScenarioGridItems unpinnedMapEntries $unpinnedMapEntries');
    }

    var sections = <ChipSectionKey, List<FilterGridItem<ScenarioFilter>>>{};
    final activePinnedKey = ScenarioImportanceSectionKey.activePinned(context);
    final excludeUniqueKey = ScenarioImportanceSectionKey.excludeUnique(context);
    final intersectAndKey = ScenarioImportanceSectionKey.intersectAnd(context);
    final unionOrKey = ScenarioImportanceSectionKey.unionOr(context);
    sections = groupBy<FilterGridItem<ScenarioFilter>, ChipSectionKey>(unpinnedMapEntries, (kv) {
      switch ((kv.filter.scenario.loadType)) {
        case ScenarioLoadType.excludeEach:
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
      case ScenarioChipGroupFactor.importance:
        sections = {
          // group ordering
          if (sections.containsKey(activePinnedKey)) activePinnedKey: sections[activePinnedKey]!,
          if (sections.containsKey(excludeUniqueKey)) excludeUniqueKey: sections[excludeUniqueKey]!,
          if (sections.containsKey(intersectAndKey)) intersectAndKey: sections[intersectAndKey]!,
          if (sections.containsKey(unionOrKey)) unionOrKey: sections[unionOrKey]!,
        };
      case ScenarioChipGroupFactor.intersectBeforeUnion:
        sections = {
          // group ordering
          if (sections.containsKey(activePinnedKey)) activePinnedKey: sections[activePinnedKey]!,
          if (sections.containsKey(excludeUniqueKey)) excludeUniqueKey: sections[excludeUniqueKey]!,
          if (sections.containsKey(intersectAndKey)) intersectAndKey: sections[intersectAndKey]!,
          if (sections.containsKey(unionOrKey)) unionOrKey: sections[unionOrKey]!,
        };
      case ScenarioChipGroupFactor.unionBeforeIntersect:
        sections = {
          // group ordering
          if (sections.containsKey(activePinnedKey)) activePinnedKey: sections[activePinnedKey]!,
          if (sections.containsKey(excludeUniqueKey)) excludeUniqueKey: sections[excludeUniqueKey]!,
          if (sections.containsKey(unionOrKey)) unionOrKey: sections[unionOrKey]!,
          if (sections.containsKey(intersectAndKey)) intersectAndKey: sections[intersectAndKey]!,
        };
      case ScenarioChipGroupFactor.none:
        return {
          if (sortedMapEntries.isNotEmpty)
            const ChipSectionKey(): [
              ...newMapEntries,
              ...pinnedMapEntries,
              ...unpinnedMapEntries,
            ],
        };
    }
    debugPrint('getScenarioGridItems sections $sections');
    if (pinnedMapEntries.isNotEmpty) {
      sections = Map.fromEntries([
        MapEntry(ScenarioImportanceSectionKey.activePinned(context), pinnedMapEntries),
        ...sections.entries,
      ]);
    }
    return sections;
  }
}
