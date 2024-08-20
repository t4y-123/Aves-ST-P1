import 'package:aves/model/filters/filters.dart';
import 'package:aves/model/settings/defaults.dart';
import 'package:aves_model/aves_model.dart';
import 'package:collection/collection.dart';

import '../../scenario/enum/scenario_item.dart';

mixin ScenarioSettings on SettingsAccess {
  static const scenarioGroupFactorKey = 'scenario_group_factor';

  ScenarioChipGroupFactor get scenarioGroupFactor =>
      getEnumOrDefault(scenarioGroupFactorKey, SettingsDefaults.scenarioGroupFactor, ScenarioChipGroupFactor.values);

  set scenarioGroupFactor(ScenarioChipGroupFactor newValue) => set(scenarioGroupFactorKey, newValue.toString());

  static const scenarioSortFactorKey = 'scenario_sort_factor';
  ChipSortFactor get scenarioSortFactor =>
      getEnumOrDefault(scenarioSortFactorKey, SettingsDefaults.scenarioChipListSortFactor, ChipSortFactor.values);
  set scenarioSortFactor(ChipSortFactor newValue) => set(scenarioSortFactorKey, newValue.toString());

  static const scenarioSortReverseKey = 'scenario_sort_reverse';
  bool get scenarioSortReverse => getBool(scenarioSortReverseKey) ?? false;
  set scenarioSortReverse(bool newValue) => set(scenarioSortReverseKey, newValue);

  // use the pinned filters as the active scenario.

  static const scenarioPinnedExcludeFiltersKey = 'scenario_pinned_exclude_filters';
  static const scenarioPinnedIntersectFiltersKey = 'scenario_pinned_intersect_filters';
  static const scenarioPinnedUnionFiltersKey = 'scenario_pinned_union_filters';

  Set<CollectionFilter> get scenarioPinnedExcludeFilters =>
      (getStringList(scenarioPinnedExcludeFiltersKey) ?? []).map(CollectionFilter.fromJson).whereNotNull().toSet();

  set scenarioPinnedExcludeFilters(Set<CollectionFilter> newValue) =>
      set(scenarioPinnedExcludeFiltersKey, newValue.map((filter) => filter.toJson()).toList());

  Set<CollectionFilter> get scenarioPinnedIntersectFilters =>
      (getStringList(scenarioPinnedIntersectFiltersKey) ?? []).map(CollectionFilter.fromJson).whereNotNull().toSet();

  set scenarioPinnedIntersectFilters(Set<CollectionFilter> newValue) =>
      set(scenarioPinnedIntersectFiltersKey, newValue.map((filter) => filter.toJson()).toList());

  Set<CollectionFilter> get scenarioPinnedUnionFilters =>
      (getStringList(scenarioPinnedUnionFiltersKey) ?? []).map(CollectionFilter.fromJson).whereNotNull().toSet();

  set scenarioPinnedUnionFilters(Set<CollectionFilter> newValue) =>
      set(scenarioPinnedUnionFiltersKey, newValue.map((filter) => filter.toJson()).toList());
}
