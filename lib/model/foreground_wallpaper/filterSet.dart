import 'dart:async';
import 'dart:convert';
import 'package:aves/model/filters/filters.dart';
import 'package:aves/services/common/services.dart';
import 'package:collection/collection.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

final FilterSet filterSet = FilterSet._private();

class FilterSet with ChangeNotifier{

  Set<FilterSetRow> _rows = {};

  FilterSet._private();

  Future<void> init() async {
    _rows = await metadataDb.loadAllFilterSet();
  }

  Future<void> add(Set<FilterSetRow> newRows) async {
    await metadataDb.addFilterSet(newRows);
    _rows.addAll(newRows);

    notifyListeners();
  }

  int get count => _rows.length;

  Set<FilterSetRow> get all => Set.unmodifiable(_rows);

  Future<void> setRows(Set<FilterSetRow> newRows) async {

    await removeEntries(newRows);
    for (var row in newRows) {
      await set(
        filterSetId: row.filterSetId,
        filterSetNum: row.filterSetNum,
        aliasName: row.aliasName,
        filters: row.filters,
      );
    }
    notifyListeners();
  }

  Future<void> set({
    required int filterSetId,
    required int filterSetNum,
    required String aliasName,
    required Set<CollectionFilter>? filters,
  }) async {
    // erase contextual properties from filters before saving them
    final oldRows = _rows.where((row) => row.filterSetId == filterSetId).toSet();
    _rows.removeAll(oldRows);
    await metadataDb.removeFilterSet(oldRows);

    final row = FilterSetRow(
      filterSetId: filterSetId,
      filterSetNum: filterSetNum,
      aliasName: aliasName,
      filters: filters,
    );
    _rows.add(row);
    await metadataDb.addFilterSet({row});
  }

  Future<void> removeEntries(Set<FilterSetRow> rows) => removeIds(rows.map((row) => row.filterSetId).toSet());

  Future<void> removeIds(Set<int> rowIds) async {
    final removedRows = _rows.where((row) => rowIds.contains(row.filterSetId)).toSet();

    await metadataDb.removeFilterSet(removedRows);
    removedRows.forEach(_rows.remove);

    notifyListeners();
  }


  Future<void> clear() async {
    await metadataDb.clearFilterSet();
    _rows.clear();
  }
   // import/export
}

@immutable
class FilterSetRow extends Equatable implements Comparable<FilterSetRow> {
  final int filterSetId;
  final int filterSetNum;
  final String aliasName;
  final Set<CollectionFilter>? filters;

  @override
  List<Object?> get props => [filterSetId, filterSetNum, aliasName, filters,];

  const FilterSetRow({
    required this.filterSetId,
    required this.filterSetNum,
    required this.aliasName,
    required this.filters,
  });

  static FilterSetRow fromMap(Map map) {
    final List<dynamic> decodedFilters = jsonDecode(map['filters']);
    final filters = decodedFilters.map((e) => CollectionFilter.fromJson(e as String)).whereNotNull().toSet();

    return FilterSetRow(
      filterSetId:map['id'] as int,
      filterSetNum:map['filterSetNum'] as int,
      aliasName: map['aliasName'] as String,
      filters: filters,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': filterSetId,
        'filterSetNum': filterSetNum,
        'aliasName': aliasName,
        'filters': jsonEncode(filters?.map((filter) => filter.toJson()).toList()),
  };

  @override
  int compareTo(FilterSetRow other) {
    // If sort by filterSetNum
    final filterSetNumComparison = filterSetNum.compareTo(other.filterSetNum);
    if (filterSetNumComparison != 0) {
      return filterSetNumComparison;
    }

    // If filterSetNum is the same, sort by aliasName
    final aliasNameComparison = aliasName.compareTo(other.aliasName);
    if (aliasNameComparison != 0) {
      return aliasNameComparison;
    }

    // If aliasName is the same, sort by filterSetId
    return filterSetId.compareTo(other.filterSetId);
  }
}
