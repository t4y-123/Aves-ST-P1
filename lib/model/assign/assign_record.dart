import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:aves/model/assign/assign_entries.dart';
import 'package:aves/model/assign/enum/assign_item.dart';
import 'package:aves/services/common/services.dart';
import 'package:aves/utils/collection_utils.dart';
import 'package:collection/collection.dart';
import 'package:equatable/equatable.dart';
import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:intl/intl.dart';

import '../../l10n/l10n.dart';
import '../settings/settings.dart';

enum AssignRecordRowsType { all, bridgeAll }

final AssignRecord assignRecords = AssignRecord._private();

class AssignRecord with ChangeNotifier {
  Set<AssignRecordRow> _rows = {};
  Set<AssignRecordRow> _bridgeRows = {};

  AssignRecord._private();

  Future<void> init() async {
    _rows = await metadataDb.loadAllAssignRecords();
    _bridgeRows = await metadataDb.loadAllAssignRecords();
  }

  Future<void> refresh() async {
    _rows.clear();
    _bridgeRows.clear();
    _rows = await metadataDb.loadAllAssignRecords();
    _bridgeRows = await metadataDb.loadAllAssignRecords();
  }

  int get count => _rows.length;

  Set<AssignRecordRow> get all {
    if (settings.canAutoRemoveExpiredTempAssign) {
      final now = DateTime.now().millisecondsSinceEpoch;
      final expirationTime = settings.assignTemporaryExpiredInterval * 1000; // Convert to milliseconds
      final expiredRows = _rows
          .where((row) => (now - row.dateMillis) > expirationTime && row.assignType == AssignRecordType.temporary)
          .toSet();

      if (expiredRows.isNotEmpty) {
        removeRows(expiredRows, type: AssignRecordRowsType.all); // Remove expired records
      }
    }
    return Set.unmodifiable(_rows);
  }

  Set<AssignRecordRow> get bridgeAll => Set.unmodifiable(_bridgeRows);

  Set<AssignRecordRow> _getTarget(AssignRecordRowsType type) {
    switch (type) {
      case AssignRecordRowsType.bridgeAll:
        return _bridgeRows;
      case AssignRecordRowsType.all:
      default:
        return _rows;
    }
  }

  Future<void> add(Set<AssignRecordRow> newRows, {AssignRecordRowsType type = AssignRecordRowsType.all}) async {
    final targetSet = _getTarget(type);
    if (type == AssignRecordRowsType.all) {
      await metadataDb.addAssignRecords(newRows);
    }
    targetSet.addAll(newRows);
    notifyListeners();
  }

  Future<void> setRows(Set<AssignRecordRow> newRows, {AssignRecordRowsType type = AssignRecordRowsType.all}) async {
    for (var row in newRows) {
      await set(
        id: row.id,
        orderNum: row.orderNum,
        labelName: row.labelName,
        color: row.color!,
        assignType: row.assignType,
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
    required AssignRecordType assignType,
    required Color? color,
    required int dateMillis,
    required bool isActive,
    AssignRecordRowsType type = AssignRecordRowsType.all,
  }) async {
    final targetSet = _getTarget(type);

    final oldRows = targetSet.where((row) => row.id == id).toSet();
    targetSet.removeAll(oldRows);
    if (type == AssignRecordRowsType.all) {
      await metadataDb.removeAssignRecords(oldRows);
    }

    final row = AssignRecordRow(
      id: id,
      orderNum: orderNum,
      labelName: labelName,
      assignType: assignType,
      color: color,
      dateMillis: dateMillis,
      isActive: isActive,
    );
    targetSet.add(row);
    if (type == AssignRecordRowsType.all) {
      await metadataDb.addAssignRecords({row});
    }

    notifyListeners();
  }

  Future<void> removeRows(Set<AssignRecordRow> rows, {AssignRecordRowsType type = AssignRecordRowsType.all}) async {
    await removeIds(rows.map((row) => row.id).toSet(), type: type);
  }

  Future<void> removeIds(Set<int> rowIds, {AssignRecordRowsType type = AssignRecordRowsType.all}) async {
    final targetSet = _getTarget(type);

    final removedRows = targetSet.where((row) => rowIds.contains(row.id)).toSet();
    final removeAssignEntries = switch (type) {
      // TODO: Handle this case.
      AssignRecordRowsType.all => assignEntries.all.where((e) => rowIds.contains(e.assignId)).toSet(),
      // TODO: Handle this case.
      AssignRecordRowsType.bridgeAll => assignEntries.bridgeAll.where((e) => rowIds.contains(e.assignId)).toSet(),
    };
    if (type == AssignRecordRowsType.all) {
      await metadataDb.removeAssignRecords(removedRows);
      await assignEntries.removeRows(removeAssignEntries, type: AssignEntryRowsType.all);
    } else {
      await assignEntries.removeRows(removeAssignEntries, type: AssignEntryRowsType.bridgeAll);
    }
    removedRows.forEach(targetSet.remove);

    notifyListeners();
  }

  Future<void> clear({AssignRecordRowsType type = AssignRecordRowsType.all}) async {
    final targetSet = _getTarget(type);

    if (type == AssignRecordRowsType.all) {
      await metadataDb.clearAssignRecords();
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

  Future<String> getLabelName(int orderNum, DateTime dateTime) async {
    AppLocalizations _l10n = await AppLocalizations.delegate.load(settings.appliedLocale);
    final prefix = _l10n.assignFilterNamePrefix;
    return '$prefix $orderNum ${DateFormat('yyyy-MM-dd HH:mm:ss.SSS').format(dateTime)}';
  }

  Future<AssignRecordRow> newRow(int existOrderNumOffset,
      {String? labelName,
      AssignRecordType? assignType,
      Color? color,
      int? dateMillis,
      bool isActive = true,
      AssignRecordRowsType type = AssignRecordRowsType.all}) async {
    final targetSet = _getTarget(type);

    final relevantItems = isActive ? targetSet.where((item) => item.isActive).toList() : targetSet.toList();
    final maxGuardLevel =
        relevantItems.isEmpty ? 0 : relevantItems.map((item) => item.orderNum).reduce((a, b) => a > b ? a : b);
    final orderNum = maxGuardLevel + existOrderNumOffset;
    final finalDateTime = DateTime.now();
    return AssignRecordRow(
      id: metadataDb.nextId,
      orderNum: orderNum,
      labelName: labelName ?? await getLabelName(orderNum, finalDateTime),
      color: color ?? getRandomColor(),
      assignType: assignType ?? AssignRecordType.permanent,
      dateMillis: dateMillis ?? finalDateTime.millisecondsSinceEpoch,
      isActive: isActive,
    );
  }

  Future<void> setExistRows({
    required Set<AssignRecordRow> rows,
    required Map<String, dynamic> newValues,
    AssignRecordRowsType type = AssignRecordRowsType.all,
  }) async {
    final setBridge = type == AssignRecordRowsType.bridgeAll;
    final targetSet = setBridge ? _bridgeRows : _rows;

    debugPrint('$runtimeType setExistRows assignRecords: ${assignRecords.all.map((e) => e.toMap())}\n'
        'row.targetSet:[${targetSet.map((e) => e.toMap())}]  \n'
        'newValues ${newValues.toString()}\n');
    for (var row in rows) {
      final oldRow = targetSet.firstWhereOrNull((r) => r.id == row.id);
      if (oldRow != null) {
        debugPrint('$runtimeType setExistRows:$oldRow');
        targetSet.remove(oldRow);
        if (!setBridge) {
          await metadataDb.removeAssignRecords({oldRow});
        }

        final updatedRow = AssignRecordRow(
          id: row.id,
          orderNum: newValues[AssignRecordRow.propOrderNum] ?? row.orderNum,
          labelName: newValues[AssignRecordRow.propLabelName] ?? row.labelName,
          color: newValues[AssignRecordRow.propColor] ?? row.color,
          assignType: newValues[AssignRecordRow.propAssignType] ?? row.assignType,
          dateMillis: newValues[AssignRecordRow.propDateMills] ?? DateTime.now().millisecondsSinceEpoch,
          isActive: newValues[AssignRecordRow.propIsActive] ?? row.isActive,
        );

        targetSet.add(updatedRow);
        if (!setBridge) {
          await metadataDb.addAssignRecords({updatedRow});
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
    await metadataDb.addAssignRecords(_rows);
    debugPrint('$runtimeType  syncBridgeToRows, after\n'
        'all:[$_rows]'
        'before bridget:[$_bridgeRows]');
    notifyListeners();
  }

  // import/export
  Map<String, Map<String, dynamic>>? export() {
    final rows = assignRecords.all;
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
      debugPrint('failed to import assign filters s for jsonMap=$jsonMap');
      return;
    }

    final foundRows = <AssignRecordRow>{};
    jsonMap.forEach((id, attributes) {
      if (id is String && attributes is Map<String, dynamic>) {
        try {
          final row = AssignRecordRow.fromMap(attributes);
          foundRows.add(row);
        } catch (e) {
          debugPrint('failed to import assign filters  for id=$id, attributes=$attributes, error=$e');
        }
      } else {
        debugPrint('failed to import assign filters  for id=$id, attributes=${attributes.runtimeType}');
      }
    });

    if (foundRows.isNotEmpty) {
      await assignRecords.clear();
      await assignRecords.add(foundRows);
    }
  }
}

@immutable
class AssignRecordRow extends Equatable implements Comparable<AssignRecordRow> {
  final int id;
  final int orderNum;
  final String labelName;
  final AssignRecordType assignType;
  final Color? color;
  final int dateMillis;
  final bool isActive;

  // Define property name constants
  static const String propId = 'id';
  static const String propOrderNum = 'orderNum';
  static const String propLabelName = 'labelName';
  static const String propAssignType = 'assignType';
  static const String propColor = 'color';
  static const String propDateMills = 'dateMillis';
  static const String propIsActive = 'isActive';

  @override
  List<Object?> get props => [
        id,
        orderNum,
        labelName,
        assignType,
        color,
        dateMillis,
        isActive,
      ];

  const AssignRecordRow({
    required this.id,
    required this.orderNum,
    required this.labelName,
    required this.assignType,
    required this.color,
    required this.dateMillis,
    required this.isActive,
  });

  static AssignRecordRow fromMap(Map map) {
    final defaultAssignRecordType =
        AssignRecordType.values.safeByName(map['assignType'] as String, AssignRecordType.permanent);
    //debugPrint('AssignRecordRow defaultAssignRecordType $defaultAssignRecordType fromMap:\n  $map.');
    final colorValue = map['color'] as String?;
    //debugPrint('$AssignRecordRow colorValue $colorValue ${colorValue!.toColor}');
    final color = colorValue?.toColor;
    return AssignRecordRow(
      id: map['id'] as int,
      orderNum: map['orderNum'] as int,
      labelName: map['labelName'] as String,
      assignType: defaultAssignRecordType,
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
        'assignType': assignType.name,
        'color': '0x${color?.value.toRadixString(16).padLeft(8, '0')}',
        'dateMillis': dateMillis,
        'isActive': isActive ? 1 : 0,
      };

  @override
  int compareTo(AssignRecordRow other) {
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

    // If orderNum is the same, sort by assignType
    final assignTypeComparison = assignType.index.compareTo(other.assignType.index);
    if (assignTypeComparison != 0) {
      return assignTypeComparison;
    }

    // If assignType is the same, sort by labelName
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

  AssignRecordRow copyWith({
    int? id,
    int? orderNum,
    String? labelName,
    AssignRecordType? assignType,
    Color? color,
    int? dateMillis,
    bool? isActive,
  }) {
    return AssignRecordRow(
      id: id ?? this.id,
      orderNum: orderNum ?? this.orderNum,
      labelName: labelName ?? this.labelName,
      assignType: assignType ?? this.assignType,
      color: color ?? this.color,
      dateMillis: dateMillis ?? this.dateMillis,
      isActive: isActive ?? this.isActive,
    );
  }
}
