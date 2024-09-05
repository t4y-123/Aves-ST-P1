import 'dart:async';
import 'dart:convert';

import 'package:aves/l10n/l10n.dart';
import 'package:aves/model/presentation/base_bridge_row.dart';
import 'package:aves/model/scenario/enum/scenario_item.dart';
import 'package:aves/model/scenario/scenario_step.dart';
import 'package:aves/model/settings/settings.dart';
import 'package:aves/services/common/services.dart';
import 'package:aves/theme/colors.dart';
import 'package:aves/utils/collection_utils.dart';
import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

final Scenario scenarios = Scenario._private();

class Scenario extends PresentationRows<ScenarioRow> {
  Scenario._private();

  @override
  Future<Set<ScenarioRow>> loadAllRows() async {
    return await metadataDb.loadAllScenarios();
  }

  @override
  Future<void> addRowsToDb(Set<ScenarioRow> newRows) async {
    await metadataDb.addScenarios(newRows);
  }

  @override
  Future<void> removeRowsFromDb(Set<ScenarioRow> removedRows) async {
    await metadataDb.removeScenarios(removedRows);
  }

  @override
  Future<void> clearRowsInDb() async {
    await metadataDb.clearScenarios();
  }

  @override
  Future<void> removeIds(Set<int> rowIds,
      {PresentationRowType type = PresentationRowType.all, bool notify = true}) async {
    await super.removeIds(rowIds, type: type, notify: notify);

    final relateItems = scenarioSteps.getAll(type).where((e) => rowIds.contains(e.scenarioId)).toSet();
    await scenarioSteps.removeRows(relateItems, type: type, notify: notify);
  }

  Future<String> getLabelName(int orderNum, ScenarioLoadType loadType) async {
    AppLocalizations _l10n = await AppLocalizations.delegate.load(settings.appliedLocale);
    final loadName = switch (loadType) {
      ScenarioLoadType.excludeUnique => _l10n.scenarioLoadTypeExclude,
      ScenarioLoadType.unionOr => _l10n.scenarioLoadTypeUnion,
      ScenarioLoadType.intersectAnd => _l10n.scenarioLoadTypeIntersect,
    };
    return '$orderNum-$loadName';
  }

  Future<ScenarioRow> newRow(int existOrderNumOffset,
      {String? labelName,
      ScenarioLoadType? loadType,
      Color? color,
      int? dateMillis,
      bool isActive = true,
      PresentationRowType type = PresentationRowType.all}) async {
    final targetSet = getAll(type);
    final newLoadType = loadType ?? ScenarioLoadType.excludeUnique;
    final relevantItems = isActive ? targetSet.where((item) => item.isActive).toList() : targetSet.toList();
    final maxScenario =
        relevantItems.isEmpty ? 0 : relevantItems.map((item) => item.orderNum).reduce((a, b) => a > b ? a : b);
    final orderNum = maxScenario + existOrderNumOffset;
    return ScenarioRow(
      id: metadataDb.nextId,
      orderNum: orderNum,
      labelName: labelName ?? await getLabelName(orderNum, newLoadType),
      color: color ?? AColors.getRandomColor(),
      loadType: newLoadType,
      dateMillis: dateMillis ?? DateTime.now().millisecondsSinceEpoch,
      isActive: isActive,
    );
  }

  @override
  ScenarioRow importFromMap(Map<String, dynamic> attributes) {
    return ScenarioRow.fromMap(attributes);
  }
}

@immutable
class ScenarioRow extends PresentRow<ScenarioRow> {
  final int orderNum;
  final ScenarioLoadType loadType;
  final Color? color;
  final int dateMillis;

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
    required super.id,
    required this.orderNum,
    required super.labelName,
    required this.loadType,
    required this.color,
    required this.dateMillis,
    required super.isActive,
  });

  factory ScenarioRow.fromMap(Map map) {
    final defaultDisplayType =
        ScenarioLoadType.values.safeByName(map['loadType'] as String, ScenarioLoadType.excludeUnique);
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

  @override
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

  @override
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
