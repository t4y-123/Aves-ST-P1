import 'dart:async';
import 'package:aves/services/common/services.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

final PrivacyGuardLevel privacyGuardLevels = PrivacyGuardLevel._private();


class PrivacyGuardLevel with ChangeNotifier {

  Set<PrivacyGuardLevelRow> _rows = {};

  PrivacyGuardLevel._private();

  Future<void> init() async {
    _rows = await metadataDb.loadAllPrivacyGuardLevels();
  }

  Future<void> initializePrivacyGuardLevels(Set<PrivacyGuardLevelRow> initialPrivacyGuardLevels) async {
    await init();
    final currentLevels = await metadataDb.loadAllPrivacyGuardLevels();
    if (currentLevels.isEmpty) {
      await privacyGuardLevels.add(initialPrivacyGuardLevels);
      notifyListeners();
    }
  }

  int get count => _rows.length;

  Set<int> get all => Set.unmodifiable(_rows.map((v) => v.privacyGuardLevelID));

  Future<void> add(Set<PrivacyGuardLevelRow> newRows) async {
    await metadataDb.addPrivacyGuardLevels(newRows);
    _rows.addAll(newRows);

    notifyListeners();
  }

  Future<void> set({
    required privacyGuardLevelID,
    required guardLevel,
    required aliasName,
    required color,
    required bool isActive,
  }) async {
    // erase contextual properties from filters before saving them
    final oldRows = _rows.where((row) => row.privacyGuardLevelID == privacyGuardLevelID).toSet();
    _rows.removeAll(oldRows);
    await metadataDb.removePrivacyGuardLevels(oldRows);

    final row = PrivacyGuardLevelRow(
      privacyGuardLevelID: privacyGuardLevelID,
      guardLevel: guardLevel,
      aliasName: aliasName,
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

// import/export
  // TODO: import/export for backup.
}



@immutable
class PrivacyGuardLevelRow extends Equatable {
  final int privacyGuardLevelID;
  final int guardLevel;
  final String aliasName;
  final Color? color;
  final bool isActive;

  @override
  List<Object?> get props => [privacyGuardLevelID, guardLevel, aliasName, color];

  const PrivacyGuardLevelRow({
    required this.privacyGuardLevelID,
    required this.guardLevel,
    required this.aliasName,
    required this.color,
    required this.isActive,
  });

  factory PrivacyGuardLevelRow.fromMap(Map<String, dynamic> map) {

    final colorValue = map['color'] as int?;
    final color = colorValue != null ? Color(colorValue) : null;

    return PrivacyGuardLevelRow(
      privacyGuardLevelID: map['id'] as int,
      guardLevel: map['guardLevel'] as int,
      aliasName: map['aliasName'] as String,
      color: color,
      isActive: (map['isActive'] as int? ?? 0) != 0,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': privacyGuardLevelID,
    'guardLevel': guardLevel,
    'aliasName': aliasName,
    'color': color?.value,
    'isActive' : isActive,
  };
}
