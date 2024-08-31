import 'dart:async';

import 'package:aves/model/fgw/fgw_schedule_helper.dart';
import 'package:aves/model/fgw/guard_level.dart';
import 'package:aves/model/settings/settings.dart';
import 'package:aves/services/common/services.dart';
import 'package:aves/utils/collection_utils.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

import '../entry/entry.dart';
import 'enum/fgw_schedule_item.dart';

final FgwUsedEntryRecord fgwUsedEntryRecord = FgwUsedEntryRecord._private();

class FgwUsedEntryRecord with ChangeNotifier {
  Set<FgwUsedEntryRecordRow> _rows = {};

  FgwUsedEntryRecord._private();

  Future<void> init() async {
    _rows = await metadataDb.loadAllFgwUsedEntryRecord();
    await _removeOldestEntries();
  }

  int get count => _rows.length;

  Set<FgwUsedEntryRecordRow> get all {
    _removeOldestEntries();
    return Set.unmodifiable(_rows);
  }

  Future<void> add(Set<FgwUsedEntryRecordRow> newRows) async {
    await metadataDb.addFgwUsedEntryRecord(newRows);
    _rows.addAll(newRows);
    await _removeOldestEntries();
    notifyListeners();
  }

  Future<void> setRows(Set<FgwUsedEntryRecordRow> newRows) async {
    await removeRows(newRows);
    for (var row in newRows) {
      await set(
        id: row.id,
        privacyGuardLevelId: row.privacyGuardLevelId,
        updateType: row.updateType,
        widgetId: row.widgetId,
        entryId: row.entryId,
        dateMillis: row.dateMillis,
      );
    }
    notifyListeners();
  }

  Future<void> set(
      {required int id,
      required int privacyGuardLevelId,
      required WallpaperUpdateType updateType,
      required int widgetId,
      required int entryId,
      required int dateMillis}) async {
    final oldRows = _rows.where((row) => row.id == id).toSet();
    _rows.removeAll(oldRows);
    await metadataDb.removeFgwUsedEntryRecord(oldRows);
    final row = FgwUsedEntryRecordRow(
      id: id,
      privacyGuardLevelId: privacyGuardLevelId,
      updateType: updateType,
      widgetId: widgetId,
      entryId: entryId,
      dateMillis: dateMillis,
    );
    _rows.add(row);
    await _removeOldestEntries();
    await metadataDb.addFgwUsedEntryRecord({row});
    notifyListeners();
  }

  Future<void> removeRows(Set<FgwUsedEntryRecordRow> rows) => removeIds(rows.map((row) => row.id).toSet());

  Future<void> removeEntries(Set<AvesEntry> entries) async {
    final entryIds = entries.map((entry) => entry.id).toSet();
    final todoRows = _rows.where((row) => entryIds.contains(row.entryId)).toSet();
    await removeRows(todoRows);
  }

  Future<void> removeIds(Set<int> rowIds) async {
    final removedRows = _rows.where((row) => rowIds.contains(row.id)).toSet();
    await metadataDb.removeFgwUsedEntryRecord(removedRows);
    removedRows.forEach(_rows.remove);
    notifyListeners();
  }

  Future<void> removeEntryIds(Set<int> rowIds) async {
    //debugPrint('$runtimeType removeFgwUsedEntryRecord ${_rows.length} removeEntryIds entries:\n[$_rows]\n[$rowIds]');
    final removedRows = _rows.where((row) => rowIds.contains(row.entryId)).toSet();
    await metadataDb.removeFgwUsedEntryRecord(removedRows);
    removedRows.forEach(_rows.remove);
    notifyListeners();
  }

  Future<void> removeWidgetIds(Set<int> rowWidgetIds) async {
    final removedRows = _rows.where((row) => rowWidgetIds.contains(row.widgetId)).toSet();
    await metadataDb.removeFgwUsedEntryRecord(removedRows);
    removedRows.forEach(_rows.remove);
    notifyListeners();
  }

  Future<void> _removeOldestEntries() async {
    //debugPrint('_removeOldestEntries start');
    final Map<String, List<FgwUsedEntryRecordRow>> groupedRows = {};
    if (_rows.isNotEmpty) {
      // Group rows by key excluding entryId
      for (var row in _rows) {
        String key = '${row.privacyGuardLevelId}_${row.updateType}_${row.widgetId}';
        if (!groupedRows.containsKey(key)) {
          groupedRows[key] = [];
        }
        groupedRows[key]!.add(row);
      }

      // Remove keys with the same entryId first
      for (var rows in groupedRows.values) {
        var entryIds = <int>{};
        rows.removeWhere((row) {
          if (entryIds.contains(row.entryId)) {
            return true;
          } else {
            entryIds.add(row.entryId);
            return false;
          }
        });
      }

      // Remove oldest entries if group length exceeds max limit
      for (var key in groupedRows.keys) {
        var rows = groupedRows[key]!;
        if (rows.length > settings.maxFgwUsedEntryRecord) {
          // Sort rows by dateMillis in ascending order using direct comparison
          rows.sort((a, b) {
            if (a.dateMillis < b.dateMillis) return -1;
            if (a.dateMillis > b.dateMillis) return 1;
            return 0;
          });
          final rowsToRemove = rows.sublist(0, rows.length - settings.maxFgwUsedEntryRecord);
          await metadataDb.removeFgwUsedEntryRecord(rowsToRemove.toSet());
          _rows.removeAll(rowsToRemove);
        }
      }
    } else {
      debugPrint('_removeOldestEntries _rows is empty');
    }
  }

  Future<void> clear() async {
    await metadataDb.clearFgwUsedEntryRecord();
    _rows.clear();
    notifyListeners();
  }

  Future<FgwUsedEntryRecordRow> newRow(int privacyGuardLevelId, WallpaperUpdateType updateType, int entryId,
      {int widgetId = 0}) async {
    final int id = DateTime.now().millisecondsSinceEpoch;
    final int dateMillis = DateTime.now().millisecondsSinceEpoch;

    return FgwUsedEntryRecordRow(
      id: id,
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
    final FgwUsedEntryRecordRow newRecord = await newRow(
      curLevel!.id,
      updateType,
      entry.id,
    );
    await add({newRecord});
  }
}

@immutable
class FgwUsedEntryRecordRow extends Equatable implements Comparable<FgwUsedEntryRecordRow> {
  final int id;
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
    required this.id,
    required this.privacyGuardLevelId,
    required this.updateType,
    required this.widgetId,
    required this.entryId,
    required this.dateMillis,
  });

  static FgwUsedEntryRecordRow fromMap(Map map) {
    return FgwUsedEntryRecordRow(
      id: map['id'] as int,
      privacyGuardLevelId: map['privacyGuardLevelId'] as int,
      updateType: WallpaperUpdateType.values.safeByName(map['updateType'] as String, WallpaperUpdateType.home),
      widgetId: map['widgetId'] as int,
      entryId: map['entryId'] as int,
      dateMillis: map['dateMillis'] as int,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'privacyGuardLevelId': privacyGuardLevelId,
        'updateType': updateType.name,
        'widgetId': widgetId,
        'entryId': entryId,
        'dateMillis': dateMillis,
      };

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
