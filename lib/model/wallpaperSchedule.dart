import 'dart:async';


import 'package:aves/model/filterSet.dart';
import 'package:aves/model/privacyGuardLevel.dart';
import 'package:aves/services/common/services.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

import 'filters/aspect_ratio.dart';
import 'filters/mime.dart';

final WallpaperSchedules wallpaperSchedules = WallpaperSchedules._private();

class WallpaperSchedules with ChangeNotifier {
  Set<WallpaperScheduleRow> _rows = {};
//
  WallpaperSchedules._private();

  Future<void> init() async {
    _rows = await metadataDb.loadAllWallpaperSchedules();
  }

  Future<void> initWallpaperSchedules() async {
    // Initialize wallpaperSchedules and wallpaperScheduleDetails
    final currentWallpaperSchedules = await metadataDb.loadAllWallpaperSchedules();
    if (currentWallpaperSchedules.isEmpty) {
      await wallpaperScheduleDetails.init();

      // init Guard Levels first.
      final initialPrivacyGuardLevels = {
        const PrivacyGuardLevelRow(
          privacyGuardLevelID: 1,
          guardLevel: 1,
          aliasName: 'Exposure',
          color: Color(0xFFFF0000), // Red
          isActive: true,
        ),
        const PrivacyGuardLevelRow(
          privacyGuardLevelID: 2,
          guardLevel: 2,
          aliasName: 'Moderate',
          color: Color(0xFF8D4FF8), // Purple
          isActive: true,
        ),
        const PrivacyGuardLevelRow(
          privacyGuardLevelID: 3,
          guardLevel: 3,
          aliasName: 'Safe',
          color: Color(0xFF7AB7EF), // Blue
          isActive: true,
        ),
      };
      await privacyGuardLevels.initializePrivacyGuardLevels(initialPrivacyGuardLevels);

      // initiate FilterSet secondly.
      final initialFilterSets = {
        FilterSetRow(
          filterSetId: 1,
          filterSetNum: 1,
          aliasName: 'Home: Exposure',
          filters: {AspectRatioFilter.portrait, MimeFilter.image},
          isActive: true,
        ),
        FilterSetRow(
          filterSetId: 2,
          filterSetNum: 2,
          aliasName: 'Home: Moderate',
          filters: {AspectRatioFilter.portrait, MimeFilter.image},
          isActive: true,
        ),
        FilterSetRow(
          filterSetId: 3,
          filterSetNum: 3,
          aliasName: 'Lock: Moderate & Exposure',
          filters: {AspectRatioFilter.portrait, MimeFilter.image},
          isActive: true,
        ),
        FilterSetRow(
          filterSetId: 4,
          filterSetNum: 4,
          aliasName: 'Home: Safe',
          filters: {AspectRatioFilter.portrait, MimeFilter.image},
          isActive: true,
        ),
        FilterSetRow(
          filterSetId: 5,
          filterSetNum: 5,
          aliasName: 'Lock: Safe',
          filters: {AspectRatioFilter.portrait, MimeFilter.image},
          isActive: true,
        ),
      };
      await filterSet.initializeFilterSets(initialFilterSets);

      // Third, make schedule.
      const int defaulInterval = 5; // seconds.
      //Schedule data

      final scheduleData = [
        const WallpaperScheduleRow(
          id: 1,
          scheduleNum: 1,
          scheduleName: 'Home: Exposure',
          isActive: true,
        ),
        const WallpaperScheduleRow(
          id: 2,
          scheduleNum: 2,
          scheduleName: 'Home: Moderate',
          isActive: true,
        ),
        const WallpaperScheduleRow(
          id: 3,
          scheduleNum: 3,
          scheduleName: 'Lock: Exposure & Moderate',
          isActive: true,
        ),
        const WallpaperScheduleRow(
          id: 4,
          scheduleNum: 4,
          scheduleName: 'Home: Safe',
          isActive: true,
        ),
        const WallpaperScheduleRow(
          id: 5,
          scheduleNum: 5,
          scheduleName: 'Lock: Safe',
          isActive: true,
        ),
      ];
      // Details data
      final detailsData = [
        const WallpaperScheduleDetailRow(
          wallpaperScheduleDetailId: 1,
          wallpaperScheduleId: 1,
          filterSetId: 1,
          privacyGuardLevelId: 1,
          updateType: 'home',
          widgetId: '0',
          intervalTime: defaulInterval,
        ),
        const WallpaperScheduleDetailRow(
          wallpaperScheduleDetailId: 2,
          wallpaperScheduleId: 2,
          filterSetId: 2,
          privacyGuardLevelId: 2,
          updateType: 'home',
          widgetId: '0',
          intervalTime: defaulInterval,
        ),
        const WallpaperScheduleDetailRow(
          wallpaperScheduleDetailId: 3,
          wallpaperScheduleId: 3,
          filterSetId: 3,
          privacyGuardLevelId: 1,
          updateType: 'lock',
          widgetId: '0',
          intervalTime: 0,
        ),
        const WallpaperScheduleDetailRow(
          wallpaperScheduleDetailId: 4,
          wallpaperScheduleId: 3,
          filterSetId: 3,
          privacyGuardLevelId: 2,
          updateType: 'lock',
          widgetId: '0',
          intervalTime: 0,
        ),
        const WallpaperScheduleDetailRow(
          wallpaperScheduleDetailId: 5,
          wallpaperScheduleId: 4,
          filterSetId: 4,
          privacyGuardLevelId: 3,
          updateType: 'home',
          widgetId: '0',
          intervalTime: defaulInterval,
        ),
        const WallpaperScheduleDetailRow(
          wallpaperScheduleDetailId: 6,
          wallpaperScheduleId: 5,
          filterSetId: 4,
          privacyGuardLevelId: 3,
          updateType: 'lock',
          widgetId: '0',
          intervalTime: 0,
        ),
      ];
      // Add schedule data to the database
      await wallpaperSchedules.add(scheduleData.toSet());
      // Add details data to the database
      await wallpaperScheduleDetails.add(detailsData.toSet());
    }
  }

  int get count => _rows.length;

  Set<WallpaperScheduleRow> get all => Set.unmodifiable(_rows);

  Future<void> add(Set<WallpaperScheduleRow> newRows) async {
    await metadataDb.addWallpaperSchedules(newRows);
    _rows.addAll(newRows);
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
class WallpaperScheduleRow extends Equatable {
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
        'isActive' : isActive,
      };
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
