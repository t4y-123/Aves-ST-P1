import 'dart:async';
import 'dart:convert';

import 'package:aves/model/assign/assign_entries.dart';
import 'package:aves/model/assign/enum/assign_item.dart';
import 'package:aves/model/presentation/base_bridge_row.dart';
import 'package:aves/model/scenario/scenarios_helper.dart';
import 'package:aves/services/common/services.dart';
import 'package:aves/theme/colors.dart';
import 'package:aves/utils/collection_utils.dart';
import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:intl/intl.dart';

import '../../l10n/l10n.dart';
import '../settings/settings.dart';

final AssignRecord assignRecords = AssignRecord._private();

class AssignRecord extends PresentationRows<AssignRecordRow> {
  AssignRecord._private();

  @override
  Set<AssignRecordRow> get all {
    removeExpiredRecord();
    return getAll(PresentationRowType.all);
  }

  void removeExpiredRecord() {
    if (settings.canAutoRemoveExpiredTempAssign) {
      final now = DateTime.now().millisecondsSinceEpoch;
      final expirationTime = settings.assignTemporaryExpiredInterval * 1000; // Convert to milliseconds
      final expiredRows = getAll(PresentationRowType.all)
          .where((row) => (now - row.dateMillis) > expirationTime && row.assignType == AssignRecordType.temporary)
          .toSet();

      if (expiredRows.isNotEmpty) {
        removeRows(expiredRows, type: PresentationRowType.all); // Remove expired records
        scenariosHelper.removeTemporaryAssignRows(expiredRows, type: PresentationRowType.all); // Remove expired records
      }
    }
    notifyListeners();
  }

  @override
  Future<Set<AssignRecordRow>> loadAllRows() async {
    return await metadataDb.loadAllAssignRecords();
  }

  @override
  Future<void> addRowsToDb(Set<AssignRecordRow> newRows) async {
    await metadataDb.addAssignRecords(newRows);
  }

  @override
  Future<void> removeRowsFromDb(Set<AssignRecordRow> removedRows) async {
    await metadataDb.removeAssignRecords(removedRows);
  }

  @override
  Future<void> clearRowsInDb() async {
    await metadataDb.clearAssignRecords();
  }

  @override
  Future<void> removeIds(Set<int> rowIds,
      {PresentationRowType type = PresentationRowType.all, bool notify = true}) async {
    await super.removeIds(rowIds, type: type, notify: notify);

    final relateItems = assignEntries.getAll(type).where((e) => rowIds.contains(e.assignId)).toSet();
    await assignEntries.removeRows(relateItems, type: type, notify: notify);
  }

  Future<String> getLabelName(int orderNum, DateTime dateTime) async {
    AppLocalizations _l10n = await AppLocalizations.delegate.load(settings.appliedLocale);
    final prefix = _l10n.assignFilterNamePrefix;
    return '$prefix $orderNum ${DateFormat('yyyy-MM-dd HH:mm:ss.SSS').format(dateTime)}';
  }

  Future<AssignRecordRow> newRow(int existOrderNumOffset,
      {String? labelName,
      AssignRecordType? assignType,
      int? dateMillis,
      bool isActive = true,
      int scenarioId = 0,
      PresentationRowType type = PresentationRowType.all}) async {
    final targetSet = getTarget(type);

    final relevantItems = isActive ? targetSet.where((item) => item.isActive).toList() : targetSet.toList();
    final maxOrderNum =
        relevantItems.isEmpty ? 0 : relevantItems.map((item) => item.orderNum).reduce((a, b) => a > b ? a : b);
    final orderNum = maxOrderNum + existOrderNumOffset;
    final finalDateTime = DateTime.now();
    return AssignRecordRow(
      id: metadataDb.nextId,
      orderNum: orderNum,
      labelName: labelName ?? await getLabelName(orderNum, finalDateTime),
      color: AColors.getRandomColor(),
      assignType: assignType ?? AssignRecordType.permanent,
      dateMillis: dateMillis ?? finalDateTime.millisecondsSinceEpoch,
      scenarioId: scenarioId,
      isActive: isActive,
    );
  }

  @override
  AssignRecordRow importFromMap(Map<String, dynamic> attributes) {
    return AssignRecordRow.fromMap(attributes);
  }
}

@immutable
class AssignRecordRow extends PresentRow<AssignRecordRow> {
  final int orderNum;
  final AssignRecordType assignType;
  final Color? color;
  final int dateMillis;
  final int scenarioId;

  @override
  List<Object?> get props => [
        id,
        orderNum,
        labelName,
        assignType,
        color,
        dateMillis,
        scenarioId,
        isActive,
      ];

  const AssignRecordRow({
    required super.id,
    required this.orderNum,
    required super.labelName,
    required this.assignType,
    required this.color,
    required this.dateMillis,
    required this.scenarioId,
    required super.isActive,
  });

  factory AssignRecordRow.fromMap(Map map) {
    final defaultAssignRecordType =
        AssignRecordType.values.safeByName(map['assignType'] as String, AssignRecordType.permanent);
    //debugPrint('AssignRecordRow defaultAssignRecordType $defaultAssignRecordType fromMap:\n  $map.');
    final colorValue = map['color'] as String?;
    //debugPrint('$AssignRecordRow colorValue $colorValue ${colorValue!.toColor}');
    final color = colorValue?.toColor;
    return AssignRecordRow(
      id: map['id'] as int,
      orderNum: map['orderNum'] as int,
      labelName: map['labelName'] as String,
      assignType: defaultAssignRecordType,
      color: color,
      dateMillis: map['dateMillis'] as int,
      scenarioId: map['scenarioId'] as int,
      isActive: (map['isActive'] as int? ?? 0) != 0,
    );
  }

  String toJson() => jsonEncode(toMap());

  @override
  Map<String, dynamic> toMap() => {
        'id': id,
        'orderNum': orderNum,
        'labelName': labelName,
        'assignType': assignType.name,
        'color': '0x${color?.value.toRadixString(16).padLeft(8, '0')}',
        'dateMillis': dateMillis,
        'scenarioId': scenarioId,
        'isActive': isActive ? 1 : 0,
      };

  @override
  int compareTo(AssignRecordRow other) {
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

    // If orderNum is the same, sort by assignType
    final assignTypeComparison = assignType.index.compareTo(other.assignType.index);
    if (assignTypeComparison != 0) {
      return assignTypeComparison;
    }

    // If assignType is the same, sort by labelName
    final labelNameComparison = labelName.compareTo(other.labelName);
    if (labelNameComparison != 0) {
      return labelNameComparison;
    }

    // If labelName is the same, sort by dateMillis
    final dateMillisComparison = dateMillis.compareTo(other.dateMillis);
    if (dateMillisComparison != 0) {
      return dateMillisComparison;
    }

    // If dateMillis is the same, sort by id
    return id.compareTo(other.id);
  }

  @override
  AssignRecordRow copyWith({
    int? id,
    int? orderNum,
    String? labelName,
    AssignRecordType? assignType,
    Color? color,
    int? dateMillis,
    int? scenarioId,
    bool? isActive,
  }) {
    return AssignRecordRow(
      id: id ?? this.id,
      orderNum: orderNum ?? this.orderNum,
      labelName: labelName ?? this.labelName,
      assignType: assignType ?? this.assignType,
      color: color ?? this.color,
      dateMillis: dateMillis ?? this.dateMillis,
      scenarioId: scenarioId ?? this.scenarioId,
      isActive: isActive ?? this.isActive,
    );
  }
}
