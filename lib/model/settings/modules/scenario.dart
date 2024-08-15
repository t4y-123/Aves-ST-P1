import 'package:aves/model/settings/defaults.dart';
import 'package:aves_model/aves_model.dart';
import 'package:collection/collection.dart';

import '../../filters/filters.dart';
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
  static const scenarioPinnedFiltersKey = 'scenario_pinned_filters';
  Set<CollectionFilter> get scenarioPinnedFilters =>
      (getStringList(scenarioPinnedFiltersKey) ?? []).map(CollectionFilter.fromJson).whereNotNull().toSet();
  set scenarioPinnedFilters(Set<CollectionFilter> newValue) =>
      set(scenarioPinnedFiltersKey, newValue.map((filter) => filter.toJson()).toList());
}
