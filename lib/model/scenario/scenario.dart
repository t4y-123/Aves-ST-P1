import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:aves/services/common/services.dart';
import 'package:aves/utils/collection_utils.dart';
import 'package:collection/collection.dart';
import 'package:equatable/equatable.dart';
import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

import '../../l10n/l10n.dart';
import '../settings/settings.dart';
import 'enum/scenario_item.dart';

enum ScenarioRowsType { all, bridgeAll }

final Scenario scenarios = Scenario._private();

class Scenario with ChangeNotifier {
  Set<ScenarioRow> _rows = {};
  Set<ScenarioRow> _bridgeRows = {};

  Scenario._private();

  Future<void> init() async {
    _rows = await metadataDb.loadAllScenarios();
    _bridgeRows = await metadataDb.loadAllScenarios();
  }

  Future<void> refresh() async {
    _rows.clear();
    _bridgeRows.clear();
    _rows = await metadataDb.loadAllScenarios();
    _bridgeRows = await metadataDb.loadAllScenarios();
  }

  int get count => _rows.length;

  Set<ScenarioRow> get all => Set.unmodifiable(_rows);

  Set<ScenarioRow> get bridgeAll => Set.unmodifiable(_bridgeRows);

  Set<ScenarioRow> _getTarget(ScenarioRowsType type) {
    switch (type) {
      case ScenarioRowsType.bridgeAll:
        return _bridgeRows;
      case ScenarioRowsType.all:
      default:
        return _rows;
    }
  }

  Future<void> add(Set<ScenarioRow> newRows, {ScenarioRowsType type = ScenarioRowsType.all}) async {
    final targetSet = _getTarget(type);
    if (type == ScenarioRowsType.all) {
      await metadataDb.addScenarios(newRows);
    }
    targetSet.addAll(newRows);
    notifyListeners();
  }

  Future<void> setRows(Set<ScenarioRow> newRows, {ScenarioRowsType type = ScenarioRowsType.all}) async {
    for (var row in newRows) {
      await set(
        id: row.id,
        orderNum: row.orderNum,
        labelName: row.labelName,
        color: row.color!,
        loadType: row.loadType,
        dateMillis: row.dateMillis,
        isActive: row.isActive,
        type: type,
      );
    }
    notifyListeners();
  }

  Future<void> set({
    required int id,
    required int orderNum,
    required String labelName,
    required ScenarioLoadType loadType,
    required Color? color,
    required int dateMillis,
    required bool isActive,
    ScenarioRowsType type = ScenarioRowsType.all,
  }) async {
    final targetSet = _getTarget(type);

    final oldRows = targetSet.where((row) => row.id == id).toSet();
    targetSet.removeAll(oldRows);
    if (type == ScenarioRowsType.all) {
      await metadataDb.removeScenarios(oldRows);
    }

    final row = ScenarioRow(
      id: id,
      orderNum: orderNum,
      labelName: labelName,
      loadType: loadType,
      color: color,
      dateMillis: dateMillis,
      isActive: isActive,
    );
    targetSet.add(row);
    if (type == ScenarioRowsType.all) {
      await metadataDb.addScenarios({row});
    }

    notifyListeners();
  }

  Future<void> removeEntries(Set<ScenarioRow> rows, {ScenarioRowsType type = ScenarioRowsType.all}) async {
    await removeIds(rows.map((row) => row.id).toSet(), type: type);
  }

  Future<void> removeIds(Set<int> rowIds, {ScenarioRowsType type = ScenarioRowsType.all}) async {
    final targetSet = _getTarget(type);

    final removedRows = targetSet.where((row) => rowIds.contains(row.id)).toSet();
    if (type == ScenarioRowsType.all) {
      await metadataDb.removeScenarios(removedRows);
    }
    removedRows.forEach(targetSet.remove);

    notifyListeners();
  }

  Future<void> clear({ScenarioRowsType type = ScenarioRowsType.all}) async {
    final targetSet = _getTarget(type);

    if (type == ScenarioRowsType.all) {
      await metadataDb.clearScenarios();
    }
    targetSet.clear();

    notifyListeners();
  }

  Color getRandomColor() {
    final Random random = Random();
    return Color.fromARGB(
      255,
      random.nextInt(256),
      random.nextInt(256),
      random.nextInt(256),
    );
  }

  Future<String> getLabelName(int orderNum) async {
    AppLocalizations _l10n = await AppLocalizations.delegate.load(settings.appliedLocale);
    final prefix = _l10n.scenarioNamePrefix;
    return '$prefix $orderNum';
  }

  Future<ScenarioRow> newRow(int existOrderNumOffset,{
        String? labelName,
        ScenarioLoadType? loadType,
        Color? color,
        int? dateMillis,
        bool isActive = true,
        ScenarioRowsType type = ScenarioRowsType.all}) async {

    final targetSet = _getTarget(type);

    final relevantItems = isActive ? targetSet.where((item) => item.isActive).toList() : targetSet.toList();
    final maxGuardLevel =
        relevantItems.isEmpty ? 0 : relevantItems.map((item) => item.orderNum).reduce((a, b) => a > b ? a : b);
    final orderNum = maxGuardLevel + existOrderNumOffset;
    return ScenarioRow(
      id: metadataDb.nextId,
      orderNum: orderNum,
      labelName: labelName ?? await getLabelName(orderNum),
      color: color ?? getRandomColor(),
      loadType: loadType ?? ScenarioLoadType.excludeEach,
      dateMillis: dateMillis ?? DateTime.now().millisecondsSinceEpoch,
      isActive: isActive,
    );
  }

  Future<void> setExistRows({
    required Set<ScenarioRow> rows,
    required Map<String, dynamic> newValues,
    ScenarioRowsType type = ScenarioRowsType.all,
  }) async {
    final setBridge = type == ScenarioRowsType.bridgeAll;
    final targetSet = setBridge ? _bridgeRows : _rows;

    debugPrint('$runtimeType setExistRows scenarios: ${scenarios.all.map((e)=>e.toMap())}\n'
        'row.targetSet:[${targetSet.map((e)=>e.toMap())}]  \n'
        'newValues ${newValues.toString()}\n');
    for (var row in rows) {
      final oldRow = targetSet.firstWhereOrNull((r) => r.id == row.id);
      if (oldRow != null) {
        debugPrint('$runtimeType setExistRows:$oldRow');
        targetSet.remove(oldRow);
        if (!setBridge) {
          await metadataDb.removeScenarios({oldRow});
        }

        final updatedRow = ScenarioRow(
          id: row.id,
          orderNum: newValues[ScenarioRow.propOrderNum] ?? row.orderNum,
          labelName: newValues[ScenarioRow.propLabelName] ?? row.labelName,
          color: newValues[ScenarioRow.propColor] ?? row.color,
          loadType: newValues[ScenarioRow.propLoadType]  ?? row.loadType,
          dateMillis: newValues[ScenarioRow.propDateMills]  ?? DateTime.now().millisecondsSinceEpoch,
          isActive: newValues[ScenarioRow.propIsActive] ?? row.isActive,
        );

        targetSet.add(updatedRow);
        if (!setBridge) {
          await metadataDb.addScenarios({updatedRow});
        }
      }
    }
    notifyListeners();
  }

  Future<void> syncRowsToBridge() async {
    debugPrint('$runtimeType  syncRowsToBridge,\n'
        'all:[$_rows]'
        'before bridget:[$_bridgeRows]');
    _bridgeRows.clear();
    _bridgeRows.addAll(_rows);
    debugPrint('$runtimeType  syncRowsToBridge,\n'
        'after bridget:[$_bridgeRows]');
  }

  Future<void> syncBridgeToRows() async {
    debugPrint('$runtimeType  syncBridgeToRows, before\n'
        'all:[$_rows]'
        'before bridget:[$_bridgeRows]');
    await clear();
    _rows.addAll(_bridgeRows);
    await metadataDb.addScenarios(_rows);
    debugPrint('$runtimeType  syncBridgeToRows, after\n'
        'all:[$_rows]'
        'before bridget:[$_bridgeRows]');
    notifyListeners();
  }

  // import/export
  Map<String, Map<String, dynamic>>? export() {
    final rows = scenarios.all;
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
      debugPrint('failed to import privacy guard levels for jsonMap=$jsonMap');
      return;
    }

    final foundRows = <ScenarioRow>{};
    jsonMap.forEach((id, attributes) {
      if (id is String && attributes is Map<String, dynamic>) {
        try {
          final row = ScenarioRow.fromMap(attributes);
          foundRows.add(row);
        } catch (e) {
          debugPrint('failed to import privacy guard level for id=$id, attributes=$attributes, error=$e');
        }
      } else {
        debugPrint('failed to import privacy guard level for id=$id, attributes=${attributes.runtimeType}');
      }
    });

    if (foundRows.isNotEmpty) {
      await scenarios.clear();
      await scenarios.add(foundRows);
    }
  }
}

@immutable
class ScenarioRow extends Equatable implements Comparable<ScenarioRow> {
  final int id;
  final int orderNum;
  final String labelName;
  final ScenarioLoadType loadType;
  final Color? color;
  final int dateMillis;
  final bool isActive;

  // Define property name constants
  static const String propId = 'id';
  static const String propOrderNum = 'orderNum';
  static const String propLabelName = 'labelName';
  static const String propLoadType = 'loadType';
  static const String propColor = 'color';
  static const String propDateMills = 'dateMillis';
  static const String propIsActive = 'isActive';

  @override
  List<Object?> get props => [
        id,
        orderNum,
        labelName,
        loadType,
        color,
        dateMillis,
        isActive,
      ];

  const ScenarioRow({
    required this.id,
    required this.orderNum,
    required this.labelName,
    required this.loadType,
    required this.color,
    required this.dateMillis,
    required this.isActive,
  });

  static ScenarioRow fromMap(Map map) {
    final defaultDisplayType = ScenarioLoadType.values.safeByName(map['loadType'] as String, ScenarioLoadType.excludeEach);
    //debugPrint('ScenarioRow defaultDisplayType $defaultDisplayType fromMap:\n  $map.');
    final colorValue = map['color'] as String?;
    //debugPrint('$ScenarioRow colorValue $colorValue ${colorValue!.toColor}');
    final color = colorValue?.toColor;
    return ScenarioRow(
      id: map['id'] as int,
      orderNum: map['orderNum'] as int,
      labelName: map['labelName'] as String,
      loadType: defaultDisplayType,
      color: color,
      dateMillis: map['dateMillis'] as int,
      isActive: (map['isActive'] as int? ?? 0) != 0,
    );
  }

  String toJson() => jsonEncode(toMap());

  Map<String, dynamic> toMap() => {
        'id': id,
        'orderNum': orderNum,
        'labelName': labelName,
        'loadType': loadType.name,
        'color': '0x${color?.value.toRadixString(16).padLeft(8, '0')}',
        'dateMillis': dateMillis,
        'isActive': isActive ? 1 : 0,
      };

  @override
  int compareTo(ScenarioRow other) {
    // Sorting logic
    if (isActive != other.isActive) {
      // Sort by isActive, true (1) comes before false (0)
      return isActive ? -1 : 1;
    }

    // If isActive is the same, sort by orderNum
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

  ScenarioRow copyWith({
    int? id,
    int? orderNum,
    String? labelName,
    ScenarioLoadType? loadType,
    Color? color,
    int? dateMillis,
    bool? isActive,
  }) {
    return ScenarioRow(
      id: id ?? this.id,
      orderNum: orderNum ?? this.orderNum,
      labelName: labelName ?? this.labelName,
      loadType: loadType ?? this.loadType,
      color: color ?? this.color,
      dateMillis: dateMillis ?? this.dateMillis,
      isActive: isActive ?? this.isActive,
    );
  }
}
