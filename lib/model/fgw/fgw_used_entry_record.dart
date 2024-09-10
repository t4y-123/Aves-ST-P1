import 'dart:async';

import 'package:aves/model/fgw/fgw_schedule_helper.dart';
import 'package:aves/model/fgw/guard_level.dart';
import 'package:aves/model/presentation/base_bridge_row.dart';
import 'package:aves/model/settings/settings.dart';
import 'package:aves/services/common/services.dart';
import 'package:aves/utils/collection_utils.dart';
import 'package:flutter/foundation.dart';

import '../entry/entry.dart';
import 'enum/fgw_schedule_item.dart';

final FgwUsedEntryRecord fgwUsedEntryRecord = FgwUsedEntryRecord._private();

class FgwUsedEntryRecord extends PresentationRows<FgwUsedEntryRecordRow> {
  FgwUsedEntryRecord._private();

  @override
  Future<Set<FgwUsedEntryRecordRow>> loadAllRows() async {
    return await localMediaDb.loadAllFgwUsedEntryRecord();
  }

  @override
  Future<void> addRowsToDb(Set<FgwUsedEntryRecordRow> newRows) async {
    await localMediaDb.addFgwUsedEntryRecord(newRows);
  }

  @override
  Future<void> removeRowsFromDb(Set<FgwUsedEntryRecordRow> removedRows) async {
    await localMediaDb.removeFgwUsedEntryRecord(removedRows);
  }

  @override
  Future<void> clearRowsInDb() async {
    await localMediaDb.clearFgwUsedEntryRecord();
  }

  @override
  FgwUsedEntryRecordRow importFromMap(Map<String, dynamic> attributes) {
    return FgwUsedEntryRecordRow.fromMap(attributes);
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
  Future<void> add(Set<FgwUsedEntryRecordRow> newRows,
      {PresentationRowType type = PresentationRowType.all, bool notify = true}) async {
    await super.add(newRows, type: type, notify: notify);
    await _removeOldestEntries();
  }

  Future<void> _removeOldestEntries({PresentationRowType type = PresentationRowType.all}) async {
    final Map<String, List<FgwUsedEntryRecordRow>> groupedRows = {};
    final targetSet = getTarget(type);
    if (targetSet.isNotEmpty) {
      for (var row in targetSet) {
        String key = '${row.guardLevelId}_${row.updateType}_${row.widgetId}';
        groupedRows.putIfAbsent(key, () => []).add(row);
      }
      debugPrint('$runtimeType _removeOldestEntries groupedRows ${groupedRows.values}');
      for (var group in groupedRows.values) {
        var entryIds = <int>{};
        group.removeWhere((row) => !entryIds.add(row.entryId));

        if (group.length > settings.maxFgwUsedEntryRecord) {
          group.sort((a, b) => a.dateMillis.compareTo(b.dateMillis));
          final toRemoveRows = group.sublist(0, group.length - settings.maxFgwUsedEntryRecord).toSet();
          debugPrint('$runtimeType _removeOldestEntries toRemoveRows $toRemoveRows');
          await removeRows(group.sublist(0, group.length - settings.maxFgwUsedEntryRecord).toSet(), type: type);
        }
      }
    }
  }

  Future<FgwUsedEntryRecordRow> newRow(
    int fgwGuardLevelId,
    WallpaperUpdateType updateType,
    int entryId, {
    int widgetId = 0,
  }) async {
    final int dateMillis = DateTime.now().millisecondsSinceEpoch;
    final int id = dateMillis + localMediaDb.nextId;
    return FgwUsedEntryRecordRow(
      id: id,
      labelName: 'null',
      isActive: true,
      guardLevelId: fgwGuardLevelId,
      updateType: updateType,
      widgetId: widgetId,
      entryId: entryId,
      dateMillis: dateMillis,
    );
  }

  Future<void> addAvesEntry(AvesEntry entry, WallpaperUpdateType updateType,
      {int widgetId = 0, FgwGuardLevelRow? curLevel}) async {
    curLevel ??= await fgwScheduleHelper.getCurGuardLevel();
    final newRecord = await newRow(curLevel.id, updateType, entry.id, widgetId: widgetId);
    await add({newRecord});
  }
}

@immutable
class FgwUsedEntryRecordRow extends PresentRow<FgwUsedEntryRecordRow> {
  final int guardLevelId;
  final WallpaperUpdateType updateType;
  final int widgetId;
  final int entryId;
  final int dateMillis; // dateMillis = DateTime.now().millisecondsSinceEpoch

  @override
  List<Object?> get props => [
        id,
        guardLevelId,
        updateType,
        widgetId,
        entryId,
        dateMillis,
      ];

  const FgwUsedEntryRecordRow({
    required super.id,
    required super.labelName,
    required super.isActive,
    required this.guardLevelId,
    required this.updateType,
    required this.widgetId,
    required this.entryId,
    required this.dateMillis,
  });

  factory FgwUsedEntryRecordRow.fromMap(Map<String, dynamic> map) {
    return FgwUsedEntryRecordRow(
      id: map['id'] as int,
      guardLevelId: map['fgwGuardLevelId'] as int,
      updateType: WallpaperUpdateType.values.safeByName(map['updateType'] as String, WallpaperUpdateType.home),
      widgetId: map['widgetId'] as int,
      entryId: map['entryId'] as int,
      dateMillis: map['dateMillis'] as int,
      labelName: 'null',
      isActive: true,
    );
  }

  @override
  Map<String, dynamic> toMap() => {
        'id': id,
        'fgwGuardLevelId': guardLevelId,
        'updateType': updateType.name,
        'widgetId': widgetId,
        'entryId': entryId,
        'dateMillis': dateMillis,
      };

  @override
  FgwUsedEntryRecordRow copyWith({
    int? id,
    String? labelName,
    bool? isActive,
    int? fgwGuardLevelId,
    WallpaperUpdateType? updateType,
    int? widgetId,
    int? entryId,
    int? dateMillis,
  }) {
    return FgwUsedEntryRecordRow(
      id: id ?? this.id,
      labelName: labelName ?? this.labelName,
      isActive: isActive ?? this.isActive,
      guardLevelId: fgwGuardLevelId ?? this.guardLevelId,
      updateType: updateType ?? this.updateType,
      widgetId: widgetId ?? this.widgetId,
      entryId: entryId ?? this.entryId,
      dateMillis: dateMillis ?? this.dateMillis,
    );
  }

  @override
  int compareTo(FgwUsedEntryRecordRow other) {
    // Sort primarily by fgwGuardLevelId
    int result = guardLevelId.compareTo(other.guardLevelId);
    if (result != 0) return result;

    // Then by dateMillis
    result = dateMillis.compareTo(other.dateMillis);
    if (result != 0) return result;

    // Then by entryId
    result = entryId.compareTo(other.entryId);
    if (result != 0) return result;

    // Finally by id
    return id.compareTo(other.id);
  }
}
