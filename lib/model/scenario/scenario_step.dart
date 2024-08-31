import 'dart:convert';

import 'package:aves/model/filters/filters.dart';
import 'package:aves/model/scenario/scenario.dart';
import 'package:aves/services/common/services.dart';
import 'package:aves/utils/collection_utils.dart';
import 'package:collection/collection.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

import '../filters/aspect_ratio.dart';
import '../filters/mime.dart';
import '../filters/recent.dart';
import 'enum/scenario_item.dart';

enum ScenarioStepRowsType { all, bridgeAll }

final ScenarioSteps scenarioSteps = ScenarioSteps._private();

class ScenarioSteps with ChangeNotifier {
  Set<ScenarioStepRow> _rows = {};
  Set<ScenarioStepRow> _bridgeRows = {};

//
  ScenarioSteps._private();

  Future<void> init() async {
    _rows = await metadataDb.loadAllScenarioSteps();
    _bridgeRows = await metadataDb.loadAllScenarioSteps();
    await _removeDuplicates();
  }

  Future<void> refresh() async {
    _rows.clear();
    _bridgeRows.clear();
    _rows = await metadataDb.loadAllScenarioSteps();
    _bridgeRows = await metadataDb.loadAllScenarioSteps();
  }

  int get count => _rows.length;

  Set<ScenarioStepRow> get all {
    _removeDuplicates();
    return Set.unmodifiable(_rows);
  }

  Set<ScenarioStepRow> get bridgeAll {
    _removeDuplicates();
    return Set.unmodifiable(_bridgeRows);
  }

  Set<ScenarioStepRow> getAll(ScenarioStepRowsType type) {
    switch (type) {
      case ScenarioStepRowsType.bridgeAll:
        return bridgeAll;
      case ScenarioStepRowsType.all:
      default:
        return all;
    }
  }

  Set<ScenarioStepRow> _getTarget(ScenarioStepRowsType type) {
    switch (type) {
      case ScenarioStepRowsType.bridgeAll:
        return _bridgeRows;
      case ScenarioStepRowsType.all:
      default:
        return _rows;
    }
  }

  Future<void> add(Set<ScenarioStepRow> newRows, {ScenarioStepRowsType type = ScenarioStepRowsType.all}) async {
    final targetSet = _getTarget(type);
    if (type == ScenarioStepRowsType.all) await metadataDb.addScenarioSteps(newRows);
    targetSet.addAll(newRows);
    await _removeDuplicates();
    notifyListeners();
  }

  Future<void> setRows(Set<ScenarioStepRow> newRows, {ScenarioStepRowsType type = ScenarioStepRowsType.all}) async {
    await removeEntries(newRows, type: type);
    for (var row in newRows) {
      await set(
        id: row.id,
        scenarioId: row.scenarioId,
        stepNum: row.stepNum,
        orderNum: row.orderNum,
        labelName: row.labelName,
        isActive: row.isActive,
        loadType: row.loadType,
        filters: row.filters,
        dateMillis: row.dateMillis,
        type: type,
      );
    }
    notifyListeners();
  }

  Future<void> set({
    required int id,
    required int scenarioId,
    required int stepNum,
    required int orderNum,
    required String labelName,
    required ScenarioStepLoadType loadType,
    required Set<CollectionFilter>? filters,
    required int dateMillis,
    required bool isActive,
    ScenarioStepRowsType type = ScenarioStepRowsType.all,
  }) async {
    final targetSet = _getTarget(type);

    final oldRows = targetSet.where((row) => row.id == id).toSet();
    targetSet.removeAll(oldRows);
    if (type == ScenarioStepRowsType.all) await metadataDb.removeScenarioSteps(oldRows);
    final row = ScenarioStepRow(
      id: id,
      scenarioId: scenarioId,
      stepNum: stepNum,
      orderNum: orderNum,
      labelName: labelName,
      loadType: loadType,
      filters: filters,
      dateMillis: dateMillis,
      isActive: isActive,
    );

    debugPrint('$runtimeType set ScenarioStepRow $row');
    targetSet.add(row);
    if (type == ScenarioStepRowsType.all) await metadataDb.addScenarioSteps({row});
    await _removeDuplicates();
    notifyListeners();
  }

  Future<void> removeEntries(Set<ScenarioStepRow> rows, {ScenarioStepRowsType type = ScenarioStepRowsType.all}) async {
    await removeIds(rows.map((row) => row.id).toSet(), type: type);
  }

  Future<void> removeNumbers(Set<int> rowNums, {ScenarioStepRowsType type = ScenarioStepRowsType.all}) async {
    final targetSet = _getTarget(type);

    final removedRows = targetSet.where((row) => rowNums.contains(row.id)).toSet();
    if (type == ScenarioStepRowsType.all) await metadataDb.removeScenarioSteps(removedRows);
    removedRows.forEach(targetSet.remove);
    notifyListeners();
  }

  Future<void> removeIds(Set<int> rowIds, {ScenarioStepRowsType type = ScenarioStepRowsType.all}) async {
    final targetSet = _getTarget(type);

    final removedRows = targetSet.where((row) => rowIds.contains(row.id)).toSet();
    // only the all type affect the database.
    if (type == ScenarioStepRowsType.all) await metadataDb.removeScenarioSteps(removedRows);
    removedRows.forEach(targetSet.remove);
    notifyListeners();
  }

  Future<void> _removeDuplicates() async {
    final uniqueRows = <String, ScenarioStepRow>{};
    final duplicateRows = <ScenarioStepRow>{};
    for (var row in _rows) {
      String key;
      key = '${row.scenarioId}-${row.stepNum}-${row.isActive}';
      if (uniqueRows.containsKey(key)) {
        duplicateRows.add(uniqueRows[key]!);
      }
      uniqueRows[key] = row; // This will keep the last occurrence
    }
    _rows = uniqueRows.values.toSet();
    if (duplicateRows.isNotEmpty) {
      await metadataDb.removeScenarioSteps(duplicateRows);
    }
  }

  Future<void> clear({ScenarioStepRowsType type = ScenarioStepRowsType.all}) async {
    final targetSet = _getTarget(type);

    if (type == ScenarioStepRowsType.all) await metadataDb.clearScenarioSteps();
    targetSet.clear();
    notifyListeners();
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
    ScenarioStepRowsType type = ScenarioStepRowsType.all,
  }) {
    var thisScenario = type == ScenarioStepRowsType.all
        ? scenarios.all.firstWhereOrNull((e) => e.id == scenarioId)
        : scenarios.bridgeAll.firstWhereOrNull((e) => e.id == scenarioId);
    thisScenario ??= scenarios.all.first;

    filters ??= {AspectRatioFilter.portrait, MimeFilter.image, RecentlyAddedFilter.instance};

    dateMillis = DateTime.now().millisecondsSinceEpoch;

    final targetSet = _getTarget(type);
    final relevantItems = isActive ? targetSet.where((item) => item.isActive).toList() : targetSet.toList();
    final relevantSteps =
        isActive ? relevantItems.where((item) => item.scenarioId == scenarioId).toList() : targetSet.toList();
    final maxOrderNum =
        relevantItems.isEmpty ? 0 : relevantItems.map((item) => item.orderNum).reduce((a, b) => a > b ? a : b);
    final maxStepNum =
        relevantSteps.isEmpty ? 0 : relevantSteps.map((item) => item.stepNum).reduce((a, b) => a > b ? a : b);
    final finalStepNum = maxStepNum + existMaxStepNumOffset;
    return ScenarioStepRow(
      id: metadataDb.nextId,
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

  Future<void> syncRowsToBridge() async {
    _bridgeRows.clear();
    _bridgeRows.addAll(_rows);
  }

  Future<void> syncBridgeToRows() async {
    await clear();
    _rows.addAll(_bridgeRows);
    await metadataDb.addScenarioSteps(_rows);
    notifyListeners();
  }

  Future<void> setExistRows(Set<ScenarioStepRow> rows, Map<String, dynamic> newValues,
      {ScenarioStepRowsType type = ScenarioStepRowsType.all}) async {
    final targetSet = _getTarget(type);

    // Make a copy of the targetSet to avoid concurrent modification issues
    final targetSetCopy = targetSet.toSet();

    for (var row in rows) {
      final oldRow = targetSetCopy.firstWhereOrNull((r) => r.id == row.id);
      final updatedRow = ScenarioStepRow(
        id: row.id,
        scenarioId: newValues[ScenarioStepRow.propScenarioId] ?? row.scenarioId,
        stepNum: newValues[ScenarioStepRow.propStepNum] ?? row.stepNum,
        orderNum: newValues[ScenarioStepRow.propOrderNum] ?? row.orderNum,
        labelName: newValues[ScenarioStepRow.propLabelName] ?? row.labelName,
        loadType: newValues[ScenarioStepRow.propLoadType] ?? row.loadType,
        filters: newValues[ScenarioStepRow.propFilters] ?? row.filters,
        dateMillis: newValues[ScenarioStepRow.propDateMills] ?? row.dateMillis,
        isActive: newValues[ScenarioStepRow.propIsActive] ?? row.isActive,
      );
      if (oldRow != null) {
        await removeEntries({oldRow}, type: type);
        await setRows({updatedRow}, type: type);
      } else {
        await add({updatedRow}, type: type);
      }
    }
    await _removeDuplicates();
    notifyListeners();
  }

  // import/export
  Map<String, Map<String, dynamic>>? export() {
    final rows = scenarioSteps.all;
    final jsonMap = Map.fromEntries(rows.map((row) {
      return MapEntry(
        row.id.toString(),
        row.toMap(),
      );
    }));
    return jsonMap.isNotEmpty ? jsonMap : null;
  }

  Future<void> import(dynamic jsonMap) async {
    if (jsonMap is! Map) {
      debugPrint('failed to import wallpaper schedules for jsonMap=$jsonMap');
      return;
    }

    final foundRows = <ScenarioStepRow>{};
    jsonMap.forEach((id, attributes) {
      if (id is String && attributes is Map) {
        try {
          final row = ScenarioStepRow.fromMap(attributes);
          foundRows.add(row);
        } catch (e) {
          debugPrint('failed to import wallpaper schedule for id=$id, attributes=$attributes, error=$e');
        }
      } else {
        debugPrint('failed to import wallpaper schedule for id=$id, attributes=${attributes.runtimeType}');
      }
    });

    if (foundRows.isNotEmpty) {
      await scenarioSteps.clear();
      await scenarioSteps.add(foundRows);
    }
  }
}

@immutable
class ScenarioStepRow extends Equatable implements Comparable<ScenarioStepRow> {
  final int id;
  final int scenarioId;
  final int stepNum;
  final int orderNum;
  final String labelName;
  final ScenarioStepLoadType loadType;
  final Set<CollectionFilter>? filters;
  final int dateMillis;
  final bool isActive;

  // Define property name constants
  static const String propId = 'id';
  static const String propScenarioId = 'scenarioId';
  static const String propStepNum = 'stepNum';
  static const String propOrderNum = 'orderNum';
  static const String propLabelName = 'labelName';
  static const String propLoadType = 'loadType';
  static const String propFilters = 'filters';
  static const String propDateMills = 'dateMillis';
  static const String propIsActive = 'isActive';

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
    required this.id,
    required this.scenarioId,
    required this.stepNum,
    required this.orderNum,
    required this.labelName,
    required this.loadType,
    required this.filters,
    required this.dateMillis,
    required this.isActive,
  });

  static ScenarioStepRow fromMap(Map map) {
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
