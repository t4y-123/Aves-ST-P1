import 'dart:convert';

import 'package:aves/model/filters/filters.dart';
import 'package:aves/model/presentation/base_bridge_row.dart';
import 'package:aves/model/scenario/scenario.dart';
import 'package:aves/services/common/services.dart';
import 'package:aves/utils/collection_utils.dart';
import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';

import '../filters/aspect_ratio.dart';
import '../filters/mime.dart';
import '../filters/recent.dart';
import 'enum/scenario_item.dart';

final ScenarioSteps scenarioSteps = ScenarioSteps._private();

class ScenarioSteps extends PresentationRows<ScenarioStepRow> {
  ScenarioSteps._private();

  @override
  Future<Set<ScenarioStepRow>> loadAllRows() async {
    return await localMediaDb.loadAllScenarioSteps();
  }

  @override
  Future<void> addRowsToDb(Set<ScenarioStepRow> newRows) async {
    await localMediaDb.addScenarioSteps(newRows);
  }

  @override
  Future<void> removeRowsFromDb(Set<ScenarioStepRow> removedRows) async {
    await localMediaDb.removeScenarioSteps(removedRows);
  }

  @override
  Future<void> clearRowsInDb() async {
    await localMediaDb.clearScenarioSteps();
  }

  @override
  Future<void> add(Set<ScenarioStepRow> newRows,
      {PresentationRowType type = PresentationRowType.all, bool notify = true}) async {
    await super.add(newRows, type: type, notify: notify);
    await _removeDuplicates(type: type);
  }

  Future<void> _removeDuplicates({PresentationRowType type = PresentationRowType.all}) async {
    final uniqueRows = <String, ScenarioStepRow>{};
    final duplicateRows = <ScenarioStepRow>{};
    final todoRows = getAll(type);
    for (var row in todoRows) {
      String key;
      key = '${row.scenarioId}-${row.stepNum}-${row.isActive}';
      if (uniqueRows.containsKey(key)) {
        duplicateRows.add(uniqueRows[key]!);
      }
      uniqueRows[key] = row; // This will keep the last occurrence
    }
    if (duplicateRows.isNotEmpty) {
      await removeRows(duplicateRows, type: type);
    }
  }

  ScenarioStepRow newRow({
    required int existMaxOrderNumOffset,
    required int scenarioId,
    required int existMaxStepNumOffset,
    String? labelName,
    ScenarioStepLoadType? loadType,
    Set<CollectionFilter>? filters,
    int? dateMillis,
    bool isActive = true,
    PresentationRowType type = PresentationRowType.all,
  }) {
    var thisScenario = type == PresentationRowType.all
        ? scenarios.all.firstWhereOrNull((e) => e.id == scenarioId)
        : scenarios.bridgeAll.firstWhereOrNull((e) => e.id == scenarioId);
    thisScenario ??= scenarios.all.first;

    filters ??= {AspectRatioFilter.landscape.reverse(), MimeFilter.image, RecentlyAddedFilter.instance};

    dateMillis = DateTime.now().millisecondsSinceEpoch;

    final targetSet = getAll(type);
    final relevantItems = isActive ? targetSet.where((item) => item.isActive).toList() : targetSet.toList();
    final relevantSteps =
        isActive ? relevantItems.where((item) => item.scenarioId == scenarioId).toList() : targetSet.toList();
    final maxOrderNum =
        relevantItems.isEmpty ? 0 : relevantItems.map((item) => item.orderNum).reduce((a, b) => a > b ? a : b);
    final maxStepNum =
        relevantSteps.isEmpty ? 0 : relevantSteps.map((item) => item.stepNum).reduce((a, b) => a > b ? a : b);
    final finalStepNum = maxStepNum + existMaxStepNumOffset;

    return ScenarioStepRow(
      id: localMediaDb.nextDateId,
      scenarioId: scenarioId,
      orderNum: maxOrderNum + existMaxOrderNumOffset,
      stepNum: finalStepNum,
      labelName: labelName ?? 'S${thisScenario.orderNum}-$finalStepNum-id_$scenarioId-${thisScenario.labelName}',
      loadType: loadType ?? ScenarioStepLoadType.intersectAnd,
      filters: filters,
      dateMillis: dateMillis,
      isActive: isActive,
    );
  }

  @override
  ScenarioStepRow importFromMap(Map<String, dynamic> attributes) {
    return ScenarioStepRow.fromMap(attributes);
  }
}

@immutable
class ScenarioStepRow extends PresentRow<ScenarioStepRow> {
  final int scenarioId;
  final int stepNum;
  final int orderNum;
  final ScenarioStepLoadType loadType;
  final Set<CollectionFilter>? filters;
  final int dateMillis;

  @override
  List<Object?> get props => [
        id,
        scenarioId,
        stepNum,
        orderNum,
        labelName,
        loadType,
        filters,
        dateMillis,
        isActive,
      ];

  const ScenarioStepRow({
    required super.id,
    required this.scenarioId,
    required this.stepNum,
    required this.orderNum,
    required super.labelName,
    required this.loadType,
    required this.filters,
    required this.dateMillis,
    required super.isActive,
  });

  factory ScenarioStepRow.fromMap(Map map) {
    final defaultDisplayType =
        ScenarioStepLoadType.values.safeByName(map['loadType'] as String, ScenarioStepLoadType.intersectAnd);
    //debugPrint('ScenarioStepRow defaultDisplayType $defaultDisplayType fromMap:\n  $map.');
    final List<dynamic> decodedFilters = jsonDecode(map['filters']);
    final filters = decodedFilters.map((e) => CollectionFilter.fromJson(e as String)).whereNotNull().toSet();

    return ScenarioStepRow(
      id: map['id'] as int,
      scenarioId: map['scenarioId'] as int,
      stepNum: map['stepNum'] as int,
      orderNum: map['orderNum'] as int,
      labelName: map['labelName'] as String,
      loadType: defaultDisplayType,
      filters: filters,
      dateMillis: map['dateMillis'] as int,
      isActive: (map['isActive'] as int? ?? 0) != 0,
    );
  }

  String toJson() => jsonEncode(toMap());

  @override
  Map<String, dynamic> toMap() => {
        'id': id,
        'scenarioId': scenarioId,
        'stepNum': stepNum,
        'orderNum': orderNum,
        'labelName': labelName,
        'loadType': loadType.name,
        'filters': jsonEncode(filters?.map((filter) => filter.toJson()).toList()),
        'dateMillis': dateMillis,
        'isActive': isActive ? 1 : 0,
      };

  @override
  int compareTo(ScenarioStepRow other) {
    // Sorting logic
    if (isActive != other.isActive) {
      // Sort by isActive, true (1) comes before false (0)
      return isActive ? -1 : 1;
    }

    final scenarioIdComparison = scenarioId.compareTo(other.scenarioId);
    if (scenarioIdComparison != 0) {
      return scenarioIdComparison;
    }

    final stepNumComparison = stepNum.compareTo(other.stepNum);
    if (stepNumComparison != 0) {
      return stepNumComparison;
    }

    final orderNumComparison = orderNum.compareTo(other.orderNum);
    if (orderNumComparison != 0) {
      return orderNumComparison;
    }

    // If orderNum is the same, sort by loadType
    final loadTypeComparison = loadType.index.compareTo(other.loadType.index);
    if (loadTypeComparison != 0) {
      return loadTypeComparison;
    }

    // If loadType is the same, sort by labelName
    final labelNameComparison = labelName.compareTo(other.labelName);
    if (labelNameComparison != 0) {
      return labelNameComparison;
    }

    // If labelName is the same, sort by dateMillis
    final dateMillisComparison = dateMillis.compareTo(other.dateMillis);
    if (dateMillisComparison != 0) {
      return dateMillisComparison;
    }

    // If dateMillis is the same, sort by id
    return id.compareTo(other.id);
  }

  @override
  ScenarioStepRow copyWith({
    int? id,
    int? scenarioId,
    int? stepNum,
    int? orderNum,
    String? labelName,
    ScenarioStepLoadType? loadType,
    Set<CollectionFilter>? filters,
    int? dateMillis,
    bool? isActive,
  }) {
    return ScenarioStepRow(
      id: id ?? this.id,
      scenarioId: scenarioId ?? this.scenarioId,
      stepNum: stepNum ?? this.stepNum,
      orderNum: orderNum ?? this.orderNum,
      labelName: labelName ?? this.labelName,
      loadType: loadType ?? this.loadType,
      filters: filters ?? this.filters,
      dateMillis: dateMillis ?? this.dateMillis,
      isActive: isActive ?? this.isActive,
    );
  }
}
