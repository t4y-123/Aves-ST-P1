import 'dart:async';


import 'package:aves/model/foreground_wallpaper/filterSet.dart';
import 'package:aves/model/foreground_wallpaper/privacyGuardLevel.dart';
import 'package:aves/services/common/services.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

import '../filters/aspect_ratio.dart';
import '../filters/mime.dart';

final WallpaperSchedules wallpaperSchedules = WallpaperSchedules._private();

class WallpaperSchedules with ChangeNotifier {
  Set<WallpaperScheduleRow> _rows = {};
//
  WallpaperSchedules._private();

  Future<void> init() async {
    _rows = await metadataDb.loadAllWallpaperSchedules();
  }

  int get count => _rows.length;

  Set<WallpaperScheduleRow> get all => Set.unmodifiable(_rows);

  Future<void> add(Set<WallpaperScheduleRow> newRows) async {
    await metadataDb.addWallpaperSchedules(newRows);
    _rows.addAll(newRows);
    notifyListeners();
  }

  Future<void> setRows(Set<WallpaperScheduleRow> newRows) async {

    await removeEntries(newRows);
    for (var row in newRows) {
      await set(
        id: row.id,
        scheduleNum: row.scheduleNum,
        scheduleName: row.scheduleName,
        isActive: row.isActive,
      );
    }
    notifyListeners();
  }

  Future<void> set({
    required id,
    required scheduleNum,
    required scheduleName,
    required isActive,
  }) async {
    // erase contextual properties from filters before saving them
    final oldRows = _rows.where((row) => row.id == id).toSet();
    _rows.removeAll(oldRows);
    await metadataDb.removeWallpaperSchedules(oldRows);
    final row = WallpaperScheduleRow(
      id: id,
      scheduleNum: scheduleNum,
      scheduleName: scheduleName,
      isActive: isActive,
    );
    _rows.add(row);
    await metadataDb.addWallpaperSchedules({row});
    notifyListeners();
  }

  Future<void> removeEntries(Set<WallpaperScheduleRow> rows) =>
      removeIds(rows.map((row) => row.id).toSet());

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

  Future<void> clear() async {
    await metadataDb.clearWallpaperSchedules();
    _rows.clear();
    notifyListeners();
  }

  //TODO: t4y: import/export
}

@immutable
class WallpaperScheduleRow extends Equatable implements Comparable<WallpaperScheduleRow>  {
  final int id;
  final int scheduleNum;
  final String scheduleName;
  final bool isActive;

  @override
  List<Object?> get props => [
        id,
        scheduleNum,
        scheduleName,
        isActive,
      ];

  const WallpaperScheduleRow({
    required this.id,
    required this.scheduleNum,
    required this.scheduleName,
    required this.isActive,
  });

  static WallpaperScheduleRow fromMap(Map map) {
    return WallpaperScheduleRow(
      id: map['id'] as int,
      scheduleNum: map['scheduleNum'] as int,
      scheduleName: map['scheduleName'] as String,
      isActive: (map['isActive'] as int? ?? 0) != 0,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'scheduleNum': scheduleNum,
        'scheduleName': scheduleName,
        'isActive' : isActive ? 1 : 0,
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

// Schedules vs Details, 1:n.
final WallpaperScheduleDetails wallpaperScheduleDetails = WallpaperScheduleDetails._private();

class WallpaperScheduleDetails with ChangeNotifier {
  Set<WallpaperScheduleDetailRow> _rows = {};

  WallpaperScheduleDetails._private();

  Future<void> init() async {
    _rows = await metadataDb.loadAllWallpaperScheduleDetails();
  }

  int get count => _rows.length;

  Set<WallpaperScheduleDetailRow> get all => Set.unmodifiable(_rows);

  Future<void> add(Set<WallpaperScheduleDetailRow> newRows) async {
    await metadataDb.addWallpaperScheduleDetails(newRows);
    _rows.addAll(newRows);
    notifyListeners();
  }

  Future<void> setRows(Set<WallpaperScheduleDetailRow> newRows) async {

    await removeEntries(newRows);
    for (var row in newRows) {
      await set(
        wallpaperScheduleDetailId: row.wallpaperScheduleDetailId,
        wallpaperScheduleId: row.wallpaperScheduleId,
        filterSetId: row.filterSetId,
        privacyGuardLevelId: row.privacyGuardLevelId,
        updateType: row.updateType,
        widgetId: row.widgetId,
        intervalTime: row.intervalTime,
      );
    }
    notifyListeners();
  }

  Future<void> set({
    required wallpaperScheduleDetailId,
    required wallpaperScheduleId,
    required filterSetId,
    required privacyGuardLevelId,
    required updateType,
    required widgetId,
    required intervalTime,
  }) async {
    // erase contextual properties from filters before saving them
    final oldRows = _rows.where((row) => row.wallpaperScheduleDetailId == wallpaperScheduleDetailId).toSet();
    _rows.removeAll(oldRows);
    await metadataDb.removeWallpaperScheduleDetails(oldRows);
    final row = WallpaperScheduleDetailRow(
      wallpaperScheduleDetailId: wallpaperScheduleDetailId,
      wallpaperScheduleId: wallpaperScheduleId,
      filterSetId: filterSetId,
      privacyGuardLevelId: privacyGuardLevelId,
      updateType: updateType,
      widgetId: widgetId,
      intervalTime: intervalTime,
    );
    _rows.add(row);
    await metadataDb.addWallpaperScheduleDetails({row});
    notifyListeners();
  }

  Future<void> removeEntries(Set<WallpaperScheduleDetailRow> rows) =>
      removeIds(rows.map((row) => row.wallpaperScheduleDetailId).toSet());

  Future<void> removeIds(Set<int> rowIds) async {
    final removedRows = _rows.where((row) => rowIds.contains(row.wallpaperScheduleDetailId)).toSet();
    await metadataDb.removeWallpaperScheduleDetails(removedRows);
    removedRows.forEach(_rows.remove);
    notifyListeners();
  }

  Future<void> clear() async {
    await metadataDb.clearWallpaperSchedules();
    _rows.clear();
    notifyListeners();
  }

//TODO: t4y: import/export
}

@immutable
class WallpaperScheduleDetailRow extends Equatable {
  final int wallpaperScheduleDetailId;
  final int wallpaperScheduleId;
  final int filterSetId;
  final int privacyGuardLevelId;
  final String updateType;
  final String widgetId;
  final int intervalTime;

  @override
  List<Object?> get props => [
    wallpaperScheduleDetailId,
    wallpaperScheduleId,
    filterSetId,
    privacyGuardLevelId,
    updateType,
    widgetId,
    intervalTime,
  ];

  const WallpaperScheduleDetailRow({
    required this.wallpaperScheduleDetailId,
    required this.wallpaperScheduleId,
    required this.filterSetId,
    required this.privacyGuardLevelId,
    required this.updateType,
    required this.widgetId,
    required this.intervalTime,
  });

  static WallpaperScheduleDetailRow fromMap(Map map) {
    return WallpaperScheduleDetailRow(
      wallpaperScheduleDetailId:  map['id'] as int,
      wallpaperScheduleId: map['wallpaperScheduleId'] as int,
      filterSetId: map['filterSetId'] as int,
      privacyGuardLevelId: map['privacyGuardLevelId'] as int,
      updateType: map['updateType'] as String,
      widgetId: map['widgetId'] as String,
      intervalTime: map['intervalTime'] as int,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': wallpaperScheduleDetailId,
    'wallpaperScheduleId': wallpaperScheduleId,
    'filterSetId': filterSetId,
    'privacyGuardLevelId': privacyGuardLevelId,
    'updateType': updateType,
    'widgetId': widgetId,
    'intervalTime': intervalTime,
  };

}
