import 'dart:async';
import 'dart:convert';
import 'package:aves/model/filters/filters.dart';
import 'package:aves/services/common/services.dart';
import 'package:collection/collection.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

import '../filters/aspect_ratio.dart';
import '../filters/mime.dart';

final FilterSet filtersSets = FilterSet._private();

class FilterSet with ChangeNotifier{

  Set<FiltersSetRow> _rows = {};

  FilterSet._private();

  Future<void> init() async {
    _rows = await metadataDb.loadAllFilterSet();
  }

  Future<void> refresh() async {
    _rows.clear();
    _rows = await metadataDb.loadAllFilterSet();
  }

  Future<void> add(Set<FiltersSetRow> newRows) async {
    await metadataDb.addFilterSet(newRows);
    _rows.addAll(newRows);

    notifyListeners();
  }

  int get count => _rows.length;

  Set<FiltersSetRow> get all => Set.unmodifiable(_rows);

  Future<void> setRows(Set<FiltersSetRow> newRows) async {
    await removeEntries(newRows);
    for (var row in newRows) {
      await set(
        id: row.id,
        orderNum: row.orderNum,
        labelName: row.labelName,
        filters: row.filters,
        isActive: row.isActive,
      );
    }
    notifyListeners();
  }

  Future<void> set({
    required int id,
    required int orderNum,
    required String labelName,
    required Set<CollectionFilter>? filters,
    required bool isActive,
  }) async {
    // erase contextual properties from filters before saving them
    final oldRows = _rows.where((row) => row.id == id).toSet();
    _rows.removeAll(oldRows);
    await metadataDb.removeFilterSet(oldRows);

    final row = FiltersSetRow(
      id: id,
      orderNum: orderNum,
      labelName: labelName,
      filters: filters,
      isActive: isActive,
    );
    _rows.add(row);
    await metadataDb.addFilterSet({row});
    notifyListeners();
  }

  Future<void> removeEntries(Set<FiltersSetRow> rows) => removeIds(rows.map((row) => row.id).toSet());

  Future<void> removeIds(Set<int> rowIds) async {
    final removedRows = _rows.where((row) => rowIds.contains(row.id)).toSet();

    await metadataDb.removeFilterSet(removedRows);
    removedRows.forEach(_rows.remove);

    notifyListeners();
  }


  Future<void> clear() async {
    await metadataDb.clearFilterSet();
    _rows.clear();
    notifyListeners();
  }

  FiltersSetRow newRow(int existActiveMaxLevelOffset, {String? labelName,  Set<CollectionFilter>? filters,bool isActive = true}) {
    final relevantItems = isActive
        ? filtersSets.all.where((item) => item.isActive).toList()
        : filtersSets.all.toList();
    final maxFilterSetNum = relevantItems.isEmpty
        ? 0
        : relevantItems.map((item) => item.orderNum).reduce((a, b) => a > b ? a : b);
    final newId = metadataDb.nextId;
    final filterSetSuqNum = maxFilterSetNum + existActiveMaxLevelOffset;
    return FiltersSetRow(
      id: newId,
      orderNum: filterSetSuqNum,
      labelName: labelName ?? 'F-$filterSetSuqNum-$newId',
      filters: filters ?? {AspectRatioFilter.portrait, MimeFilter.image},
      isActive: isActive,
    );
  }

  Future<void> setExistRows(Set<FiltersSetRow> rows, Map<String, dynamic> newValues) async {
    for (var row in rows) {
      final oldRow = _rows.firstWhereOrNull((r) => r.id == row.id);
      if (oldRow != null) {
        _rows.remove(oldRow);
        await metadataDb.removeFilterSet({oldRow});

        final updatedRow = FiltersSetRow(
          id: row.id,
          orderNum: newValues[FiltersSetRow.propOrderNum] ?? row.orderNum,
          labelName: newValues[FiltersSetRow.propLabelName] ?? row.labelName,
          filters: newValues[FiltersSetRow.propFilters] ?? row.filters,
          isActive: newValues[FiltersSetRow.propIsActive] ?? row.isActive,
        );
        _rows.add(updatedRow);
        await metadataDb.addFilterSet({updatedRow});
      }
    }
    notifyListeners();
  }

  // import/export
  Map<String, Map<String, dynamic>>? export() {
    final rows = filtersSets.all;
    final jsonMap = Map.fromEntries(rows.map((row) {
      return MapEntry(
        row.id.toString(),
        row.toMap(),
      );
    }));
    return jsonMap.isNotEmpty ? jsonMap : null;
  }

  Future<void> import(dynamic jsonMap) async{
    if (jsonMap is! Map) {
      debugPrint('failed to import filter sets for jsonMap=$jsonMap');
      return;
    }

    final foundRows = <FiltersSetRow>{};
    jsonMap.forEach((id, attributes) {
      if (id is String && attributes is Map) {
        try {
          final row = FiltersSetRow.fromMap(attributes);
          foundRows.add(row);
        } catch (e) {
          debugPrint('failed to import filter set for id=$id, attributes=$attributes, error=$e');
        }
      } else {
        debugPrint('failed to import filter set for id=$id, attributes=${attributes.runtimeType}');
      }
    });

    if (foundRows.isNotEmpty) {
      await filtersSets.clear();
      await filtersSets.add(foundRows);
    }
  }
}

@immutable
class FiltersSetRow extends Equatable implements Comparable<FiltersSetRow> {
  final int id;
  final int orderNum;
  final String labelName;
  final Set<CollectionFilter>? filters;
  final bool isActive;

  // Define property name constants
  static const String propOrderNum = 'orderNum';
  static const String propLabelName = 'labelName';
  static const String propFilters = 'filters';
  static const String propIsActive = 'isActive';

  @override
  List<Object?> get props => [id, orderNum, labelName, filters,];

  const FiltersSetRow({
    required this.id,
    required this.orderNum,
    required this.labelName,
    required this.filters,
    required this.isActive,
  });

  static FiltersSetRow fromMap(Map map) {
    final List<dynamic> decodedFilters = jsonDecode(map['filters']);
    final filters = decodedFilters.map((e) => CollectionFilter.fromJson(e as String)).whereNotNull().toSet();

    return FiltersSetRow(
      id:map['id'] as int,
      orderNum:map['orderNum'] as int,
      labelName: map['labelName'] as String,
      filters: filters,
      isActive: (map['isActive'] as int? ?? 0) != 0,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'orderNum': orderNum,
        'labelName': labelName,
        'filters': jsonEncode(filters?.map((filter) => filter.toJson()).toList()),
        'isActive' : isActive ? 1 : 0,
  };

  @override
  int compareTo(FiltersSetRow other) {
    // Sorting logic
    if (isActive != other.isActive) {
      // Sort by isActive, true (1) comes before false (0)
      return isActive ? -1 : 1;
    }
    // If sort by orderNum
    final orderNumComparison = orderNum.compareTo(other.orderNum);
    if (orderNumComparison != 0) {
      return orderNumComparison;
    }

    // If orderNum is the same, sort by labelName
    final labelNameComparison = labelName.compareTo(other.labelName);
    if (labelNameComparison != 0) {
      return labelNameComparison;
    }

    // If labelName is the same, sort by id
    return id.compareTo(other.id);
  }
}
