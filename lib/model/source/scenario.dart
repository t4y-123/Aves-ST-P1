import 'package:aves/model/entry/entry.dart';
import 'package:aves/model/scenario/scenario.dart';
import 'package:aves/model/scenario/scenario_step.dart';
import 'package:aves/model/source/collection_source.dart';
import 'package:aves/utils/collection_utils.dart';
import 'package:collection/collection.dart';
import 'package:flutter/widgets.dart';

import '../filters/scenario.dart';

mixin ScenarioMixin on SourceBase {
  final Set<ScenarioRow> _newScenarios = {};

  List<ScenarioRow> get rawScenarios => List.unmodifiable(scenarios.all);

  Set<ScenarioRow> _oldScenarios = {};
  Set<ScenarioStepRow> _oldScenarioSteps = {};

  Set<ScenarioFilter> getNewScenarioFilters(BuildContext context) =>
      Set.unmodifiable(_newScenarios.map((v) => ScenarioFilter(v.id, v.labelName)));

  void notifyScenariosChanged() {
    debugPrint('$runtimeType\n'
        '  void notifyScenariosChanged() {  not.fire(ScenariosChangedEvent());) {');
    // Get the current scenarios and scenario steps
    final currentScenarios = scenarios.all;
    final currentScenarioSteps = scenarioSteps.all;

    // Compare current scenarios and steps with the old ones using the generic compare method
    if (!_areSetsEqual(_oldScenarios, currentScenarios) || !_areSetsEqual(_oldScenarioSteps, currentScenarioSteps)) {
      debugPrint('$runtimeType\n'
          '  void notifyScenariosChanged() {  eventBus.fire(ScenariosChangedEvent());) {');

      // Fire the event only if there is a difference
      eventBus.fire(ScenariosChangedEvent());

      // Update the old scenarios and scenario steps with the current sets
      _oldScenarios = Set.from(currentScenarios);
      _oldScenarioSteps = Set.from(currentScenarioSteps);
    }
  }

  /// Generic utility function to compare two sets of any type
  bool _areSetsEqual<T>(Set<T> oldSet, Set<T> newSet) {
    if (oldSet.length != newSet.length) return false;
    return oldSet.containsAll(newSet) && newSet.containsAll(oldSet);
  }

  void updateScenario({bool notify = true}) {
    debugPrint('$runtimeType   void updateScenario({bool notify = true}) {');
    // Notify if required
    if (notify) {
      notifyScenariosChanged();
    }
  }

  // filter summary

  // by directory
  final Map<String, int> _filterEntryCountMap = {}, _filterSizeMap = {};
  final Map<String, AvesEntry?> _filterRecentEntryMap = {};

  void invalidateScenarioFilterSummary({
    Set<AvesEntry>? entries,
    bool notify = true,
  }) {
    //t4y:always rebuild all scenario if change.
    _filterEntryCountMap.clear();
    _filterSizeMap.clear();
    _filterRecentEntryMap.clear();
    if (notify) {
      //debugPrint(' eventBus.fire(ScenarioSummaryInvalidatedEvent');
      eventBus.fire(const ScenarioSummaryInvalidatedEvent(null));
    }
  }

  int scenarioEntryCount(ScenarioFilter filter) {
    return _filterEntryCountMap.putIfAbsent(filter.displayName, () => visibleEntries.where(filter.test).length);
  }

  int scenarioSize(ScenarioFilter filter) {
    return _filterSizeMap.putIfAbsent(
        filter.displayName, () => visibleEntries.where(filter.test).map((v) => v.sizeBytes).sum);
  }

  AvesEntry? scenarioRecentEntry(ScenarioFilter filter) {
    return _filterRecentEntryMap.putIfAbsent(
        filter.displayName, () => sortedEntriesByDate.firstWhereOrNull(filter.test));
  }
}

class ScenariosChangedEvent {}

class ScenarioSummaryInvalidatedEvent {
  final Set<int?>? scenarioIds;

  const ScenarioSummaryInvalidatedEvent(this.scenarioIds);
}
