import 'dart:async';
import 'dart:convert';
import 'package:aves/model/foreground_wallpaper/privacy_guard_level.dart';
import 'package:aves/services/common/services.dart';
import 'package:aves/utils/collection_utils.dart';
import 'package:collection/collection.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

import '../settings/settings.dart';
import 'enum/fgw_schedule_item.dart';
import 'filtersSet.dart';

enum ScheduleRowType { all, bridgeAll }

final WallpaperSchedules wallpaperSchedules = WallpaperSchedules._private();

class WallpaperSchedules with ChangeNotifier {
  Set<WallpaperScheduleRow> _rows = {};
  Set<WallpaperScheduleRow> _bridgeRows = {};

//
  WallpaperSchedules._private();

  Future<void> init() async {
    _rows = await metadataDb.loadAllWallpaperSchedules();
    _bridgeRows = await metadataDb.loadAllWallpaperSchedules();
    await _removeDuplicates();
  }

  Future<void> refresh() async {
    _rows.clear();
    _bridgeRows.clear();
    _rows = await metadataDb.loadAllWallpaperSchedules();
    _bridgeRows = await metadataDb.loadAllWallpaperSchedules();
  }

  int get count => _rows.length;

  Set<WallpaperScheduleRow> get all {
    _removeDuplicates();
    return Set.unmodifiable(_rows);
  }

  Set<WallpaperScheduleRow> get bridgeAll {
    _removeDuplicates();
    return Set.unmodifiable(_bridgeRows);
  }

  Set<WallpaperScheduleRow> getAll(ScheduleRowType type) {
    switch (type) {
      case ScheduleRowType.bridgeAll:
        return bridgeAll;
      case ScheduleRowType.all:
      default:
        return all;
    }
  }

  Set<WallpaperScheduleRow> _getTarget(ScheduleRowType type) {
    switch (type) {
      case ScheduleRowType.bridgeAll:
        return _bridgeRows;
      case ScheduleRowType.all:
      default:
        return _rows;
    }
  }

  Future<void> add(Set<WallpaperScheduleRow> newRows, {ScheduleRowType type = ScheduleRowType.all}) async {
    final targetSet = _getTarget(type);
    if (type == ScheduleRowType.all) await metadataDb.addWallpaperSchedules(newRows);
    targetSet.addAll(newRows);
    await _removeDuplicates();
    notifyListeners();
  }

  Future<void> setRows(Set<WallpaperScheduleRow> newRows, {ScheduleRowType type = ScheduleRowType.all}) async {
    await removeEntries(newRows, type: type);
    for (var row in newRows) {
      await set(
        id: row.id,
        orderNum: row.orderNum,
        labelName: row.labelName,
        privacyGuardLevelId: row.privacyGuardLevelId,
        filtersSetId: row.filtersSetId,
        updateType: row.updateType,
        displayType: row.displayType,
        widgetId: row.widgetId,
        intervalTime: row.interval,
        isActive: row.isActive,
        type: type,
      );
    }
    notifyListeners();
  }

  Future<void> set({
    required int id,
    required int orderNum,
    required String labelName,
    required int privacyGuardLevelId,
    required int filtersSetId,
    required WallpaperUpdateType updateType,
    required int widgetId,
    required FgwDisplayedType displayType,
    required int intervalTime,
    required bool isActive,
    ScheduleRowType type = ScheduleRowType.all,
  }) async {
    final targetSet = _getTarget(type);

    final oldRows = targetSet.where((row) => row.id == id).toSet();
    targetSet.removeAll(oldRows);
    if (type == ScheduleRowType.all) await metadataDb.removeWallpaperSchedules(oldRows);
    final row = WallpaperScheduleRow(
      id: id,
      orderNum: orderNum,
      filtersSetId: filtersSetId,
      labelName: labelName,
      privacyGuardLevelId: privacyGuardLevelId,
      updateType: updateType,
      widgetId: widgetId,
      displayType: displayType,
      interval: intervalTime,
      isActive: isActive,
    );

    debugPrint('$runtimeType set WallpaperScheduleRow $row');
    targetSet.add(row);
    if (type == ScheduleRowType.all) await metadataDb.addWallpaperSchedules({row});
    await _removeDuplicates();
    notifyListeners();
  }

  Future<void> removeEntries(Set<WallpaperScheduleRow> rows, {ScheduleRowType type = ScheduleRowType.all}) async {
    await removeIds(rows.map((row) => row.id).toSet(), type: type);
  }

  Future<void> removeNumbers(Set<int> rowNums, {ScheduleRowType type = ScheduleRowType.all}) async {
    final targetSet = _getTarget(type);

    final removedRows = targetSet.where((row) => rowNums.contains(row.id)).toSet();
    if (type == ScheduleRowType.all) await metadataDb.removeWallpaperSchedules(removedRows);
    removedRows.forEach(targetSet.remove);
    notifyListeners();
  }

  Future<void> removeIds(Set<int> rowIds, {ScheduleRowType type = ScheduleRowType.all}) async {
    final targetSet = _getTarget(type);

    final removedRows = targetSet.where((row) => rowIds.contains(row.id)).toSet();
    // only the all type affect the database.
    if (type == ScheduleRowType.all) await metadataDb.removeWallpaperSchedules(removedRows);
    removedRows.forEach(targetSet.remove);
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

  Future<void> clear({ScheduleRowType type = ScheduleRowType.all}) async {
    final targetSet = _getTarget(type);

    await metadataDb.clearWallpaperSchedules();
    targetSet.clear();
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
    int? id,
    ScheduleRowType type = ScheduleRowType.all,
  }) {
    var thisGuardLevel = type ==ScheduleRowType.all?
    privacyGuardLevels.all.firstWhereOrNull((e) => e.privacyGuardLevelID == privacyGuardLevelId)
        :  privacyGuardLevels.bridgeAll.firstWhereOrNull((e) => e.privacyGuardLevelID == privacyGuardLevelId);
    thisGuardLevel ??= privacyGuardLevels.all.first;

    var thisFiltersSet = filtersSets.all.firstWhereOrNull((e) => e.id == filtersSetId);
    thisFiltersSet ??= filtersSets.all.first;

    final targetSet = _getTarget(type);
    final relevantItems = isActive ? targetSet.where((item) => item.isActive).toList() : targetSet.toList();
    final maxScheduleNum =
        relevantItems.isEmpty ? 0 : relevantItems.map((item) => item.orderNum).reduce((a, b) => a > b ? a : b);

    return WallpaperScheduleRow(
      id: id ?? metadataDb.nextId,
      orderNum: maxScheduleNum + existMaxOrderNumOffset,
      labelName:
          labelName ?? 'L${thisGuardLevel.guardLevel}-ID_$privacyGuardLevelId-${thisGuardLevel.labelName}-${updateType.name}',
      privacyGuardLevelId: privacyGuardLevelId,
      filtersSetId: thisFiltersSet.id,
      updateType: updateType,
      widgetId: widgetId ?? 0,
      displayType: displayType ?? settings.fgwDisplayType,
      interval: interval ?? settings.defaultNewUpdateInterval,
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
    await metadataDb.addWallpaperSchedules(_rows);
    notifyListeners();
  }

  Future<void> setExistRows(Set<WallpaperScheduleRow> rows, Map<String, dynamic> newValues,
      {ScheduleRowType type = ScheduleRowType.all}) async {
    final targetSet = _getTarget(type);

    // Make a copy of the targetSet to avoid concurrent modification issues
    final targetSetCopy = targetSet.toSet();

    for (var row in rows) {
      final oldRow = targetSetCopy.firstWhereOrNull((r) => r.id == row.id);
      if (oldRow != null) {
        await removeEntries({oldRow}, type: type);
        final updatedRow = WallpaperScheduleRow(
          id: row.id,
          orderNum: newValues[WallpaperScheduleRow.propOrderNum] ?? row.orderNum,
          labelName: newValues[WallpaperScheduleRow.propLabelName] ?? row.labelName,
          privacyGuardLevelId: newValues[WallpaperScheduleRow.propPrivacyGuardLevelId] ?? row.privacyGuardLevelId,
          filtersSetId: newValues[WallpaperScheduleRow.propFiltersSetId] ?? row.filtersSetId,
          updateType: newValues[WallpaperScheduleRow.propUpdateType] ?? row.updateType,
          widgetId: newValues[WallpaperScheduleRow.propWidgetId] ?? row.widgetId,
          displayType: newValues[WallpaperScheduleRow.propDisplayType] ?? row.displayType,
          interval: newValues[WallpaperScheduleRow.propInterval] ?? row.interval,
          isActive: newValues[WallpaperScheduleRow.propIsActive] ?? row.isActive,
        );
        await setRows({updatedRow}, type: type);
        // set conflict update type in {home,lock} and {both}.
        if (updatedRow.isActive) {
          if (updatedRow.updateType == WallpaperUpdateType.home || updatedRow.updateType == WallpaperUpdateType.lock) {
            // Deactivate rows with updateType both
            for (var conflictingRow in targetSetCopy.where((r) =>
                r.updateType == WallpaperUpdateType.both && r.privacyGuardLevelId == updatedRow.privacyGuardLevelId)) {
              await set(
                id: conflictingRow.id,
                orderNum: conflictingRow.orderNum,
                labelName: conflictingRow.labelName,
                privacyGuardLevelId: conflictingRow.privacyGuardLevelId,
                filtersSetId: conflictingRow.filtersSetId,
                updateType: conflictingRow.updateType,
                widgetId: conflictingRow.widgetId,
                displayType: conflictingRow.displayType,
                intervalTime: conflictingRow.interval,
                isActive: false,
                type: type,
              );
            }
          } else if (updatedRow.updateType == WallpaperUpdateType.both) {
            // Deactivate rows with updateType home or lock
            for (var conflictingRow in targetSetCopy.where((r) =>
                (r.updateType == WallpaperUpdateType.home || r.updateType == WallpaperUpdateType.lock) &&
                r.privacyGuardLevelId == updatedRow.privacyGuardLevelId)) {
              await set(
                id: conflictingRow.id,
                orderNum: conflictingRow.orderNum,
                labelName: conflictingRow.labelName,
                privacyGuardLevelId: conflictingRow.privacyGuardLevelId,
                filtersSetId: conflictingRow.filtersSetId,
                updateType: conflictingRow.updateType,
                widgetId: conflictingRow.widgetId,
                displayType: conflictingRow.displayType,
                intervalTime: conflictingRow.interval,
                isActive: false,
                type: type,
              );
            }
          }
        }
      }
    }
    await _removeDuplicates();
    notifyListeners();
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

  Future<void> import(dynamic jsonMap) async {
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

  // Define property name constants
  static const String propId = 'id';
  static const String propOrderNum = 'orderNum';
  static const String propLabelName = 'labelName';
  static const String propPrivacyGuardLevelId = 'privacyGuardLevelId';
  static const String propFiltersSetId = 'filtersSetId';
  static const String propUpdateType = 'updateType';
  static const String propWidgetId = 'widgetId';
  static const String propDisplayType = 'displayType';
  static const String propInterval = 'interval';
  static const String propIsActive = 'isActive';

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
    final defaultDisplayType =
        FgwDisplayedType.values.safeByName(map['displayType'] as String, settings.fgwDisplayType);
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
  String toJson() => jsonEncode(toMap());

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

    // If isActive is the same, sort by orderNum
    final orderNumComparison = orderNum.compareTo(other.orderNum);
    if (orderNumComparison != 0) {
      return orderNumComparison;
    }
    // If orderNum is the same, sort by id
    return id.compareTo(other.id);
  }

  WallpaperScheduleRow copyWith({
    int? id,
    int? orderNum,
    String? labelName,
    int? privacyGuardLevelId,
    int? filtersSetId,
    WallpaperUpdateType? updateType,
    int? widgetId,
    FgwDisplayedType? displayType,
    int? interval,
    bool? isActive,
  }) {
    return WallpaperScheduleRow(
      id: id ?? this.id,
      orderNum: orderNum ?? this.orderNum,
      labelName: labelName ?? this.labelName,
      privacyGuardLevelId: privacyGuardLevelId ?? this.privacyGuardLevelId,
      filtersSetId: filtersSetId ?? this.filtersSetId,
      updateType: updateType ?? this.updateType,
      widgetId: widgetId ?? this.widgetId,
      displayType: displayType ?? this.displayType,
      interval: interval ?? this.interval,
      isActive: isActive ?? this.isActive,
    );
  }
}
