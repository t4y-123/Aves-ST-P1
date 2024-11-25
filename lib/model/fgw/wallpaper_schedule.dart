import 'dart:async';
import 'dart:convert';

import 'package:aves/model/fgw/enum/fgw_schedule_item.dart';
import 'package:aves/model/fgw/guard_level.dart';
import 'package:aves/model/presentation/base_bridge_row.dart';
import 'package:aves/model/settings/settings.dart';
import 'package:aves/services/common/services.dart';
import 'package:aves/utils/collection_utils.dart';
import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';

final FgwSchedule fgwSchedules = FgwSchedule._private();

class FgwSchedule extends PresentationRows<FgwScheduleRow> {
  FgwSchedule._private();

  @override
  Future<Set<FgwScheduleRow>> loadAllRows() async {
    return await localMediaDb.loadAllFgwSchedules();
  }

  @override
  Future<void> addRowsToDb(Set<FgwScheduleRow> newRows) async {
    await localMediaDb.addFgwSchedules(newRows);
  }

  @override
  Future<void> removeRowsFromDb(Set<FgwScheduleRow> removedRows) async {
    await localMediaDb.removeFgwSchedules(removedRows);
  }

  @override
  Future<void> clearRowsInDb() async {
    await localMediaDb.clearFgwSchedules();
  }

  Future<void> _removeDuplicates({PresentationRowType type = PresentationRowType.all}) async {
    final uniqueRows = <String, FgwScheduleRow>{};
    final duplicateRows = <FgwScheduleRow>{};
    final todoRows = getAll(type);
    for (var row in todoRows) {
      String key;
      if (row.updateType == WallpaperUpdateType.widget) {
        key = '${row.guardLevelId}-${row.updateType}-${row.widgetId}';
      } else {
        key = '${row.guardLevelId}-${row.updateType}';
      }
      if (uniqueRows.containsKey(key)) {
        duplicateRows.add(uniqueRows[key]!);
      }
      uniqueRows[key] = row; // This will keep the last occurrence
    }
    await setRows(uniqueRows.values.toSet(), type: type);
    if (duplicateRows.isNotEmpty) {
      await removeRows(duplicateRows, type: type);
    }
  }

  FgwScheduleRow newRow({
    required int existMaxOrderNumOffset,
    required int guardLevelId,
    required int filtersSetId,
    required WallpaperUpdateType updateType,
    FgwDisplayedType? displayType,
    String? labelName,
    int? widgetId,
    int? interval,
    bool isActive = true,
    int? id,
    PresentationRowType type = PresentationRowType.all,
  }) {
    // get a guard level.
    final relateGuardLevel = fgwGuardLevels.getAll(type);

    if (relateGuardLevel.isEmpty) throw 'In general GuardLevel show not be empty!';
    debugPrint('$runtimeType WallpaperScheduleRow newRow relateGuardLevel:\n$relateGuardLevel');
    var thisGuardLevel = relateGuardLevel.firstWhereOrNull((e) => e.id == guardLevelId);
    debugPrint('$runtimeType WallpaperScheduleRow newRow $guardLevelId thisGuardLevel:\n$thisGuardLevel');

    thisGuardLevel ??= relateGuardLevel.first;
    //
    // get a filterSet
    // final relateFilterSet = filtersSets.getAll(type);
    // if (relateGuardLevel.isEmpty) throw 'In general FilterSet  show not be empty!';
    // var thisFiltersSet = relateFilterSet.firstWhereOrNull((e) => e.id == filtersSetId) ?? filtersSets.all.first;

    final targetSet = getAll(type);
    final relevantItems = isActive ? targetSet.where((item) => item.isActive).toList() : targetSet.toList();
    final maxScheduleNum =
        relevantItems.isEmpty ? 0 : relevantItems.map((item) => item.orderNum).reduce((a, b) => a > b ? a : b);
    final labelNameCommon = labelName ??
        'L${thisGuardLevel.guardLevel} ${thisGuardLevel.labelName} ${updateType.name} id.${thisGuardLevel.id} ';
    final newLabelName = (updateType == WallpaperUpdateType.widget) ? '$labelNameCommon $widgetId' : labelNameCommon;

    return FgwScheduleRow(
      id: id ?? localMediaDb.nextDateId,
      orderNum: maxScheduleNum + existMaxOrderNumOffset,
      labelName: newLabelName,
      guardLevelId: guardLevelId,
      filtersSetId: filtersSetId,
      updateType: updateType,
      widgetId: widgetId ?? 0,
      displayType: displayType ?? settings.fgwDisplayType,
      interval: interval ?? settings.defaultNewUpdateInterval,
      isActive: isActive,
    );
  }

  Future<void> setWithDealConflictUpdateType(Set<FgwScheduleRow> rows,
      {PresentationRowType type = PresentationRowType.all}) async {
    final targetSet = getAll(type);

    // Make a copy of the targetSet to avoid concurrent modification issues
    final targetSetCopy = targetSet.toSet();
    debugPrint('$runtimeType \n curRow $rows \n'
        'targetSet $targetSet\n ');

    for (var row in rows) {
      final oldRow = targetSetCopy.firstWhereOrNull((r) => r.id == row.id);
      if (oldRow != null) {
        final updatedRow = row.copyWith();
        await removeRows({oldRow}, type: type);
        await setRows({updatedRow}, type: type);
        // set conflict update type in {home,lock} and {both}.
        if (updatedRow.isActive && (updatedRow.updateType != WallpaperUpdateType.widget)) {
          if (updatedRow.updateType == WallpaperUpdateType.home || updatedRow.updateType == WallpaperUpdateType.lock) {
            // Deactivate rows with updateType both
            for (var conflictingRow in targetSetCopy
                .where((r) => r.updateType == WallpaperUpdateType.both && r.guardLevelId == updatedRow.guardLevelId)) {
              final newRow = conflictingRow.copyWith(isActive: false);
              await set(newRow, type: type);
            }
          } else if (updatedRow.updateType == WallpaperUpdateType.both) {
            // Deactivate rows with updateType home or lock
            for (var conflictingRow in targetSetCopy.where((r) =>
                (r.updateType == WallpaperUpdateType.home || r.updateType == WallpaperUpdateType.lock) &&
                r.guardLevelId == updatedRow.guardLevelId)) {
              final newRow = conflictingRow.copyWith(isActive: false);
              await set(newRow, type: type);
            }
          }
        }
      } else {
        await set(row, type: type);
      }
    }
    await _removeDuplicates(type: type);
    notifyListeners();
  }

  @override
  FgwScheduleRow importFromMap(Map<String, dynamic> attributes) {
    return FgwScheduleRow.fromMap(attributes);
  }
}

@immutable
class FgwScheduleRow extends PresentRow<FgwScheduleRow> {
  final int orderNum;
  final int guardLevelId;
  final int filtersSetId;
  final WallpaperUpdateType updateType;
  final int widgetId;
  final FgwDisplayedType displayType;
  final int interval;

  @override
  List<Object?> get props => [
        id,
        orderNum,
        labelName,
        guardLevelId,
        filtersSetId,
        updateType,
        widgetId,
        displayType,
        interval,
        isActive,
      ];

  const FgwScheduleRow({
    required super.id,
    required this.orderNum,
    required super.labelName,
    required this.guardLevelId,
    required this.filtersSetId,
    required this.updateType,
    required this.widgetId,
    required this.displayType,
    required this.interval,
    required super.isActive,
  });

  factory FgwScheduleRow.fromMap(Map map) {
    final defaultDisplayType =
        FgwDisplayedType.values.safeByName(map['displayType'] as String, settings.fgwDisplayType);
    //debugPrint('WallpaperScheduleRow defaultDisplayType $defaultDisplayType fromMap:\n  $map.');
    return FgwScheduleRow(
      id: map['id'] as int,
      orderNum: map['orderNum'] as int,
      labelName: map['labelName'] as String,
      guardLevelId: map['fgwGuardLevelId'] as int,
      filtersSetId: map['filtersSetId'] as int,
      updateType: WallpaperUpdateType.values.safeByName(map['updateType'] as String, WallpaperUpdateType.home),
      widgetId: map['widgetId'] as int,
      displayType: defaultDisplayType,
      interval: map['interval'] as int,
      isActive: (map['isActive'] as int? ?? 0) != 0,
    );
  }

  String toJson() => jsonEncode(toMap());

  @override
  Map<String, dynamic> toMap() => {
        'id': id,
        'orderNum': orderNum,
        'labelName': labelName,
        'fgwGuardLevelId': guardLevelId,
        'filtersSetId': filtersSetId,
        'updateType': updateType.name,
        'widgetId': widgetId,
        'displayType': displayType.name,
        'interval': interval,
        'isActive': isActive ? 1 : 0,
      };

  @override
  int compareTo(FgwScheduleRow other) {
    // 1. Sort by isActive
    if (isActive != other.isActive) {
      return isActive ? -1 : 1;
    }
    // 2. Sort by guardLevelId
    final guardLevelIdComparison = guardLevelId.compareTo(other.guardLevelId);
    if (guardLevelIdComparison != 0) {
      return guardLevelIdComparison;
    }
    // 3. Define the order of WallpaperUpdateType
    const updateTypeOrder = {
      WallpaperUpdateType.home: 0,
      WallpaperUpdateType.lock: 1,
      WallpaperUpdateType.both: 2,
      WallpaperUpdateType.widget: 3,
    };

    // 4. Compare by WallpaperUpdateType order
    final updateTypeComparison = updateTypeOrder[updateType]!.compareTo(updateTypeOrder[other.updateType]!);
    if (updateTypeComparison != 0) {
      return updateTypeComparison;
    }

    // 5. Compare by widgetId
    final widgetIdComparison = widgetId.compareTo(other.widgetId);
    if (widgetIdComparison != 0) {
      return widgetIdComparison;
    }

    // 6. Compare by orderNum
    final orderNumComparison = orderNum.compareTo(other.orderNum);
    if (orderNumComparison != 0) {
      return orderNumComparison;
    }

    // 7. If all else is the same, compare by id
    return id.compareTo(other.id);
  }

  @override
  FgwScheduleRow copyWith({
    int? id,
    int? orderNum,
    String? labelName,
    int? guardLevelId,
    int? filtersSetId,
    WallpaperUpdateType? updateType,
    int? widgetId,
    FgwDisplayedType? displayType,
    int? interval,
    bool? isActive,
  }) {
    return FgwScheduleRow(
      id: id ?? this.id,
      orderNum: orderNum ?? this.orderNum,
      labelName: labelName ?? this.labelName,
      guardLevelId: guardLevelId ?? this.guardLevelId,
      filtersSetId: filtersSetId ?? this.filtersSetId,
      updateType: updateType ?? this.updateType,
      widgetId: widgetId ?? this.widgetId,
      displayType: displayType ?? this.displayType,
      interval: interval ?? this.interval,
      isActive: isActive ?? this.isActive,
    );
  }
}
