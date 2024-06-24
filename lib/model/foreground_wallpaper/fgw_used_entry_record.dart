import 'dart:async';
import 'package:aves/model/foreground_wallpaper/wallpaperSchedule.dart';
import 'package:aves/model/settings/settings.dart';
import 'package:aves/services/common/services.dart';
import 'package:aves/utils/collection_utils.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';


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
    await removeEntries(newRows);
    for (var row in newRows) {
      await set(
        id: row.id,
        privacyGuardLevelId: row.privacyGuardLevelId,
        updateType: row.updateType,
        widgetId: row.widgetId,
        entryId: row.widgetId,
        dateMillis: row.widgetId,
      );
    }
    notifyListeners();
  }

  Future<void> set({
    required int id,
    required int privacyGuardLevelId,
    required WallpaperUpdateType updateType,
    required int widgetId,
    required int entryId,
    required int dateMillis
  }) async {
    // Remove existing entries with the same privacyGuardLevelId and updateType
    // erase contextual properties from filters before saving them
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
    debugPrint('$runtimeType set  FgwUsedEntryRecordRow  $row');
    _rows.add(row);
    await metadataDb.addFgwUsedEntryRecord({row});
    await _removeOldestEntries();
    notifyListeners();
  }

  Future<void> removeEntries(Set<FgwUsedEntryRecordRow> rows) =>
      removeIds(rows.map((row) => row.id).toSet());

  Future<void> removeIds(Set<int> rowIds) async {
    final removedRows = _rows.where((row) => rowIds.contains(row.id)).toSet();
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
    final Map<String, List<FgwUsedEntryRecordRow>> groupedRows = {};

    for (var row in _rows) {
      String key = '${row.privacyGuardLevelId}_${row.updateType}_${row.widgetId}_${row.entryId}';
      if (!groupedRows.containsKey(key)) {
        groupedRows[key] = [];
      }
      groupedRows[key]!.add(row);
    }

    groupedRows.forEach((key, rows) {
      if (rows.length > settings.maxFgwUsedEntryRecord) {
        // Sort rows within the group by dateMillis (assuming ascending order here)
        rows.sort((a, b) => a.dateMillis.compareTo(b.dateMillis));
        final rowsToRemove = rows.sublist(settings.maxFgwUsedEntryRecord);
        _rows.removeAll(rowsToRemove);
        metadataDb.removeFgwUsedEntryRecord(rowsToRemove.toSet());
      }
    });
  }

  int getValidUniqueId() {
    int id = 1;
    while (fgwUsedEntryRecord.all.any((item) => item.id == id)) {
      id+= 1;
    }
    return id;
  }

  Future<void> clear() async {
    await metadataDb.clearFgwUsedEntryRecord();
    _rows.clear();
    notifyListeners();
  }
}

@immutable
class FgwUsedEntryRecordRow extends Equatable
    implements Comparable<FgwUsedEntryRecordRow> {
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
      entryId: map['id'] as int,
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
