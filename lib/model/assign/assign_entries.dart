import 'dart:convert';

import 'package:aves/model/entry/entry.dart';
import 'package:aves/model/presentation/base_bridge_row.dart';
import 'package:aves/model/source/collection_source.dart';
import 'package:aves/services/common/services.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

enum AssignEntryRowsType { all, bridgeAll }

final AssignEntries assignEntries = AssignEntries._private();

class AssignEntries extends PresentationRows<AssignEntryRow> {
  AssignEntries._private();

  @override
  Future<Set<AssignEntryRow>> loadAllRows() async {
    return await localMediaDb.loadAllAssignEntries();
  }

  @override
  Future<void> addRowsToDb(Set<AssignEntryRow> newRows) async {
    await localMediaDb.addAssignEntries(newRows);
  }

  @override
  Future<void> removeRowsFromDb(Set<AssignEntryRow> removedRows) async {
    await localMediaDb.removeAssignEntries(removedRows);
  }

  @override
  Future<void> clearRowsInDb() async {
    await localMediaDb.clearAssignEntries();
  }

  @override
  AssignEntryRow importFromMap(Map<String, dynamic> attributes) {
    return AssignEntryRow.fromMap(attributes);
  }

  Future<void> removeEntries(Set<AvesEntry> entries,
      {PresentationRowType type = PresentationRowType.all, bool notify = true}) async {
    final entryIds = entries.map((entry) => entry.id).toSet();
    await removeEntryIds(entryIds, type: type, notify: notify);
  }

  Future<void> removeEntryIds(Set<int> rowIds,
      {PresentationRowType type = PresentationRowType.all, bool notify = true}) async {
    await removeRows(all.where((row) => rowIds.contains(row.entryId)).toSet(), type: type, notify: notify);
  }

  @override
  Future<void> add(Set<AssignEntryRow> newRows,
      {PresentationRowType type = PresentationRowType.all, bool notify = true}) async {
    await super.add(newRows, type: type, notify: notify);
    await _removeDuplicates();
  }

  Future<void> _removeDuplicates({PresentationRowType type = PresentationRowType.all, bool notify = true}) async {
    final uniqueRows = <String, AssignEntryRow>{};
    final duplicateRows = <AssignEntryRow>{};
    final targetRows = getTarget(type);
    for (var row in targetRows) {
      String key;
      key = '${row.assignId}-${row.entryId}';
      if (uniqueRows.containsKey(key)) {
        duplicateRows.add(uniqueRows[key]!);
      }
      uniqueRows[key] = row; // This will keep the last occurrence
    }
    await removeRows(duplicateRows, type: type, notify: notify);
  }

  AssignEntryRow newRow({
    required BuildContext? context,
    required int existMaxOrderNumOffset,
    required int assignId,
    required int entryId,
    int? dateMillis,
    int? orderNum = 1,
    bool isActive = true,
    AssignEntryRowsType type = AssignEntryRowsType.all,
  }) {
    String labelName = '';
    if (context != null) {
      final source = context.read<CollectionSource>();
      final curEntry = source.allEntries.firstWhereOrNull((e) => e.id == entryId);
      if (curEntry != null) {
        labelName = curEntry.bestTitle!;
      }
    }
    dateMillis = DateTime.now().millisecondsSinceEpoch;
    return AssignEntryRow(
      id: localMediaDb.nextId,
      assignId: assignId,
      entryId: entryId,
      dateMillis: dateMillis,
      isActive: isActive,
      labelName: labelName,
      orderNum: orderNum ?? 1,
    );
  }

  void removeInvalidEntries(BuildContext context,
      {PresentationRowType type = PresentationRowType.all, bool notify = true}) {
    final source = context.read<CollectionSource>(); // Assuming context is accessible or pass source explicitly
    final targetRows = getTarget(type);
    final invalidRows =
        targetRows.where((row) => source.allEntries.firstWhereOrNull((e) => e.id == row.entryId) == null).toSet();

    if (invalidRows.isNotEmpty) {
      removeRows(invalidRows, type: type, notify: notify);
      localMediaDb.removeAssignEntries(invalidRows); // Ensure the database is updated
    }
  }

  Future<void> addAvesEntry(AvesEntry entry, int assignId,
      {PresentationRowType type = PresentationRowType.all, bool notify = true}) async {
    final newEntryRow = newRow(existMaxOrderNumOffset: 1, assignId: assignId, entryId: entry.id, context: null);
    await add({newEntryRow}, type: type, notify: notify);
  }
}

@immutable
class AssignEntryRow extends PresentRow<AssignEntryRow> {
  final int assignId;
  final int entryId;
  final int dateMillis;
  final int orderNum;

  @override
  List<Object?> get props => [
        id,
        assignId,
        entryId,
        dateMillis,
        isActive,
      ];

  const AssignEntryRow({
    required super.id,
    required super.labelName,
    required this.assignId,
    required this.entryId,
    required this.dateMillis,
    required this.orderNum,
    required super.isActive,
  });

  factory AssignEntryRow.fromMap(Map map) {
    return AssignEntryRow(
      id: map['id'] as int,
      assignId: map['assignId'] as int,
      entryId: map['entryId'] as int,
      dateMillis: map['dateMillis'] as int,
      isActive: (map['isActive'] as int? ?? 0) != 0,
      orderNum: map['orderNum'] as int,
      labelName: map['labelName'] as String,
    );
  }

  String toJson() => jsonEncode(toMap());

  @override
  Map<String, dynamic> toMap() => {
        'id': id,
        'assignId': assignId,
        'entryId': entryId,
        'dateMillis': dateMillis,
        'orderNum': orderNum,
        'isActive': isActive ? 1 : 0,
        'labelName': labelName,
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

  @override
  AssignEntryRow copyWith({
    int? id,
    int? assignId,
    int? entryId,
    int? dateMillis,
    int? orderNum,
    bool? isActive,
    String? labelName,
  }) {
    return AssignEntryRow(
      id: id ?? this.id,
      assignId: assignId ?? this.assignId,
      entryId: entryId ?? this.entryId,
      dateMillis: dateMillis ?? this.dateMillis,
      isActive: isActive ?? this.isActive,
      labelName: labelName ?? this.labelName,
      orderNum: orderNum ?? this.orderNum,
    );
  }
}
