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
    _rows = await metadataDb.loadAllShareCopiedEntries();
    debugPrint('$runtimeType ShareCopiedEntries init _rows'
        '[$_rows]  start');
  }

  int get count => _rows.length;

  Set<int> get all => Set.unmodifiable(_rows.map((v) => v.id));

  bool isShareCopied(AvesEntry entry) => _rows.any((row) => row.id == entry.id);

  bool isExpiredCopied(AvesEntry entry) {
    debugPrint('[$entry] isExpiredCopied start');
    if(!isShareCopied(entry))return false;
    final dateMillis = _rows.firstWhereOrNull((row) => row.id == entry.id)?.dateMillis;
    if (dateMillis == null) return false;
    debugPrint('$runtimeType [$entry] isExpiredCopied dateMillis $dateMillis');
    debugPrint('dateMillis add ${settings.shareByCopyRemoveInterval} : $runtimeType '
        '${DateTime.fromMillisecondsSinceEpoch(dateMillis).add(Duration(seconds: settings.shareByCopyRemoveInterval))}');
    debugPrint('(${DateTime.now()}');
    return DateTime.fromMillisecondsSinceEpoch(dateMillis).add(Duration(seconds: settings.shareByCopyRemoveInterval)).isBefore(DateTime.now());
  }

  ShareCopiedEntryRow _entryToRow(AvesEntry entry) => ShareCopiedEntryRow(id: entry.id, dateMillis:DateTime.now().millisecondsSinceEpoch);

  Future<void> add(Set<AvesEntry> entries) async {
    debugPrint('shareCopiedEntries.add(add:\n$entries');
    final newRows = entries.map(_entryToRow).toSet();
    debugPrint('shareCopiedEntries.add(newRows:\n$newRows');
    await metadataDb.addShareCopiedEntries(newRows);
    _rows.addAll(newRows);
    notifyListeners();
  }

  Future<void> removeEntryIds(Set<int> rowIds) async {
    debugPrint('$runtimeType removeShareCopiedEntries ${_rows.length} removeEntryIds entries:\n[$_rows]\n[$rowIds]');
    final removedRows = _rows.where((row) => rowIds.contains(row.id)).toSet();
    await metadataDb.removeShareCopiedEntries(removedRows);
    removedRows.forEach(_rows.remove);
    notifyListeners();

  }
  Future<void> removeEntries(Set<AvesEntry> entries) => removeIds(entries.map((entry) => entry.id).toSet());

  Future<void> removeIds(Set<int> entryIds) async {
    final removedRows = _rows.where((row) => entryIds.contains(row.id)).toSet();

    await metadataDb.removeShareCopiedEntries(removedRows);
    removedRows.forEach(_rows.remove);

    notifyListeners();
  }

  Future<void> clear() async {
    await metadataDb.clearShareCopiedEntries();
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
