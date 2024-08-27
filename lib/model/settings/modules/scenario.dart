import 'package:aves/model/assign/enum/assign_item.dart';
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

  static const scenarioLockKey = 'scenario_lock';
  bool get scenarioLock => getBool(scenarioLockKey) ?? SettingsDefaults.scenarioLock;
  set scenarioLock(bool newValue) => set(scenarioLockKey, newValue);

  static const scenarioLockTypeKey = 'scenario_lock_type';

  ScenarioLockType get scenarioLockType =>
      getEnumOrDefault(scenarioLockTypeKey, SettingsDefaults.scenarioLockType, ScenarioLockType.values);

  set scenarioLockType(ScenarioLockType newValue) => set(scenarioLockTypeKey, newValue.toString());

  static const scenarioLockPassKey = 'scenario_lock_password';

  static const canScenarioAffectFgwKey = 'can_scenario_affect_foreground_wallpaper';
  bool get canScenarioAffectFgw => getBool(canScenarioAffectFgwKey) ?? SettingsDefaults.canScenarioAffectFgw;
  set canScenarioAffectFgw(bool newValue) => set(canScenarioAffectFgwKey, newValue);

  static const useScenariosKey = 'use_scenarios';
  bool get useScenarios => getBool(useScenariosKey) ?? SettingsDefaults.useScenarios;
  set useScenarios(bool newValue) => set(useScenariosKey, newValue);

  static const assignTemporaryFollowActionKey = 'assign_temporary_follow_action_type';
  AssignTemporaryFollowAction get assignTemporaryFollowAction => getEnumOrDefault(
      assignTemporaryFollowActionKey, SettingsDefaults.assignTemporaryFollowAction, AssignTemporaryFollowAction.values);

  set assignTemporaryFollowAction(AssignTemporaryFollowAction newValue) =>
      set(assignTemporaryFollowActionKey, newValue.toString());

  static const assignTemporaryExpiredIntervalKey = 'assign_temporary_expired_interval';
  int get assignTemporaryExpiredInterval =>
      getInt(assignTemporaryExpiredIntervalKey) ?? SettingsDefaults.assignTemporaryExpiredInterval;
  set assignTemporaryExpiredInterval(int newValue) => set(assignTemporaryExpiredIntervalKey, newValue);

  static const canAutoRemoveExpiredTempAssignKey = 'can_auto_remove_expired_tmp_assign';
  bool get canAutoRemoveExpiredTempAssign =>
      getBool(canAutoRemoveExpiredTempAssignKey) ?? SettingsDefaults.canAutoRemoveExpiredTempAssign;
  set canAutoRemoveExpiredTempAssign(bool newValue) => set(canAutoRemoveExpiredTempAssignKey, newValue);

  static const autoRemoveCorrespondScenarioAsTempAssignRemoveKey =
      'can_auto_remove_correspond_scenario_when_temp_assign_remove';
  bool get autoRemoveCorrespondScenarioAsTempAssignRemove =>
      getBool(autoRemoveCorrespondScenarioAsTempAssignRemoveKey) ??
      SettingsDefaults.autoRemoveCorrespondScenarioAsTempAssignRemove;
  set autoRemoveCorrespondScenarioAsTempAssignRemove(bool newValue) =>
      set(autoRemoveCorrespondScenarioAsTempAssignRemoveKey, newValue);

  static const autoRemoveTempAssignAsCorrespondScenarioRemoveKey =
      'can_auto_remove_temp_assign_as_remove_relateScenario';
  bool get autoRemoveTempAssignAsCorrespondScenarioRemove =>
      getBool(autoRemoveTempAssignAsCorrespondScenarioRemoveKey) ??
      SettingsDefaults.autoRemoveTempAssignAsCorrespondScenarioRemove;
  set autoRemoveTempAssignAsCorrespondScenarioRemove(bool newValue) =>
      set(autoRemoveTempAssignAsCorrespondScenarioRemoveKey, newValue);

  static const confirmRemoveScenarioKey = 'confirm_remove_scenario';
  set confirmRemoveScenario(bool newValue) => set(confirmRemoveScenarioKey, newValue);
  bool get confirmRemoveScenario => getBool(confirmRemoveScenarioKey) ?? SettingsDefaults.confirmRemoveScenario;

  static const confirmRemoveAssignKey = 'confirm_remove_assign';
  set confirmRemoveAssign(bool newValue) => set(confirmRemoveAssignKey, newValue);
  bool get confirmRemoveAssign => getBool(confirmRemoveAssignKey) ?? SettingsDefaults.confirmRemoveAssign;
}
