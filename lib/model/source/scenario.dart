import 'package:aves/model/entry/entry.dart';
import 'package:aves/model/scenario/scenario.dart';
import 'package:aves/model/source/collection_source.dart';
import 'package:aves/utils/collection_utils.dart';
import 'package:collection/collection.dart';
import 'package:flutter/widgets.dart';

import '../filters/scenario.dart';

mixin ScenarioMixin on SourceBase {
  final Set<ScenarioRow> _newScenarios = {};

  List<ScenarioRow> get rawScenarios => List.unmodifiable(scenarios.all);

  Set<ScenarioFilter> getNewScenarioFilters(BuildContext context) =>
      Set.unmodifiable(_newScenarios.map((v) => ScenarioFilter(v.id, v.labelName)));

  void notifyScenariosChanged() {
    eventBus.fire(ScenariosChangedEvent());
  }

  void _onScenarioChanged({bool notify = true}) {
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
    Set<String?>? directories,
    bool notify = true,
  }) {
    //t4y:Todo: fire invalid scenario filters later.the
    // if (_filterEntryCountMap.isEmpty && _filterSizeMap.isEmpty && _filterRecentEntryMap.isEmpty) return;
    //
    // if (entries == null && directories == null) {
    //   _filterEntryCountMap.clear();
    //   _filterSizeMap.clear();
    //   _filterRecentEntryMap.clear();
    // } else {
    //   directories ??= {};
    //   if (entries != null) {
    //     directories.addAll(entries.map((entry) => entry.directory).whereNotNull());
    //   }
    //   directories.forEach((directory) {
    //     _filterEntryCountMap.remove(directory);
    //     _filterSizeMap.remove(directory);
    //     _filterRecentEntryMap.remove(directory);
    //   });
    // }
    // if (notify) {
    //   eventBus.fire(ScenarioSummaryInvalidatedEvent(scenarios.all));
    // }
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
  final Set<int?>? scenarioId;

  const ScenarioSummaryInvalidatedEvent(this.scenarioId);
}
