import 'package:aves/model/entry/entry.dart';
import 'package:aves/model/filters/assign.dart';
import 'package:aves/model/source/collection_source.dart';
import 'package:aves/utils/collection_utils.dart';
import 'package:collection/collection.dart';

mixin AssignMixin on SourceBase {
  static const commitCountThreshold = 400;
  static const _stopCheckCountThreshold = 100;

  List<String> sortedAssigns = List.unmodifiable([]);

  void updateAssigns() {
    invalidateAssignFilterSummary();
    eventBus.fire(AssignsChangedEvent());
  }

  // filter summary

  // by assign
  final Map<String, int> _filterEntryCountMap = {}, _filterSizeMap = {};
  final Map<String, AvesEntry?> _filterRecentEntryMap = {};

  void invalidateAssignFilterSummary({
    Set<AvesEntry>? entries,
    Set<int>? assignIds,
    bool notify = true,
  }) {
    if (_filterEntryCountMap.isEmpty && _filterSizeMap.isEmpty && _filterRecentEntryMap.isEmpty) return;

    _filterEntryCountMap.clear();
    _filterSizeMap.clear();
    _filterRecentEntryMap.clear();

    if (notify) {
      eventBus.fire(AssignSummaryInvalidatedEvent(assignIds));
    }
  }

  int assignEntryCount(AssignFilter filter) {
    return _filterEntryCountMap.putIfAbsent(filter.displayName, () => visibleEntries.where(filter.test).length);
  }

  int assignSize(AssignFilter filter) {
    return _filterSizeMap.putIfAbsent(
        filter.displayName, () => visibleEntries.where(filter.test).map((v) => v.sizeBytes).sum);
  }

  AvesEntry? assignRecentEntry(AssignFilter filter) {
    return _filterRecentEntryMap.putIfAbsent(
        filter.displayName, () => sortedEntriesByDate.firstWhereOrNull(filter.test));
  }
}

class CatalogMetadataChangedEvent {}

class AssignsChangedEvent {}

class AssignSummaryInvalidatedEvent {
  final Set<int>? assignIds;

  const AssignSummaryInvalidatedEvent(this.assignIds);
}
