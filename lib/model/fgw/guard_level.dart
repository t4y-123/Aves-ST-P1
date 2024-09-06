import 'dart:async';
import 'dart:convert';

import 'package:aves/l10n/l10n.dart';
import 'package:aves/model/fgw/wallpaper_schedule.dart';
import 'package:aves/model/presentation/base_bridge_row.dart';
import 'package:aves/model/settings/settings.dart';
import 'package:aves/services/common/services.dart';
import 'package:aves/theme/colors.dart';
import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

final GuardLevel fgwGuardLevels = GuardLevel._private();

class GuardLevel extends PresentationRows<FgwGuardLevelRow> {
  GuardLevel._private();

  @override
  Future<Set<FgwGuardLevelRow>> loadAllRows() async {
    return await localMediaDb.loadAllFgwGuardLevels();
  }

  @override
  Future<void> addRowsToDb(Set<FgwGuardLevelRow> newRows) async {
    await localMediaDb.addFgwGuardLevels(newRows);
  }

  @override
  Future<void> removeRowsFromDb(Set<FgwGuardLevelRow> removedRows) async {
    await localMediaDb.removeFgwGuardLevels(removedRows);
  }

  @override
  Future<void> clearRowsInDb() async {
    await localMediaDb.clearFgwGuardLevel();
  }

  @override
  Future<void> removeIds(Set<int> rowIds,
      {PresentationRowType type = PresentationRowType.all, bool notify = true}) async {
    await super.removeIds(rowIds, type: type, notify: notify);

    final relatedSchedules = fgwSchedules.getAll(type).where((e) => rowIds.contains(e.guardLevelId)).toSet();
    await fgwSchedules.removeRows(relatedSchedules, type: type, notify: notify);
  }

  Future<String> getLabelName(int guardLevel) async {
    AppLocalizations _l10n = await AppLocalizations.delegate.load(settings.appliedLocale);
    final prefix = _l10n.guardLevelNamePrefix;
    return '$prefix $guardLevel';
  }

  Future<FgwGuardLevelRow> newRow(int existLevelOffset,
      {String? labelName,
      Color? newColor,
      bool isActive = true,
      PresentationRowType type = PresentationRowType.all}) async {
    final targetSet = getAll(type);

    final relevantItems = isActive ? targetSet.where((item) => item.isActive).toList() : targetSet.toList();
    final maxGuardLevel =
        relevantItems.isEmpty ? 0 : relevantItems.map((item) => item.guardLevel).reduce((a, b) => a > b ? a : b);
    final guardLevel = maxGuardLevel + existLevelOffset;
    return FgwGuardLevelRow(
      id: localMediaDb.nextId,
      guardLevel: guardLevel,
      labelName: labelName ?? await getLabelName(guardLevel),
      color: newColor ?? AColors.getRandomColor(),
      isActive: isActive,
    );
  }

  @override
  FgwGuardLevelRow importFromMap(Map<String, dynamic> attributes) {
    return FgwGuardLevelRow.fromMap(attributes);
  }
}

@immutable
class FgwGuardLevelRow extends PresentRow<FgwGuardLevelRow> {
  final int guardLevel;
  final Color? color;

  // Define property name constants
  static const String propGuardLevel = 'guardLevel';
  static const String propColor = 'color';

  const FgwGuardLevelRow({
    required super.id,
    required this.guardLevel,
    required super.labelName,
    required this.color,
    required super.isActive,
  });

  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'guardLevel': guardLevel,
      'labelName': labelName,
      'color': '0x${color?.value.toRadixString(16).padLeft(8, '0')}',
      'isActive': isActive ? 1 : 0,
    };
  }

  factory FgwGuardLevelRow.fromMap(Map<String, dynamic> map) {
    final colorValue = map['color'] as String?;
    final color = colorValue?.toColor;

    return FgwGuardLevelRow(
      id: map['id'] as int,
      guardLevel: map['guardLevel'] as int,
      labelName: map['labelName'] as String,
      color: color,
      isActive: (map['isActive'] as int? ?? 0) != 0,
    );
  }

  String toJson() => jsonEncode(toMap());

  @override
  int compareTo(FgwGuardLevelRow other) {
    // Sorting logic
    if (isActive != other.isActive) {
      // Sort by isActive, true (1) comes before false (0)
      return isActive ? -1 : 1;
    }

    // If isActive is the same, sort by guardLevel
    final guardLevelComparison = guardLevel.compareTo(other.guardLevel);
    if (guardLevelComparison != 0) {
      return guardLevelComparison;
    }

    // If guardLevel is the same, sort by id
    return id.compareTo(other.id);
  }

  @override
  FgwGuardLevelRow copyWith({
    int? id,
    int? guardLevel,
    String? labelName,
    Color? color,
    bool? isActive,
  }) {
    return FgwGuardLevelRow(
      id: id ?? this.id,
      guardLevel: guardLevel ?? this.guardLevel,
      labelName: labelName ?? this.labelName,
      color: color ?? this.color,
      isActive: isActive ?? this.isActive,
    );
  }
}
