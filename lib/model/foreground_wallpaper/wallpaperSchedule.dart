import 'dart:async';
import 'package:aves/services/common/services.dart';
import 'package:aves/utils/collection_utils.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

enum WallpaperUpdateType { home, lock, both, widget }

final WallpaperSchedules wallpaperSchedules = WallpaperSchedules._private();

class WallpaperSchedules with ChangeNotifier {
  Set<WallpaperScheduleRow> _rows = {};

//
  WallpaperSchedules._private();

  Future<void> init() async {
    _rows = await metadataDb.loadAllWallpaperSchedules();
    await _removeDuplicates();
  }

  int get count => _rows.length;

  Set<WallpaperScheduleRow> get all {
    _removeDuplicates();
    return Set.unmodifiable(_rows);
  }

  Future<void> add(Set<WallpaperScheduleRow> newRows) async {
    await metadataDb.addWallpaperSchedules(newRows);
    _rows.addAll(newRows);
    await _removeDuplicates();
    notifyListeners();
  }

  Future<void> setRows(Set<WallpaperScheduleRow> newRows) async {
    await removeEntries(newRows);
    for (var row in newRows) {
      await set(
        id: row.id,
        scheduleNum: row.scheduleNum,
        aliasName: row.aliasName,
        privacyGuardLevelId: row.privacyGuardLevelId,
        filterSetId: row.filterSetId,
        updateType: row.updateType,
        widgetId: row.widgetId,
        intervalTime: row.intervalTime,
        isActive: row.isActive,
      );
    }
    notifyListeners();
  }

  Future<void> set({
    required id,
    required scheduleNum,
    required aliasName,
    required privacyGuardLevelId,
    required filterSetId,
    required updateType,
    required widgetId,
    required intervalTime,
    required isActive,
  }) async {
    // Remove existing entries with the same privacyGuardLevelId and updateType
    // erase contextual properties from filters before saving them
    final oldRows = _rows.where((row) => row.id == id).toSet();
    _rows.removeAll(oldRows);
    await metadataDb.removeWallpaperSchedules(oldRows);
    final row = WallpaperScheduleRow(
      id: id,
      scheduleNum: scheduleNum,
      filterSetId: filterSetId,
      aliasName: aliasName,
      privacyGuardLevelId: privacyGuardLevelId,
      updateType: updateType,
      widgetId: widgetId,
      intervalTime: intervalTime,
      isActive: isActive,
    );
    debugPrint('$runtimeType set  WallpaperScheduleRow  $row');
    _rows.add(row);
    await metadataDb.addWallpaperSchedules({row});
    await _removeDuplicates();
    notifyListeners();
  }

  Future<void> removeEntries(Set<WallpaperScheduleRow> rows) => removeIds(rows.map((row) => row.id).toSet());

  Future<void> removeNumbers(Set<int> rowNums) async {
    final removedRows = _rows.where((row) => rowNums.contains(row.scheduleNum)).toSet();
    await metadataDb.removeWallpaperSchedules(removedRows);
    removedRows.forEach(_rows.remove);
    notifyListeners();
  }

  Future<void> removeIds(Set<int> rowIds) async {
    final removedRows = _rows.where((row) => rowIds.contains(row.id)).toSet();
    await metadataDb.removeWallpaperSchedules(removedRows);
    removedRows.forEach(_rows.remove);
    notifyListeners();
  }

  Future<void> _removeDuplicates() async {
    final uniqueRows = <String, WallpaperScheduleRow>{};
    final duplicateRows = <WallpaperScheduleRow>{};
    for (var row in _rows) {
      String key;
      if (row.updateType == WallpaperUpdateType.widget) {
        key = '${row.privacyGuardLevelId}-${row.updateType}-${row.widgetId}';
      } else {
        key = '${row.privacyGuardLevelId}-${row.updateType}';
      }
      if (uniqueRows.containsKey(key)) {
        duplicateRows.add(uniqueRows[key]!);
      }
      uniqueRows[key] = row; // This will keep the last occurrence
    }
    _rows = uniqueRows.values.toSet();
    if (duplicateRows.isNotEmpty) {
      await metadataDb.removeWallpaperSchedules(duplicateRows);
    }
  }

  Future<void> clear() async {
    await metadataDb.clearWallpaperSchedules();
    _rows.clear();
    notifyListeners();
  }
}

@immutable
class WallpaperScheduleRow extends Equatable implements Comparable<WallpaperScheduleRow> {
  final int id;
  final int scheduleNum;
  final String aliasName;
  final int privacyGuardLevelId;
  final int filterSetId;
  final WallpaperUpdateType updateType;
  final int widgetId;
  final int intervalTime;
  final bool isActive;

  @override
  List<Object?> get props => [
        id,
        scheduleNum,
        aliasName,
        privacyGuardLevelId,
        filterSetId,
        updateType,
        widgetId,
        intervalTime,
        isActive,
      ];

  const WallpaperScheduleRow({
    required this.id,
    required this.scheduleNum,
    required this.aliasName,
    required this.privacyGuardLevelId,
    required this.filterSetId,
    required this.updateType,
    required this.widgetId,
    required this.intervalTime,
    required this.isActive,
  });

  static WallpaperScheduleRow fromMap(Map map) {
    return WallpaperScheduleRow(
      id: map['id'] as int,
      scheduleNum: map['scheduleNum'] as int,
      aliasName: map['aliasName'] as String,
      privacyGuardLevelId: map['privacyGuardLevelId'] as int,
      filterSetId: map['filterSetId'] as int,
      updateType: WallpaperUpdateType.values.safeByName(map['updateType'] as String, WallpaperUpdateType.home),
      widgetId: map['widgetId'] as int,
      intervalTime: map['intervalTime'] as int,
      isActive: (map['isActive'] as int? ?? 0) != 0,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'scheduleNum': scheduleNum,
        'aliasName': aliasName,
        'privacyGuardLevelId': privacyGuardLevelId,
        'filterSetId': filterSetId,
        'updateType': updateType.name,
        'widgetId': widgetId,
        'intervalTime': intervalTime,
        'isActive': isActive ? 1 : 0,
      };

  @override
  int compareTo(WallpaperScheduleRow other) {
    // Sorting logic
    if (isActive != other.isActive) {
      // Sort by isActive, true (1) comes before false (0)
      return isActive ? -1 : 1;
    }

    // If isActive is the same, sort by scheduleNum
    final scheduleNumComparison = scheduleNum.compareTo(other.scheduleNum);
    if (scheduleNumComparison != 0) {
      return scheduleNumComparison;
    }
    // If scheduleNum is the same, sort by id
    return id.compareTo(other.id);
  }
}
