import 'dart:convert';

import 'package:aves/services/common/services.dart';
import 'package:collection/collection.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

enum AssignEntryRowsType { all, bridgeAll }

final AssignEntries assignEntries = AssignEntries._private();

class AssignEntries with ChangeNotifier {
  Set<AssignEntryRow> _rows = {};
  Set<AssignEntryRow> _bridgeRows = {};

//
  AssignEntries._private();

  Future<void> init() async {
    _rows = await metadataDb.loadAllAssignEntries();
    _bridgeRows = await metadataDb.loadAllAssignEntries();
    await _removeDuplicates();
  }

  Future<void> refresh() async {
    _rows.clear();
    _bridgeRows.clear();
    _rows = await metadataDb.loadAllAssignEntries();
    _bridgeRows = await metadataDb.loadAllAssignEntries();
  }

  int get count => _rows.length;

  Set<AssignEntryRow> get all {
    _removeDuplicates();
    return Set.unmodifiable(_rows);
  }

  Set<AssignEntryRow> get bridgeAll {
    _removeDuplicates();
    return Set.unmodifiable(_bridgeRows);
  }

  Set<AssignEntryRow> getAll(AssignEntryRowsType type) {
    switch (type) {
      case AssignEntryRowsType.bridgeAll:
        return bridgeAll;
      case AssignEntryRowsType.all:
      default:
        return all;
    }
  }

  Set<AssignEntryRow> _getTarget(AssignEntryRowsType type) {
    switch (type) {
      case AssignEntryRowsType.bridgeAll:
        return _bridgeRows;
      case AssignEntryRowsType.all:
      default:
        return _rows;
    }
  }

  Future<void> add(Set<AssignEntryRow> newRows, {AssignEntryRowsType type = AssignEntryRowsType.all}) async {
    final targetSet = _getTarget(type);
    if (type == AssignEntryRowsType.all) await metadataDb.addAssignEntries(newRows);
    targetSet.addAll(newRows);
    await _removeDuplicates();
    notifyListeners();
  }

  Future<void> setRows(Set<AssignEntryRow> newRows, {AssignEntryRowsType type = AssignEntryRowsType.all}) async {
    await removeEntries(newRows, type: type);
    for (var row in newRows) {
      await set(
        id: row.id,
        assignId: row.assignId,
        entryId: row.entryId,
        isActive: row.isActive,
        dateMillis: row.dateMillis,
        type: type,
      );
    }
    notifyListeners();
  }

  Future<void> set({
    required int id,
    required int assignId,
    required int entryId,
    required int dateMillis,
    required bool isActive,
    AssignEntryRowsType type = AssignEntryRowsType.all,
  }) async {
    final targetSet = _getTarget(type);

    final oldRows = targetSet.where((row) => row.id == id).toSet();
    targetSet.removeAll(oldRows);
    if (type == AssignEntryRowsType.all) await metadataDb.removeAssignEntries(oldRows);
    final row = AssignEntryRow(
      id: id,
      assignId: assignId,
      entryId: entryId,
      dateMillis: dateMillis,
      isActive: isActive,
    );

    debugPrint('$runtimeType set AssignEntryRow $row');
    targetSet.add(row);
    if (type == AssignEntryRowsType.all) await metadataDb.addAssignEntries({row});
    await _removeDuplicates();
    notifyListeners();
  }

  Future<void> removeEntries(Set<AssignEntryRow> rows, {AssignEntryRowsType type = AssignEntryRowsType.all}) async {
    await removeIds(rows.map((row) => row.id).toSet(), type: type);
  }

  Future<void> removeNumbers(Set<int> rowNums, {AssignEntryRowsType type = AssignEntryRowsType.all}) async {
    final targetSet = _getTarget(type);

    final removedRows = targetSet.where((row) => rowNums.contains(row.id)).toSet();
    if (type == AssignEntryRowsType.all) await metadataDb.removeAssignEntries(removedRows);
    removedRows.forEach(targetSet.remove);
    notifyListeners();
  }

  Future<void> removeIds(Set<int> rowIds, {AssignEntryRowsType type = AssignEntryRowsType.all}) async {
    final targetSet = _getTarget(type);

    final removedRows = targetSet.where((row) => rowIds.contains(row.id)).toSet();
    // only the all type affect the database.
    if (type == AssignEntryRowsType.all) await metadataDb.removeAssignEntries(removedRows);
    removedRows.forEach(targetSet.remove);
    notifyListeners();
  }

  Future<void> _removeDuplicates() async {
    final uniqueRows = <String, AssignEntryRow>{};
    final duplicateRows = <AssignEntryRow>{};
    for (var row in _rows) {
      String key;
      key = '${row.assignId}-${row.entryId}';
      if (uniqueRows.containsKey(key)) {
        duplicateRows.add(uniqueRows[key]!);
      }
      uniqueRows[key] = row; // This will keep the last occurrence
    }
    _rows = uniqueRows.values.toSet();
    if (duplicateRows.isNotEmpty) {
      await metadataDb.removeAssignEntries(duplicateRows);
    }
  }

  Future<void> clear({AssignEntryRowsType type = AssignEntryRowsType.all}) async {
    final targetSet = _getTarget(type);

    await metadataDb.clearAssignEntries();
    targetSet.clear();
    notifyListeners();
  }

  AssignEntryRow newRow({
    required int existMaxOrderNumOffset,
    required int assignId,
    required int entryId,
    int? dateMillis,
    bool isActive = true,
    AssignEntryRowsType type = AssignEntryRowsType.all,
  }) {
    dateMillis = DateTime.now().millisecondsSinceEpoch;
    return AssignEntryRow(
      id: metadataDb.nextId,
      assignId: assignId,
      entryId: entryId,
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
    await metadataDb.addAssignEntries(_rows);
    notifyListeners();
  }

  Future<void> setExistRows(Set<AssignEntryRow> rows, Map<String, dynamic> newValues,
      {AssignEntryRowsType type = AssignEntryRowsType.all}) async {
    final targetSet = _getTarget(type);

    // Make a copy of the targetSet to avoid concurrent modification issues
    final targetSetCopy = targetSet.toSet();

    for (var row in rows) {
      final oldRow = targetSetCopy.firstWhereOrNull((r) => r.id == row.id);
      final updatedRow = AssignEntryRow(
        id: row.id,
        assignId: newValues[AssignEntryRow.propAssignId] ?? row.assignId,
        entryId: newValues[AssignEntryRow.propEntryId] ?? row.entryId,
        dateMillis: newValues[AssignEntryRow.propDateMills] ?? row.dateMillis,
        isActive: newValues[AssignEntryRow.propIsActive] ?? row.isActive,
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
    final rows = assignEntries.all;
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

    final foundRows = <AssignEntryRow>{};
    jsonMap.forEach((id, attributes) {
      if (id is String && attributes is Map) {
        try {
          final row = AssignEntryRow.fromMap(attributes);
          foundRows.add(row);
        } catch (e) {
          debugPrint('failed to import wallpaper schedule for id=$id, attributes=$attributes, error=$e');
        }
      } else {
        debugPrint('failed to import wallpaper schedule for id=$id, attributes=${attributes.runtimeType}');
      }
    });

    if (foundRows.isNotEmpty) {
      await assignEntries.clear();
      await assignEntries.add(foundRows);
    }
  }
}

@immutable
class AssignEntryRow extends Equatable implements Comparable<AssignEntryRow> {
  final int id;
  final int assignId;
  final int entryId;
  final int dateMillis;
  final bool isActive;

  // Define property name constants
  static const String propId = 'id';
  static const String propAssignId = 'assignId';
  static const String propEntryId = 'entryId';
  static const String propDateMills = 'dateMillis';
  static const String propIsActive = 'isActive';

  @override
  List<Object?> get props => [
        id,
        assignId,
        entryId,
        dateMillis,
        isActive,
      ];

  const AssignEntryRow({
    required this.id,
    required this.assignId,
    required this.entryId,
    required this.dateMillis,
    required this.isActive,
  });

  static AssignEntryRow fromMap(Map map) {
    return AssignEntryRow(
      id: map['id'] as int,
      assignId: map['assignId'] as int,
      entryId: map['entryId'] as int,
      dateMillis: map['dateMillis'] as int,
      isActive: (map['isActive'] as int? ?? 0) != 0,
    );
  }

  String toJson() => jsonEncode(toMap());

  Map<String, dynamic> toMap() => {
        'id': id,
        'assignId': assignId,
        'entryId': entryId,
        'dateMillis': dateMillis,
        'isActive': isActive ? 1 : 0,
      };

  @override
  int compareTo(AssignEntryRow other) {
    // Sorting logic
    if (isActive != other.isActive) {
      // Sort by isActive, true (1) comes before false (0)
      return isActive ? -1 : 1;
    }

    final assignIdComparison = assignId.compareTo(other.assignId);
    if (assignIdComparison != 0) {
      return assignIdComparison;
    }

    final entryIdComparison = entryId.compareTo(other.entryId);
    if (entryIdComparison != 0) {
      return entryIdComparison;
    }

    // If labelName is the same, sort by dateMillis
    final dateMillisComparison = dateMillis.compareTo(other.dateMillis);
    if (dateMillisComparison != 0) {
      return dateMillisComparison;
    }

    // If dateMillis is the same, sort by id
    return id.compareTo(other.id);
  }

  AssignEntryRow copyWith({
    int? id,
    int? assignId,
    int? entryId,
    int? dateMillis,
    bool? isActive,
  }) {
    return AssignEntryRow(
      id: id ?? this.id,
      assignId: assignId ?? this.assignId,
      entryId: entryId ?? this.entryId,
      dateMillis: dateMillis ?? this.dateMillis,
      isActive: isActive ?? this.isActive,
    );
  }
}
