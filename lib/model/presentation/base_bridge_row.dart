import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

enum PresentationRowType { all, bridgeAll }

abstract class PresentationRows<T extends PresentRow> with ChangeNotifier {
  Set<T> _rows = {};
  Set<T> _bridgeRows = {};

  @protected
  Set<T> get rows => _rows;
  @protected
  Set<T> get bridgeRows => _bridgeRows;

  Future<void> init() async {
    _rows = await loadAllRows();
    _bridgeRows = await loadAllRows();
  }

  Future<Set<T>> loadAllRows();

  Future<void> refresh({bool notify = true}) async {
    _rows.clear();
    _bridgeRows.clear();
    _rows = await loadAllRows();
    _bridgeRows.addAll(_rows);
    if (notify) notifyListeners();
  }

  @protected
  Set<T> getTarget(PresentationRowType type) {
    switch (type) {
      case PresentationRowType.bridgeAll:
        return _bridgeRows;
      case PresentationRowType.all:
      default:
        return _rows;
    }
  }

  Set<T> getAll(PresentationRowType type) {
    switch (type) {
      case PresentationRowType.bridgeAll:
        return Set.unmodifiable(_bridgeRows);
      case PresentationRowType.all:
      default:
        return Set.unmodifiable(_rows);
    }
  }

  Future<void> add(Set<T> newRows, {PresentationRowType type = PresentationRowType.all, bool notify = true}) async {
    final targetSet = getTarget(type);
    if (type == PresentationRowType.all) {
      await addRowsToDb(newRows);
    }
    targetSet.addAll(newRows);
    if (notify) notifyListeners();
  }

  Future<void> addRowsToDb(Set<T> newRows);

  Future<void> removeRows(Set<T> rows, {PresentationRowType type = PresentationRowType.all, bool notify = true}) =>
      removeIds(rows.map((row) => row.id).toSet(), type: type, notify: notify);

  Future<void> removeIds(Set<int> rowIds,
      {PresentationRowType type = PresentationRowType.all, bool notify = true}) async {
    final targetSet = getTarget(type);
    final removedRows = targetSet.where((row) => rowIds.contains(row.id)).toSet();

    if (type == PresentationRowType.all) {
      await removeRowsFromDb(removedRows);
    }
    removedRows.forEach(targetSet.remove);
    if (notify) notifyListeners();
  }

  Future<void> removeRowsFromDb(Set<T> removedRows);

  Future<void> removeBeforeSet(int id, {PresentationRowType type = PresentationRowType.all, bool notify = true}) async {
    final targetSet = getTarget(type);

    final oldRows = targetSet.where((row) => row.id == id).toSet();
    targetSet.removeAll(oldRows);
    if (type == PresentationRowType.all) await removeRowsFromDb(oldRows);
    if (notify) notifyListeners();
  }

  Future<void> clear({PresentationRowType type = PresentationRowType.all, bool notify = true}) async {
    final targetSet = getTarget(type);
    if (type == PresentationRowType.all) {
      await clearRowsInDb();
    }
    targetSet.clear();
    if (notify) notifyListeners();
  }

  Future<void> clearRowsInDb();

  //t4y: shall use the rows copy with method to set Rows.
  Future<void> setRows(Set<T> newRows, {PresentationRowType type = PresentationRowType.all, bool notify = true}) async {
    for (var row in newRows) {
      await set(row, type: type, notify: false);
    }
    notifyListeners();
  }

  Future<void> set(T row, {PresentationRowType type = PresentationRowType.all, bool notify = true}) async {
    final targetSet = getTarget(type);

    targetSet.removeWhere((oldRow) => oldRow.id == row.id);
    if (type == PresentationRowType.all) {
      await removeRowsFromDb({row});
    }

    targetSet.add(row);
    if (type == PresentationRowType.all) {
      await addRowsToDb({row});
    }

    if (notify) notifyListeners();
  }

  int get count => _rows.length;

  Set<T> get all => Set.unmodifiable(_rows);
  Set<T> get bridgeAll => Set.unmodifiable(_bridgeRows);

  Future<void> syncRowsToBridge({bool notify = true}) async {
    debugPrint('$runtimeType syncRowsToBridge,\n'
        'all:[$_rows]'
        'before bridget:[$_bridgeRows]');
    await refresh(notify: false);
    _bridgeRows.clear();
    _bridgeRows.addAll(_rows);

    debugPrint('$runtimeType syncRowsToBridge,\n'
        'after bridget:[$_bridgeRows]');
    if (notify) notifyListeners();
  }

  Future<void> syncBridgeToRows({bool notify = true}) async {
    debugPrint('$runtimeType syncBridgeToRows, before\n'
        'all:[$_rows]'
        'before bridget:[$_bridgeRows]');

    await clear(notify: false);
    _rows.addAll(_bridgeRows);
    await addRowsToDb(_rows);

    debugPrint('$runtimeType syncBridgeToRows, after\n'
        'all:[$_rows]'
        'before bridget:[$_bridgeRows]');
    if (notify) notifyListeners();
  }

  // Import/Export functionality
  Map<String, Map<String, dynamic>>? export() {
    final rows = _rows;
    final jsonMap = Map.fromEntries(rows.map((row) {
      return MapEntry(
        row.id.toString(),
        row.toMap(),
      );
    }));
    return jsonMap.isNotEmpty ? jsonMap : null;
  }

  T importFromMap(Map<String, dynamic> attributes);

  Future<void> import(dynamic jsonMap, {bool notify = true}) async {
    if (jsonMap is! Map) {
      debugPrint('failed to import privacy guard levels for jsonMap=$jsonMap');
      return;
    }

    final foundRows = <T>{};
    jsonMap.forEach((id, attributes) {
      if (id is String && attributes is Map<String, dynamic>) {
        try {
          final row = importFromMap(attributes);
          foundRows.add(row);
        } catch (e) {
          debugPrint('failed to import PresentationRows for id=$id, attributes=$attributes, error=$e');
        }
      } else {
        debugPrint('failed to import PresentationRows id=$id, attributes=${attributes.runtimeType}');
      }
    });

    if (foundRows.isNotEmpty) {
      await clear(notify: false);
      await add(foundRows, notify: false);
      if (notify) notifyListeners();
    }
  }
}

/// Base class for presentation rows with equatable and comparable functionality.
@immutable
abstract class PresentRow<T> extends Equatable implements Comparable<T> {
  final int id;
  final String labelName;
  final bool isActive;

  const PresentRow({
    required this.id,
    required this.labelName,
    required this.isActive,
  });

  Map<String, dynamic> toMap();

  static T fromMap<T>(Map<String, dynamic> map) {
    throw UnimplementedError();
  }

  @override
  List<Object?> get props => [id, labelName, isActive];

  @override
  int compareTo(T other) {
    if (isActive != (other as PresentRow).isActive) {
      return isActive ? -1 : 1;
    }
    final labelComparison = labelName.compareTo(other.labelName);
    if (labelComparison != 0) {
      return labelComparison;
    }
    return id.compareTo(other.id);
  }

  T copyWith({
    int? id,
    String? labelName,
    bool? isActive,
  });

  static String formatItemMap(Map<String, dynamic> map) {
    return map.entries.map((entry) {
      if (entry.key == 'dateMillis' && entry.value is int) {
        final date = DateTime.fromMillisecondsSinceEpoch(entry.value as int);
        return '${entry.key}: ${date.toLocal()}';
      }
      return '${entry.key}: ${entry.value}';
    }).join('\n');
  }
}
