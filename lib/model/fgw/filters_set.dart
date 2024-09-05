import 'dart:async';
import 'dart:convert';

import 'package:aves/model/filters/aspect_ratio.dart';
import 'package:aves/model/filters/filters.dart';
import 'package:aves/model/filters/mime.dart';
import 'package:aves/model/presentation/base_bridge_row.dart';
import 'package:aves/services/common/services.dart';
import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';

final FiltersSet filtersSets = FiltersSet._private();

class FiltersSet extends PresentationRows<FiltersSetRow> {
  FiltersSet._private();

  @override
  Future<Set<FiltersSetRow>> loadAllRows() async {
    return await metadataDb.loadAllFilterSet();
  }

  @override
  Future<void> addRowsToDb(Set<FiltersSetRow> newRows) async {
    await metadataDb.addFilterSet(newRows);
  }

  @override
  Future<void> removeRowsFromDb(Set<FiltersSetRow> removedRows) async {
    await metadataDb.removeFilterSet(removedRows);
  }

  @override
  Future<void> clearRowsInDb() async {
    await metadataDb.clearFilterSet();
  }

  FiltersSetRow newRow(
    int existActiveMaxLevelOffset, {
    String? labelName,
    Set<CollectionFilter>? filters,
    bool isActive = true,
    PresentationRowType type = PresentationRowType.all,
  }) {
    final targetSet = getAll(type);
    final relevantItems = isActive ? targetSet.where((item) => item.isActive).toList() : targetSet.toList();
    final maxFilterSetNum =
        relevantItems.isEmpty ? 0 : relevantItems.map((item) => item.orderNum).reduce((a, b) => a > b ? a : b);
    final newId = metadataDb.nextId;
    final filterSetSuqNum = maxFilterSetNum + existActiveMaxLevelOffset;
    return FiltersSetRow(
      id: newId,
      orderNum: filterSetSuqNum,
      labelName: labelName ?? 'F-$filterSetSuqNum-$newId',
      filters: filters ?? {MimeFilter.image, AspectRatioFilter.landscape.reverse()},
      isActive: isActive,
    );
  }

  @override
  FiltersSetRow importFromMap(Map<String, dynamic> attributes) {
    return FiltersSetRow.fromMap(attributes);
  }
}

@immutable
class FiltersSetRow extends PresentRow<FiltersSetRow> {
  final int orderNum;
  final Set<CollectionFilter>? filters;

  @override
  List<Object?> get props => [
        id,
        orderNum,
        labelName,
        filters,
        isActive,
      ];

  const FiltersSetRow({
    required super.id,
    required this.orderNum,
    required super.labelName,
    required this.filters,
    required super.isActive,
  });

  static FiltersSetRow fromMap(Map map) {
    final List<dynamic> decodedFilters = jsonDecode(map['filters']);
    final filters = decodedFilters.map((e) => CollectionFilter.fromJson(e as String)).whereNotNull().toSet();

    return FiltersSetRow(
      id: map['id'] as int,
      orderNum: map['orderNum'] as int,
      labelName: map['labelName'] as String,
      filters: filters,
      isActive: (map['isActive'] as int? ?? 0) != 0,
    );
  }

  @override
  Map<String, dynamic> toMap() => {
        'id': id,
        'orderNum': orderNum,
        'labelName': labelName,
        'filters': jsonEncode(filters?.map((filter) => filter.toJson()).toList()),
        'isActive': isActive ? 1 : 0,
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

  @override
  FiltersSetRow copyWith({
    int? id,
    int? orderNum,
    String? labelName,
    bool? isActive,
    Set<CollectionFilter>? filters,
  }) {
    return FiltersSetRow(
      id: id ?? this.id,
      orderNum: orderNum ?? this.orderNum,
      labelName: labelName ?? this.labelName,
      isActive: isActive ?? this.isActive,
      filters: filters ?? this.filters,
    );
  }
}
