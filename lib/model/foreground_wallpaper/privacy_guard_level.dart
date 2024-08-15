import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:aves/services/common/services.dart';
import 'package:collection/collection.dart';
import 'package:equatable/equatable.dart';
import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

import '../../l10n/l10n.dart';
import '../settings/settings.dart';

final PrivacyGuardLevel privacyGuardLevels = PrivacyGuardLevel._private();

enum LevelRowType {all,bridgeAll}

class PrivacyGuardLevel with ChangeNotifier {

  Set<PrivacyGuardLevelRow> _rows = {};
  Set<PrivacyGuardLevelRow> _bridgeRows = {};

  PrivacyGuardLevel._private();

  Future<void> init() async {
    _rows = await metadataDb.loadAllPrivacyGuardLevels();
    _bridgeRows = await metadataDb.loadAllPrivacyGuardLevels();
  }

  Future<void> refresh() async {
    _rows.clear();
    _bridgeRows.clear();
    _rows = await metadataDb.loadAllPrivacyGuardLevels();
    _bridgeRows = await metadataDb.loadAllPrivacyGuardLevels();
  }

  int get count => _rows.length;

  Set<PrivacyGuardLevelRow> get all => Set.unmodifiable(_rows);
  Set<PrivacyGuardLevelRow> get bridgeAll => Set.unmodifiable(_bridgeRows);

  Set<PrivacyGuardLevelRow> _getTarget(LevelRowType type) {
    switch (type) {
      case LevelRowType.bridgeAll:
        return _bridgeRows;
      case LevelRowType.all:
      default:
        return _rows;
    }
  }

  Future<void> add(Set<PrivacyGuardLevelRow> newRows, {LevelRowType type = LevelRowType.all}) async {
    final targetSet = _getTarget(type);
    if (type == LevelRowType.all) {
      await metadataDb.addPrivacyGuardLevels(newRows);
    }
    targetSet.addAll(newRows);
    notifyListeners();
  }

  Future<void> setRows(Set<PrivacyGuardLevelRow> newRows, {LevelRowType type = LevelRowType.all}) async {
    for (var row in newRows) {
      await set(
        privacyGuardLevelID: row.privacyGuardLevelID,
        guardLevel: row.guardLevel,
        labelName: row.labelName,
        color: row.color!,
        isActive: row.isActive,
        type: type,
      );
    }
    notifyListeners();
  }

  Future<void> set({
    required int privacyGuardLevelID,
    required int guardLevel,
    required String labelName,
    required Color color,
    required bool isActive,
    LevelRowType type = LevelRowType.all,
  }) async {
    final targetSet = _getTarget(type);

    final oldRows = targetSet.where((row) => row.privacyGuardLevelID == privacyGuardLevelID).toSet();
    targetSet.removeAll(oldRows);
    if (type == LevelRowType.all) {
      await metadataDb.removePrivacyGuardLevels(oldRows);
    }

    final row = PrivacyGuardLevelRow(
      privacyGuardLevelID: privacyGuardLevelID,
      guardLevel: guardLevel,
      labelName: labelName,
      color: color,
      isActive: isActive,
    );
    targetSet.add(row);
    if (type == LevelRowType.all) {
      await metadataDb.addPrivacyGuardLevels({row});
    }

    notifyListeners();
  }

  Future<void> removeEntries(Set<PrivacyGuardLevelRow> rows, {LevelRowType type = LevelRowType.all}) async {
    await removeIds(rows.map((row) => row.privacyGuardLevelID).toSet(), type: type);
  }

  Future<void> removeIds(Set<int> rowIds, {LevelRowType type = LevelRowType.all}) async {
    final targetSet = _getTarget(type);

    final removedRows = targetSet.where((row) => rowIds.contains(row.privacyGuardLevelID)).toSet();
    if (type == LevelRowType.all) {
      await metadataDb.removePrivacyGuardLevels(removedRows);
    }
    removedRows.forEach(targetSet.remove);

    notifyListeners();
  }

  Future<void> clear({LevelRowType type = LevelRowType.all}) async {
    final targetSet = _getTarget(type);

    if (type == LevelRowType.all) {
      await metadataDb.clearPrivacyGuardLevel();
    }
    targetSet.clear();

    notifyListeners();
  }

  Color getRandomColor() {
    final Random random = Random();
    return Color.fromARGB(
      255,
      random.nextInt(256),
      random.nextInt(256),
      random.nextInt(256),
    );
  }

  Future<String> getLabelName(int guardLevel) async {
    AppLocalizations _l10n = await AppLocalizations.delegate.load(settings.appliedLocale);
    final prefix = _l10n.guardLevelNamePrefix;
    return '$prefix $guardLevel';
  }

  Future<PrivacyGuardLevelRow> newRow(int existLevelOffset, {String? labelName, Color? newColor, bool isActive = true, LevelRowType type = LevelRowType.all}) async {
    final targetSet = _getTarget(type);

    final relevantItems = isActive
        ? targetSet.where((item) => item.isActive).toList()
        : targetSet.toList();
    final maxGuardLevel = relevantItems.isEmpty
        ? 0
        : relevantItems.map((item) => item.guardLevel).reduce((a, b) => a > b ? a : b);
    final guardLevel =  maxGuardLevel + existLevelOffset;
    return PrivacyGuardLevelRow(
      privacyGuardLevelID: metadataDb.nextId,
      guardLevel: guardLevel,
      labelName: labelName ?? await getLabelName(guardLevel),
      color:  newColor ?? getRandomColor(),
      isActive: isActive,
    );
  }

  Future<void> setExistRows({
    required Set<PrivacyGuardLevelRow> rows,
    required Map<String, dynamic> newValues,
    LevelRowType type =LevelRowType.all,
  }) async {
    final setBridge = type == LevelRowType.bridgeAll;
    final targetSet = setBridge ? _bridgeRows : _rows;

    debugPrint('$runtimeType setExistRows privacyGuardLevels: ${privacyGuardLevels.all}\n'
        'row.targetSet:[$targetSet]  \n'
        'newValues $newValues\n');
    for (var row in rows) {
      final oldRow = targetSet.firstWhereOrNull((r) => r.privacyGuardLevelID == row.privacyGuardLevelID);
      if (oldRow != null) {
        debugPrint('$runtimeType setExistRows:$oldRow');
        targetSet.remove(oldRow);
        if (!setBridge) {
          await metadataDb.removePrivacyGuardLevels({oldRow});
        }

        final updatedRow = PrivacyGuardLevelRow(
          privacyGuardLevelID: row.privacyGuardLevelID,
          guardLevel: newValues[PrivacyGuardLevelRow.propGuardLevel] ?? row.guardLevel,
          labelName: newValues[PrivacyGuardLevelRow.propLabelName] ?? row.labelName,
          color: newValues[PrivacyGuardLevelRow.propColor] ?? row.color,
          isActive: newValues[PrivacyGuardLevelRow.propIsActive] ?? row.isActive,
        );

        targetSet.add(updatedRow);
        if (!setBridge) {
          await metadataDb.addPrivacyGuardLevels({updatedRow});
        }
      }
    }
    notifyListeners();
  }

  Future<void> syncRowsToBridge() async {
    debugPrint('$runtimeType  syncRowsToBridge,\n'
        'all:[$_rows]'
        'before bridget:[$_bridgeRows]');
    _bridgeRows.clear();
    _bridgeRows.addAll(_rows);
    debugPrint('$runtimeType  syncRowsToBridge,\n'
        'after bridget:[$_bridgeRows]');
  }

  Future<void> syncBridgeToRows() async {
    debugPrint('$runtimeType  syncBridgeToRows, before\n'
        'all:[$_rows]'
        'before bridget:[$_bridgeRows]');
    await clear();
    _rows.addAll(_bridgeRows);
    await metadataDb.addPrivacyGuardLevels(_rows);
    debugPrint('$runtimeType  syncBridgeToRows, after\n'
        'all:[$_rows]'
        'before bridget:[$_bridgeRows]');
    notifyListeners();
  }


  // import/export
  Map<String, Map<String, dynamic>>? export() {
    final rows = privacyGuardLevels.all;
    final jsonMap = Map.fromEntries(rows.map((row) {
      return MapEntry(
        row.privacyGuardLevelID.toString(),
        row.toMap(),
      );
    }));
    return jsonMap.isNotEmpty ? jsonMap : null;
  }

  Future<void> import (dynamic jsonMap) async {
    if (jsonMap is! Map) {
      debugPrint('failed to import privacy guard levels for jsonMap=$jsonMap');
      return;
    }

    final foundRows = <PrivacyGuardLevelRow>{};
    jsonMap.forEach((id, attributes) {
      if (id is String && attributes is Map<String, dynamic>) {
        try {
          final row = PrivacyGuardLevelRow.fromMap(attributes);
          foundRows.add(row);
        } catch (e) {
          debugPrint('failed to import privacy guard level for id=$id, attributes=$attributes, error=$e');
        }
      } else {
        debugPrint('failed to import privacy guard level for id=$id, attributes=${attributes.runtimeType}');
      }
    });

    if (foundRows.isNotEmpty) {
      await privacyGuardLevels.clear();
      await privacyGuardLevels.add(foundRows);
    }
  }
}



@immutable
class PrivacyGuardLevelRow extends Equatable  implements Comparable<PrivacyGuardLevelRow>{
  final int privacyGuardLevelID;
  final int guardLevel;
  final String labelName;
  final Color? color;
  final bool isActive;
  // Define property name constants
  static const String propGuardLevel = 'guardLevel';
  static const String propLabelName = 'labelName';
  static const String propColor = 'color';
  static const String propIsActive = 'isActive';

  @override
  List<Object?> get props => [privacyGuardLevelID, guardLevel, labelName, color,isActive];

  const PrivacyGuardLevelRow({
    required this.privacyGuardLevelID,
    required this.guardLevel,
    required this.labelName,
    required this.color,
    required this.isActive,
  });

  factory PrivacyGuardLevelRow.fromMap(Map<String, dynamic> map) {
    //debugPrint('$PrivacyGuardLevelRow map $map');
    final colorValue = map['color'] as String?;
    //debugPrint('$PrivacyGuardLevelRow colorValue $colorValue ${colorValue!.toColor}');
    final color = colorValue?.toColor;
    //debugPrint('$PrivacyGuardLevelRow  color $color');

    return PrivacyGuardLevelRow(
      privacyGuardLevelID: map['id'] as int,
      guardLevel: map['guardLevel'] as int,
      labelName: map['labelName'] as String,
      color: color,
      isActive: (map['isActive'] as int? ?? 0) != 0,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': privacyGuardLevelID,
    'guardLevel': guardLevel,
    'labelName': labelName,
    'color':'0x${color?.value.toRadixString(16).padLeft(8, '0')}',
    'isActive' : isActive ? 1 : 0,
  };

  String toJson() => jsonEncode(toMap());

  @override
  int compareTo(PrivacyGuardLevelRow other) {
    // Sorting logic
    if (isActive != other.isActive) {
      // Sort by isActive, true (1) comes before false (0)
      return isActive ? -1 : 1;
    }

    // If isActive is the same, sort by guardLevel, which should be unique in database.
    final guardLevelComparison = guardLevel.compareTo(other.guardLevel);
    if (guardLevelComparison != 0) {
      return guardLevelComparison;
    }

    // If guardLevel is the same, sort by privacyGuardLevelID
    return privacyGuardLevelID.compareTo(other.privacyGuardLevelID);
  }
}
