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
    return await metadataDb.loadAllFgwUsedEntryRecord();
  }

  @override
  Future<void> addRowsToDb(Set<FgwUsedEntryRecordRow> newRows) async {
    await metadataDb.addFgwUsedEntryRecord(newRows);
  }

  @override
  Future<void> removeRowsFromDb(Set<FgwUsedEntryRecordRow> removedRows) async {
    await metadataDb.removeFgwUsedEntryRecord(removedRows);
  }

  @override
  Future<void> clearRowsInDb() async {
    await metadataDb.clearFgwUsedEntryRecord();
  }

  @override
  FgwUsedEntryRecordRow importFromMap(Map<String, dynamic> attributes) {
    return FgwUsedEntryRecordRow.fromMap(attributes);
  }

  Future<void> removeEntries(Set<AvesEntry> entries) async {
    final entryIds = entries.map((entry) => entry.id).toSet();
    await removeRows(all.where((row) => entryIds.contains(row.entryId)).toSet());
  }

  Future<void> removeEntryIds(Set<int> rowIds) async {
    await removeRows(all.where((row) => rowIds.contains(row.entryId)).toSet());
  }

  Future<void> removeWidgetIds(Set<int> rowWidgetIds) async {
    await removeRows(all.where((row) => rowWidgetIds.contains(row.widgetId)).toSet());
  }

  @override
  Future<void> add(Set<FgwUsedEntryRecordRow> newRows,
      {PresentationRowType type = PresentationRowType.all, bool notify = true}) async {
    await super.add(newRows, type: type, notify: notify);
    await _removeOldestEntries();
  }

  Future<void> _removeOldestEntries() async {
    final Map<String, List<FgwUsedEntryRecordRow>> groupedRows = {};
    if (rows.isNotEmpty) {
      for (var row in rows) {
        String key = '${row.privacyGuardLevelId}_${row.updateType}_${row.widgetId}';
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
          await removeRows(group.sublist(0, group.length - settings.maxFgwUsedEntryRecord).toSet());
        }
      }
    }
  }

  Future<FgwUsedEntryRecordRow> newRow(
    int privacyGuardLevelId,
    WallpaperUpdateType updateType,
    int entryId, {
    int widgetId = 0,
  }) async {
    final int id = DateTime.now().millisecondsSinceEpoch;
    final int dateMillis = DateTime.now().millisecondsSinceEpoch;

    return FgwUsedEntryRecordRow(
      id: id,
      labelName: 'null',
      isActive: true,
      privacyGuardLevelId: privacyGuardLevelId,
      updateType: updateType,
      widgetId: widgetId,
      entryId: entryId,
      dateMillis: dateMillis,
    );
  }

  Future<void> addAvesEntry(AvesEntry entry, WallpaperUpdateType updateType,
      {int widgetId = 0, FgwGuardLevelRow? curLevel}) async {
    curLevel ??= await fgwScheduleHelper.getCurGuardLevel();
    final newRecord = await newRow(curLevel!.id, updateType, entry.id, widgetId: widgetId);
    await add({newRecord});
  }
}

@immutable
class FgwUsedEntryRecordRow extends PresentRow<FgwUsedEntryRecordRow> {
  final int privacyGuardLevelId;
  final WallpaperUpdateType updateType;
  final int widgetId;
  final int entryId;
  final int dateMillis; // dateMillis = DateTime.now().millisecondsSinceEpoch

  @override
  List<Object?> get props => [
        id,
        privacyGuardLevelId,
        updateType,
        widgetId,
        entryId,
        dateMillis,
      ];

  const FgwUsedEntryRecordRow({
    required super.id,
    required super.labelName,
    required super.isActive,
    required this.privacyGuardLevelId,
    required this.updateType,
    required this.widgetId,
    required this.entryId,
    required this.dateMillis,
  });

  factory FgwUsedEntryRecordRow.fromMap(Map<String, dynamic> map) {
    return FgwUsedEntryRecordRow(
      id: map['id'] as int,
      privacyGuardLevelId: map['privacyGuardLevelId'] as int,
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
        'privacyGuardLevelId': privacyGuardLevelId,
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
    int? privacyGuardLevelId,
    WallpaperUpdateType? updateType,
    int? widgetId,
    int? entryId,
    int? dateMillis,
  }) {
    return FgwUsedEntryRecordRow(
      id: id ?? this.id,
      labelName: labelName ?? this.labelName,
      isActive: isActive ?? this.isActive,
      privacyGuardLevelId: privacyGuardLevelId ?? this.privacyGuardLevelId,
      updateType: updateType ?? this.updateType,
      widgetId: widgetId ?? this.widgetId,
      entryId: entryId ?? this.entryId,
      dateMillis: dateMillis ?? this.dateMillis,
    );
  }

  @override
  int compareTo(FgwUsedEntryRecordRow other) {
    // Sort primarily by privacyGuardLevelId
    int result = privacyGuardLevelId.compareTo(other.privacyGuardLevelId);
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
