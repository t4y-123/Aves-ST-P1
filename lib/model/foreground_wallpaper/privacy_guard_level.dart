import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:aves/services/common/services.dart';
import 'package:collection/collection.dart';
import 'package:equatable/equatable.dart';
import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

final PrivacyGuardLevel privacyGuardLevels = PrivacyGuardLevel._private();

class PrivacyGuardLevel with ChangeNotifier {

  Set<PrivacyGuardLevelRow> _rows = {};

  PrivacyGuardLevel._private();

  Future<void> init() async {
    _rows = await metadataDb.loadAllPrivacyGuardLevels();
  }

  Future<void> refresh() async {
    _rows.clear();
    _rows = await metadataDb.loadAllPrivacyGuardLevels();
  }

  int get count => _rows.length;

  Set<PrivacyGuardLevelRow> get all => Set.unmodifiable(_rows);

  Future<void> add(Set<PrivacyGuardLevelRow> newRows) async {
    await metadataDb.addPrivacyGuardLevels(newRows);
    _rows.addAll(newRows);

    notifyListeners();
  }

  Future<void> setRows(Set<PrivacyGuardLevelRow> newRows) async {
    for (var row in newRows) {
      await set(
        privacyGuardLevelID: row.privacyGuardLevelID,
        guardLevel: row.guardLevel,
        labelName: row.labelName,
        color: row.color!,
        isActive: row.isActive,
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
  }) async {
    // erase contextual properties from filters before saving them
    final oldRows = _rows.where((row) => row.privacyGuardLevelID == privacyGuardLevelID).toSet();
    _rows.removeAll(oldRows);
    await metadataDb.removePrivacyGuardLevels(oldRows);

    final row = PrivacyGuardLevelRow(
      privacyGuardLevelID: privacyGuardLevelID,
      guardLevel: guardLevel,
      labelName: labelName,
      color: color,
      isActive: isActive,
    );
    _rows.add(row);
    await metadataDb.addPrivacyGuardLevels({row});

    notifyListeners();
  }

  Future<void> removeEntries(Set<PrivacyGuardLevelRow> rows) => removeIds(rows.map((row) => row.privacyGuardLevelID).toSet());

  Future<void> removeIds(Set<int> rowIds) async {
    final removedRows = _rows.where((row) => rowIds.contains(row.privacyGuardLevelID)).toSet();

    await metadataDb.removePrivacyGuardLevels(removedRows);
    removedRows.forEach(_rows.remove);

    notifyListeners();
  }

  Future<void> clear() async {
    await metadataDb.clearPrivacyGuardLevel();
    _rows.clear();

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

  PrivacyGuardLevelRow newRow(int existLevelOffset, String alias,{ Color? newColor, bool isActive = true}) {
    final relevantItems = isActive
        ? privacyGuardLevels.all.where((item) => item.isActive).toList()
        : privacyGuardLevels.all.toList();
    final maxGuardLevel = relevantItems.isEmpty
        ? 0
        : relevantItems.map((item) => item.guardLevel).reduce((a, b) => a > b ? a : b);

    return PrivacyGuardLevelRow(
      privacyGuardLevelID: metadataDb.nextId,
      guardLevel: maxGuardLevel + existLevelOffset,
      labelName: alias,
      color:  newColor ?? getRandomColor(),
      isActive: isActive,
    );
  }

  Future<void> setExistRows(Set<PrivacyGuardLevelRow> rows, Map<String, dynamic> newValues) async {
    for (var row in rows) {
      final oldRow = _rows.firstWhereOrNull((r) => r.privacyGuardLevelID == row.privacyGuardLevelID);
      if (oldRow != null) {
        _rows.remove(oldRow);
        await metadataDb.removePrivacyGuardLevels({oldRow});

        final updatedRow = PrivacyGuardLevelRow(
          privacyGuardLevelID: row.privacyGuardLevelID,
          guardLevel: newValues[PrivacyGuardLevelRow.propGuardLevel] ?? row.guardLevel,
          labelName: newValues[PrivacyGuardLevelRow.propLabelName] ?? row.labelName,
          color: newValues[PrivacyGuardLevelRow.propColor] ?? row.color,
          isActive: newValues[PrivacyGuardLevelRow.propIsActive] ?? row.isActive,
        );

        _rows.add(updatedRow);
        await metadataDb.addPrivacyGuardLevels({updatedRow});
      }
    }
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
  List<Object?> get props => [privacyGuardLevelID, guardLevel, labelName, color];

  const PrivacyGuardLevelRow({
    required this.privacyGuardLevelID,
    required this.guardLevel,
    required this.labelName,
    required this.color,
    required this.isActive,
  });

  factory PrivacyGuardLevelRow.fromMap(Map<String, dynamic> map) {
    debugPrint('$PrivacyGuardLevelRow map $map');
    final colorValue = map['color'] as String?;
    debugPrint('$PrivacyGuardLevelRow colorValue $colorValue ${colorValue!.toColor}');
    final color = colorValue.toColor;
    debugPrint('$PrivacyGuardLevelRow  color $color');

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
