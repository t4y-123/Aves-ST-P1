import 'package:aves/model/settings/settings.dart';
import 'package:collection/collection.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

import '../../services/common/services.dart';
import '../entry/entry.dart';

final ShareCopiedEntries shareCopiedEntries = ShareCopiedEntries._private();

class ShareCopiedEntries with ChangeNotifier {
  Set<ShareCopiedEntryRow> _rows = {};

  ShareCopiedEntries._private();

  Future<void> init() async {
    //_rows.clear();
    _rows = await localMediaDb.loadAllShareCopiedEntries();
    //debugPrint('$runtimeType ShareCopiedEntries init _rows'
    //     '[$_rows]  start');
  }

  Future<void> refresh() async {
    _rows.clear();
    await init();
  }

  int get count => _rows.length;

  Set<int> get all => Set.unmodifiable(_rows.map((v) => v.id));

  bool isShareCopied(AvesEntry entry) => _rows.any((row) => row.id == entry.id);

  bool isExpiredCopied(AvesEntry entry) {
    //debugPrint('[$entry] isExpiredCopied start');
    if (!isShareCopied(entry)) return false;
    return isExpiredCopiedId(entry.id, Duration(seconds: settings.shareByCopyRemoveInterval));
  }

  bool isExpiredRecord(int id) {
    //debugPrint('[$entry] isExpiredCopied start');
    return isExpiredCopiedId(id, Duration(days: settings.shareByCopyObsoleteRecordRemoveInterval));
  }

  bool isExpiredCopiedId(int entryId, Duration duration) {
    //debugPrint('[$entryId] isExpiredCopied start');
    final dateMillis = _rows.firstWhereOrNull((row) => row.id == entryId)?.dateMillis;
    if (dateMillis == null) return false;
    final result = DateTime.fromMillisecondsSinceEpoch(dateMillis).add(duration).isBefore(DateTime.now());
    // debugPrint('$runtimeType [$entryId] isExpiredCopied dateMillis $dateMillis'
    //     'dateMillis add ${settings.shareByCopyRemoveInterval} : $runtimeType '
    //     '${DateTime.fromMillisecondsSinceEpoch(dateMillis).add(Duration(seconds: settings.shareByCopyRemoveInterval))}'
    //     '(${DateTime.now()}'
    //     'result: $result');
    return result;
  }

  ShareCopiedEntryRow _entryToRow(AvesEntry entry) =>
      ShareCopiedEntryRow(id: entry.id, dateMillis: DateTime.now().millisecondsSinceEpoch);

  Future<void> add(Set<AvesEntry> entries) async {
    //debugPrint('shareCopiedEntries.add(add:\n$entries');
    final newRows = entries.map(_entryToRow).toSet();
    //debugPrint('shareCopiedEntries.add(newRows:\n$newRows');
    await localMediaDb.addShareCopiedEntries(newRows);
    _rows.addAll(newRows);
    notifyListeners();
  }

  Future<void> removeEntryIds(Set<int> rowIds) async {
    //debugPrint('$runtimeType removeShareCopiedEntries ${_rows.length} removeEntryIds entries:\n[$_rows]\n[$rowIds]');
    final removedRows = _rows.where((row) => rowIds.contains(row.id)).toSet();
    await localMediaDb.removeShareCopiedEntries(removedRows);
    removedRows.forEach(_rows.remove);
    notifyListeners();
  }

  Future<void> removeEntries(Set<AvesEntry> entries) => removeIds(entries.map((entry) => entry.id).toSet());

  Future<void> removeIds(Set<int> entryIds) async {
    final removedRows = _rows.where((row) => entryIds.contains(row.id)).toSet();

    await localMediaDb.removeShareCopiedEntries(removedRows);
    removedRows.forEach(_rows.remove);

    notifyListeners();
  }

  Future<void> clear() async {
    await localMediaDb.clearShareCopiedEntries();
    _rows.clear();
    notifyListeners();
  }
}

@immutable
class ShareCopiedEntryRow extends Equatable {
  final int id;
  final int dateMillis;

  @override
  List<Object?> get props => [id, dateMillis];

  const ShareCopiedEntryRow({
    required this.id,
    required this.dateMillis,
  });

  ShareCopiedEntryRow copyWith({
    int? id,
  }) {
    return ShareCopiedEntryRow(
      id: id ?? this.id,
      dateMillis: dateMillis,
    );
  }

  factory ShareCopiedEntryRow.fromMap(Map map) {
    return ShareCopiedEntryRow(
      id: map['id'] as int,
      dateMillis: map['dateMillis'] as int,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'dateMillis': dateMillis,
      };
}
