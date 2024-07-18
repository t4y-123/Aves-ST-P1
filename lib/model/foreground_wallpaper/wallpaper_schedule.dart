import 'dart:async';
import 'package:aves/model/foreground_wallpaper/privacy_guard_level.dart';
import 'package:aves/services/common/services.dart';
import 'package:aves/utils/collection_utils.dart';
import 'package:collection/collection.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

import '../settings/settings.dart';
import 'enum/fgw_schedule_item.dart';
import 'filtersSet.dart';

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
        scheduleNum: row.orderNum,
        lableName: row.labelName,
        privacyGuardLevelId: row.privacyGuardLevelId,
        filtersSetId: row.filtersSetId,
        updateType: row.updateType,
        displayType: row.displayType,
        widgetId: row.widgetId,
        intervalTime: row.interval,
        isActive: row.isActive,
      );
    }
    notifyListeners();
  }

  Future<void> set({
    required id,
    required scheduleNum,
    required lableName,
    required privacyGuardLevelId,
    required filtersSetId,
    required updateType,
    required widgetId,
    required displayType,
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
      orderNum: scheduleNum,
      filtersSetId: id,
      labelName: lableName,
      privacyGuardLevelId: privacyGuardLevelId,
      updateType: updateType,
      widgetId: widgetId,
      displayType:displayType,
      interval: intervalTime,
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
    final removedRows = _rows.where((row) => rowNums.contains(row.orderNum)).toSet();
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

  WallpaperScheduleRow newRow({
      required int existMaxOrderNumOffset,
      required int privacyGuardLevelId,
      required int filtersSetId,
      required WallpaperUpdateType updateType,
      FgwDisplayedType? displayType,
      String? labelName,
      int? widgetId,
      int? interval,
      bool isActive = true,
      int? id}) {
    var thisGuardLevel = privacyGuardLevels.all.firstWhereOrNull((e) => e.privacyGuardLevelID == privacyGuardLevelId);
    thisGuardLevel ??= privacyGuardLevels.all.first;

    var thisFiltersSet = filtersSets.all.firstWhereOrNull((e) => e.id == filtersSetId);
    thisFiltersSet ??= filtersSets.all.first;

    final relevantItems = isActive ? all.where((item) => item.isActive).toList() : all.toList();
    final maxScheduleNum =
        relevantItems.isEmpty ? 0 : relevantItems.map((item) => item.orderNum).reduce((a, b) => a > b ? a : b);

    return WallpaperScheduleRow(
      id: id ?? metadataDb.nextId,
      orderNum: maxScheduleNum + existMaxOrderNumOffset,
      labelName: labelName ?? 'L${thisGuardLevel.guardLevel}-ID_${thisGuardLevel.privacyGuardLevelID}-${updateType.name}',
      privacyGuardLevelId: privacyGuardLevelId,
      filtersSetId: thisFiltersSet.id,
      updateType: updateType,
      widgetId: widgetId ?? 0,
      displayType: displayType ?? settings.fgwDisplayType,
      interval: interval ?? settings.defaultNewUpdateInterval,
      isActive: isActive,
    );
  }

  // import/export
  Map<String, Map<String, dynamic>>? export() {
    final rows = wallpaperSchedules.all;
    final jsonMap = Map.fromEntries(rows.map((row) {
      return MapEntry(
        row.id.toString(),
        row.toMap(),
      );
    }));
    return jsonMap.isNotEmpty ? jsonMap : null;
  }

  Future<void> import (dynamic jsonMap) async {
    if (jsonMap is! Map) {
      debugPrint('failed to import wallpaper schedules for jsonMap=$jsonMap');
      return;
    }

    final foundRows = <WallpaperScheduleRow>{};
    jsonMap.forEach((id, attributes) {
      if (id is String && attributes is Map) {
        try {
          final row = WallpaperScheduleRow.fromMap(attributes);
          foundRows.add(row);
        } catch (e) {
          debugPrint('failed to import wallpaper schedule for id=$id, attributes=$attributes, error=$e');
        }
      } else {
        debugPrint('failed to import wallpaper schedule for id=$id, attributes=${attributes.runtimeType}');
      }
    });

    if (foundRows.isNotEmpty) {
      await wallpaperSchedules.clear();
      await wallpaperSchedules.add(foundRows);
    }
  }
}

@immutable
class WallpaperScheduleRow extends Equatable implements Comparable<WallpaperScheduleRow> {
  final int id;
  final int orderNum;
  final String labelName;
  final int privacyGuardLevelId;
  final int filtersSetId;
  final WallpaperUpdateType updateType;
  final int widgetId;
  final FgwDisplayedType displayType;
  final int interval; // in seconds
  final bool isActive;

  @override
  List<Object?> get props => [
        id,
        orderNum,
        labelName,
        privacyGuardLevelId,
        filtersSetId,
        updateType,
        widgetId,
        displayType,
        interval,
        isActive,
      ];

  const WallpaperScheduleRow({
    required this.id,
    required this.orderNum,
    required this.labelName,
    required this.privacyGuardLevelId,
    required this.filtersSetId,
    required this.updateType,
    required this.widgetId,
    required this.displayType,
    required this.interval,
    required this.isActive,
  });

  static WallpaperScheduleRow fromMap(Map map) {
    final defaultDisplayType = FgwDisplayedType.values.safeByName(map['displayType'] as String,settings.fgwDisplayType);
    debugPrint('WallpaperScheduleRow defaultDisplayType $defaultDisplayType fromMap:\n  $map.');
    return WallpaperScheduleRow(
      id: map['id'] as int,
      orderNum: map['orderNum'] as int,
      labelName: map['labelName'] as String,
      privacyGuardLevelId: map['privacyGuardLevelId'] as int,
      filtersSetId: map['filtersSetId'] as int,
      updateType: WallpaperUpdateType.values.safeByName(map['updateType'] as String, WallpaperUpdateType.home),
      widgetId: map['widgetId'] as int,
      displayType: defaultDisplayType,
      interval: map['interval'] as int,
      isActive: (map['isActive'] as int? ?? 0) != 0,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'orderNum': orderNum,
        'labelName': labelName,
        'privacyGuardLevelId': privacyGuardLevelId,
        'filtersSetId': filtersSetId,
        'updateType': updateType.name,
        'widgetId': widgetId,
        'displayType': displayType.name,
        'interval': interval,
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
    final scheduleNumComparison = orderNum.compareTo(other.orderNum);
    if (scheduleNumComparison != 0) {
      return scheduleNumComparison;
    }
    // If scheduleNum is the same, sort by id
    return id.compareTo(other.id);
  }
}
