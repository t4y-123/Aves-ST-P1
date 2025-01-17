import 'dart:io';

import 'package:aves/model/assign/assign_entries.dart';
import 'package:aves/model/assign/assign_record.dart';
import 'package:aves/model/covers.dart';
import 'package:aves/model/db/db.dart';
import 'package:aves/model/db/db_sqflite_upgrade.dart';
import 'package:aves/model/entry/entry.dart';
import 'package:aves/model/favourites.dart';
import 'package:aves/model/fgw/fgw_used_entry_record.dart';
import 'package:aves/model/fgw/filters_set.dart';
import 'package:aves/model/fgw/guard_level.dart';
import 'package:aves/model/fgw/share_copied_entry.dart';
import 'package:aves/model/fgw/wallpaper_schedule.dart';
import 'package:aves/model/filters/filters.dart';
import 'package:aves/model/metadata/address.dart';
import 'package:aves/model/metadata/catalog.dart';
import 'package:aves/model/metadata/trash.dart';
import 'package:aves/model/scenario/scenario.dart';
import 'package:aves/model/scenario/scenario_step.dart';
import 'package:aves/model/vaults/details.dart';
import 'package:aves/model/viewer/video_playback.dart';
import 'package:aves/services/common/services.dart';
import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

class SqfliteLocalMediaDb implements LocalMediaDb {
  late Database _db;

  Future<String> get path async => pContext.join(await getDatabasesPath(), 'metadata.db');

  static const entryTable = 'entry';
  static const dateTakenTable = 'dateTaken';
  static const metadataTable = 'metadata';
  static const addressTable = 'address';
  static const favouriteTable = 'favourites';
  static const coverTable = 'covers';
  static const vaultTable = 'vaults';
  static const trashTable = 'trash';
  static const videoPlaybackTable = 'videoPlayback';

  static const _queryCursorBufferSize = 1000;
  // t4y for foreground Wallpaper
  static const fgwGuardLevelTable = 'fgwGuardLevel';
  static const filtersSetTable = 'filtersSet';
  static const fgwScheduleTable = 'fgwSchedule';
  static const fgwUsedEntryTable = 'fgwUsedEntry';

  //t4y share by copy:
  static const shareCopiedEntryTable = 'shareCopiedEntry';

  // t4y: presentation: scenario presentation
  static const scenarioTable = 'scenarioPresent';
  static const scenarioStepTable = 'scenarioStep';
  static const assignRecordTable = 'assignRecord';
  static const assignEntryTable = 'assignEntry';
  //End

  static int _lastId = 0;
  // In dart ,the int is 64-bit.
  // The 64-bit signed integer records the number of ticks from a certain era to the present.
  // Some systems (such as the Java standard library) agree that 1 tick is equal to 1 millisecond.
  // This agreed time system can be used until about 292 million years later.
  // Other systems (such as Win32) agree that 1 tick is equal to 100 nanoseconds.
  // The time range covered by this system is 29227 years before and after the era.
  // https://zh.wikipedia.org/wiki/9223372036854775807
  @override
  int get nextId => ++_lastId;

  int _initTime = 0;
  @override
  int get nextDateId => _initTime + _lastId++;

  @override
  Future<void> init() async {
    _initTime = DateTime.now().millisecondsSinceEpoch;
    _db = await openDatabase(
      await path,
      onCreate: (db, version) async {
        await db.execute('CREATE TABLE $entryTable('
            'id INTEGER PRIMARY KEY'
            ', contentId INTEGER'
            ', uri TEXT'
            ', path TEXT UNIQUE'
            ', sourceMimeType TEXT'
            ', width INTEGER'
            ', height INTEGER'
            ', sourceRotationDegrees INTEGER'
            ', sizeBytes INTEGER'
            ', title TEXT'
            ', dateAddedSecs INTEGER DEFAULT (strftime(\'%s\',\'now\'))'
            ', dateModifiedSecs INTEGER'
            ', sourceDateTakenMillis INTEGER'
            ', durationMillis INTEGER'
            ', trashed INTEGER DEFAULT 0'
            ', origin INTEGER DEFAULT 0'
            ')');
        await db.execute('CREATE TABLE $dateTakenTable('
            'id INTEGER PRIMARY KEY'
            ', dateMillis INTEGER'
            ')');
        await db.execute('CREATE TABLE $metadataTable('
            'id INTEGER PRIMARY KEY'
            ', mimeType TEXT'
            ', dateMillis INTEGER'
            ', flags INTEGER'
            ', rotationDegrees INTEGER'
            ', xmpSubjects TEXT'
            ', xmpTitle TEXT'
            ', latitude REAL'
            ', longitude REAL'
            ', rating INTEGER'
            ')');
        await db.execute('CREATE TABLE $addressTable('
            'id INTEGER PRIMARY KEY'
            ', addressLine TEXT'
            ', countryCode TEXT'
            ', countryName TEXT'
            ', adminArea TEXT'
            ', locality TEXT'
            ')');
        await db.execute('CREATE TABLE $favouriteTable('
            'id INTEGER PRIMARY KEY'
            ')');
        await db.execute('CREATE TABLE $coverTable('
            'filter TEXT PRIMARY KEY'
            ', entryId INTEGER'
            ', packageName TEXT'
            ', color INTEGER'
            ')');
        await db.execute('CREATE TABLE $vaultTable('
            'name TEXT PRIMARY KEY'
            ', autoLock INTEGER'
            ', useBin INTEGER'
            ', lockType TEXT'
            ')');
        await db.execute('CREATE TABLE $trashTable('
            'id INTEGER PRIMARY KEY'
            ', path TEXT'
            ', dateMillis INTEGER'
            ')');
        await db.execute('CREATE TABLE $videoPlaybackTable('
            'id INTEGER PRIMARY KEY'
            ', resumeTimeMillis INTEGER'
            ')');
        //T4y: Foreground Wallpaper tables
        await db.execute('CREATE TABLE $fgwGuardLevelTable('
            'id INTEGER PRIMARY KEY'
            ', guardLevel INTEGER'
            ', labelName TEXT'
            ', color INTEGER'
            ', isActive INTEGER DEFAULT 0'
            ')');
        await db.execute('CREATE TABLE $filtersSetTable('
            'id INTEGER PRIMARY KEY'
            ', orderNum INTEGER'
            ', labelName TEXT'
            ', filters TEXT'
            ', isActive INTEGER DEFAULT 0'
            ')');
        await db.execute('CREATE TABLE $fgwScheduleTable('
            'id INTEGER PRIMARY KEY'
            ', orderNum INTEGER'
            ', labelName TEXT'
            ', fgwGuardLevelId INTEGER'
            ', filtersSetId INTEGER'
            ', updateType TEXT' // Values can be 'home', 'lock', or 'widget'
            ', widgetId INTEGER DEFAULT 0' // Default to 0 for 'home' or 'lock'
            ', displayType TEXT' // Values can be 'random'  or 'most recent not used'
            ', interval INTEGER DEFAULT 0' // 0 will be update when the phone is locked
            ', isActive INTEGER DEFAULT 0'
            ')');
        await db.execute('CREATE TABLE $fgwUsedEntryTable('
            'id INTEGER PRIMARY KEY'
            ', fgwGuardLevelId INTEGER'
            ', updateType TEXT' // Values can be 'home', 'lock', or 'widget'
            ', widgetId INTEGER DEFAULT 0' // Default to 0 for 'home' or 'lock'
            ', entryId INTEGER'
            ', dateMillis INTEGER'
            ')');
        await db.execute('CREATE TABLE $shareCopiedEntryTable('
            'id INTEGER PRIMARY KEY'
            ', dateMillis INTEGER'
            ')');
        //T4y: Scenario Presentation
        await db.execute('CREATE TABLE $scenarioTable('
            'id INTEGER PRIMARY KEY'
            ', orderNum INTEGER'
            ', labelName TEXT'
            ', loadType TEXT'
            ', color INTEGER'
            ', dateMillis INTEGER'
            ', isActive INTEGER DEFAULT 0'
            ')');
        await db.execute('CREATE TABLE $scenarioStepTable('
            'id INTEGER PRIMARY KEY'
            ', scenarioId INTEGER'
            ', stepNum INTEGER'
            ', orderNum INTEGER'
            ', labelName TEXT'
            ', loadType TEXT'
            ', filters TEXT'
            ', dateMillis INTEGER'
            ', isActive INTEGER DEFAULT 0'
            ')');
        //T4y: Assign entries Presentation
        await db.execute('CREATE TABLE $assignRecordTable('
            'id INTEGER PRIMARY KEY'
            ', orderNum INTEGER'
            ', labelName TEXT'
            ', assignType TEXT'
            ', color INTEGER'
            ', dateMillis INTEGER'
            ', scenarioId INTEGER DEFAULT 0'
            ', isActive INTEGER DEFAULT 0'
            ')');
        await db.execute('CREATE TABLE $assignEntryTable('
            'id INTEGER PRIMARY KEY'
            ', assignId INTEGER'
            ', entryId INTEGER'
            ', dateMillis INTEGER'
            ', orderNum INTEGER'
            ', labelName TEXT'
            ', isActive INTEGER DEFAULT 0'
            ')');
      },
      onUpgrade: LocalMediaDbUpgrader.upgradeDb,
      version: 11,
    );

    final maxIdRows = await _db.rawQuery('SELECT MAX(id) AS maxId FROM $entryTable');
    _lastId = (maxIdRows.firstOrNull?['maxId'] as int?) ?? 0;
  }

  @override
  Future<int> dbFileSize() async {
    final file = File(await path);
    return await file.exists() ? await file.length() : 0;
  }

  @override
  Future<void> reset() async {
    debugPrint('$runtimeType reset');
    await _db.close();
    await deleteDatabase(await path);
    await init();
  }

  @override
  Future<void> removeIds(Set<int> ids, {Set<EntryDataType>? dataTypes}) async {
    if (ids.isEmpty) return;

    final _dataTypes = dataTypes ?? EntryDataType.values.toSet();

    // using array in `whereArgs` and using it with `where id IN ?` is a pain, so we prefer `batch` instead
    final batch = _db.batch();
    const where = 'id = ?';
    const coverWhere = 'entryId = ?';
    ids.forEach((id) {
      final whereArgs = [id];
      if (_dataTypes.contains(EntryDataType.basic)) {
        batch.delete(entryTable, where: where, whereArgs: whereArgs);
      }
      if (_dataTypes.contains(EntryDataType.catalog)) {
        batch.delete(dateTakenTable, where: where, whereArgs: whereArgs);
        batch.delete(metadataTable, where: where, whereArgs: whereArgs);
      }
      if (_dataTypes.contains(EntryDataType.address)) {
        batch.delete(addressTable, where: where, whereArgs: whereArgs);
      }
      if (_dataTypes.contains(EntryDataType.references)) {
        batch.delete(favouriteTable, where: where, whereArgs: whereArgs);
        batch.delete(coverTable, where: coverWhere, whereArgs: whereArgs);
        batch.delete(trashTable, where: where, whereArgs: whereArgs);
        batch.delete(videoPlaybackTable, where: where, whereArgs: whereArgs);
      }
    });
    await batch.commit(noResult: true);
  }

  // entries

  @override
  Future<void> clearEntries() async {
    final count = await _db.delete(entryTable, where: '1');
    debugPrint('$runtimeType clearEntries deleted $count rows');
  }

  @override
  Future<Set<AvesEntry>> loadEntries({int? origin, String? directory}) async {
    String? where;
    final whereArgs = <Object?>[];

    if (origin != null) {
      where = 'origin = ?';
      whereArgs.add(origin);
    }

    final entries = <AvesEntry>{};
    if (directory != null) {
      final separator = pContext.separator;
      if (!directory.endsWith(separator)) {
        directory = '$directory$separator';
      }

      where = '${where != null ? '$where AND ' : ''}path LIKE ?';
      whereArgs.add('$directory%');
      final cursor = await _db.queryCursor(entryTable, where: where, whereArgs: whereArgs, bufferSize: _queryCursorBufferSize);

      final dirLength = directory.length;
      while (await cursor.moveNext()) {
        final row = cursor.current;
        // skip entries in subfolders
        final path = row['path'] as String?;
        if (path != null && !path.substring(dirLength).contains(separator)) {
          entries.add(AvesEntry.fromMap(row));
        }
      }
    } else {
      final cursor = await _db.queryCursor(entryTable, where: where, whereArgs: whereArgs, bufferSize: _queryCursorBufferSize);
      while (await cursor.moveNext()) {
        entries.add(AvesEntry.fromMap(cursor.current));
      }
    }

    return entries;
  }

  @override
  Future<Set<AvesEntry>> loadEntriesById(Set<int> ids) => _getByIds(ids, entryTable, AvesEntry.fromMap);

  @override
  Future<void> insertEntries(Set<AvesEntry> entries) async {
    if (entries.isEmpty) return;
    final stopwatch = Stopwatch()..start();
    final batch = _db.batch();
    entries.forEach((entry) => _batchInsertEntry(batch, entry));
    await batch.commit(noResult: true);
    debugPrint('$runtimeType saveEntries complete in ${stopwatch.elapsed.inMilliseconds}ms for ${entries.length} entries');
  }

  @override
  Future<void> updateEntry(int id, AvesEntry entry) async {
    final batch = _db.batch();
    batch.delete(entryTable, where: 'id = ?', whereArgs: [id]);
    _batchInsertEntry(batch, entry);
    await batch.commit(noResult: true);
  }

  void _batchInsertEntry(Batch batch, AvesEntry entry) {
    batch.insert(
      entryTable,
      entry.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<Set<AvesEntry>> searchLiveEntries(String query, {int? limit}) async {
    final rows = await _db.query(
      entryTable,
      where: '(title LIKE ? OR path LIKE ?) AND trashed = ?',
      whereArgs: ['%$query%', '%$query%', 0],
      orderBy: 'sourceDateTakenMillis DESC',
      limit: limit,
    );
    return rows.map(AvesEntry.fromMap).toSet();
  }

  @override
  Future<Set<AvesEntry>> searchLiveDuplicates(int origin, Set<AvesEntry>? entries) async {
    String where = 'origin = ? AND trashed = ?';
    if (entries != null) {
      where += ' AND contentId IN (${entries.map((v) => v.contentId).join(',')})';
    }
    final rows = await _db.rawQuery(
      'SELECT *, MAX(id) AS id'
      ' FROM $entryTable'
      ' WHERE $where'
      ' GROUP BY contentId'
      ' HAVING COUNT(id) > 1',
      [origin, 0],
    );
    final duplicates = rows.map(AvesEntry.fromMap).toSet();
    if (duplicates.isNotEmpty) {
      debugPrint('Found duplicates=$duplicates');
    }
    // return most recent duplicate for each duplicated content ID
    return duplicates;
  }

  // date taken

  @override
  Future<void> clearDates() async {
    final count = await _db.delete(dateTakenTable, where: '1');
    debugPrint('$runtimeType clearDates deleted $count rows');
  }

  @override
  Future<Map<int?, int?>> loadDates() async {
    final result = <int?, int?>{};
    final cursor = await _db.queryCursor(dateTakenTable, bufferSize: _queryCursorBufferSize);
    while (await cursor.moveNext()) {
      final row = cursor.current;
      result[row['id'] as int] = row['dateMillis'] as int? ?? 0;
    }
    return result;
  }

  // catalog metadata

  @override
  Future<void> clearCatalogMetadata() async {
    final count = await _db.delete(metadataTable, where: '1');
    debugPrint('$runtimeType clearMetadataEntries deleted $count rows');
  }

  @override
  Future<Set<CatalogMetadata>> loadCatalogMetadata() async {
    final result = <CatalogMetadata>{};
    final cursor = await _db.queryCursor(metadataTable, bufferSize: _queryCursorBufferSize);
    while (await cursor.moveNext()) {
      result.add(CatalogMetadata.fromMap(cursor.current));
    }
    return result;
  }

  @override
  Future<Set<CatalogMetadata>> loadCatalogMetadataById(Set<int> ids) => _getByIds(ids, metadataTable, CatalogMetadata.fromMap);

  @override
  Future<void> saveCatalogMetadata(Set<CatalogMetadata> metadataEntries) async {
    if (metadataEntries.isEmpty) return;
    final stopwatch = Stopwatch()..start();
    try {
      final batch = _db.batch();
      metadataEntries.forEach((metadata) => _batchInsertMetadata(batch, metadata));
      await batch.commit(noResult: true);
      debugPrint('$runtimeType saveMetadata complete in ${stopwatch.elapsed.inMilliseconds}ms for ${metadataEntries.length} entries');
    } catch (error, stack) {
      debugPrint('$runtimeType failed to save metadata with error=$error\n$stack');
    }
  }

  @override
  Future<void> updateCatalogMetadata(int id, CatalogMetadata? metadata) async {
    final batch = _db.batch();
    batch.delete(dateTakenTable, where: 'id = ?', whereArgs: [id]);
    batch.delete(metadataTable, where: 'id = ?', whereArgs: [id]);
    _batchInsertMetadata(batch, metadata);
    await batch.commit(noResult: true);
  }

  void _batchInsertMetadata(Batch batch, CatalogMetadata? metadata) {
    if (metadata == null) return;
    if (metadata.dateMillis != 0) {
      batch.insert(
        dateTakenTable,
        {
          'id': metadata.id,
          'dateMillis': metadata.dateMillis,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    batch.insert(
      metadataTable,
      metadata.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // address

  @override
  Future<void> clearAddresses() async {
    final count = await _db.delete(addressTable, where: '1');
    debugPrint('$runtimeType clearAddresses deleted $count rows');
  }

  @override
  Future<Set<AddressDetails>> loadAddresses() async {
    final result = <AddressDetails>{};
    final cursor = await _db.queryCursor(addressTable, bufferSize: _queryCursorBufferSize);
    while (await cursor.moveNext()) {
      result.add(AddressDetails.fromMap(cursor.current));
    }
    return result;
  }

  @override
  Future<Set<AddressDetails>> loadAddressesById(Set<int> ids) => _getByIds(ids, addressTable, AddressDetails.fromMap);

  @override
  Future<void> saveAddresses(Set<AddressDetails> addresses) async {
    if (addresses.isEmpty) return;
    final stopwatch = Stopwatch()..start();
    final batch = _db.batch();
    addresses.forEach((address) => _batchInsertAddress(batch, address));
    await batch.commit(noResult: true);
    debugPrint('$runtimeType saveAddresses complete in ${stopwatch.elapsed.inMilliseconds}ms for ${addresses.length} entries');
  }

  @override
  Future<void> updateAddress(int id, AddressDetails? address) async {
    final batch = _db.batch();
    batch.delete(addressTable, where: 'id = ?', whereArgs: [id]);
    _batchInsertAddress(batch, address);
    await batch.commit(noResult: true);
  }

  void _batchInsertAddress(Batch batch, AddressDetails? address) {
    if (address == null) return;
    batch.insert(
      addressTable,
      address.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // vaults

  @override
  Future<void> clearVaults() async {
    final count = await _db.delete(vaultTable, where: '1');
    debugPrint('$runtimeType clearVaults deleted $count rows');
  }

  @override
  Future<Set<VaultDetails>> loadAllVaults() async {
    final result = <VaultDetails>{};
    final cursor = await _db.queryCursor(vaultTable, bufferSize: _queryCursorBufferSize);
    while (await cursor.moveNext()) {
      result.add(VaultDetails.fromMap(cursor.current));
    }
    return result;
  }

  @override
  Future<void> addVaults(Set<VaultDetails> rows) async {
    if (rows.isEmpty) return;
    final batch = _db.batch();
    rows.forEach((row) => _batchInsertVault(batch, row));
    await batch.commit(noResult: true);
  }

  @override
  Future<void> updateVault(String oldName, VaultDetails row) async {
    final batch = _db.batch();
    batch.delete(vaultTable, where: 'name = ?', whereArgs: [oldName]);
    _batchInsertVault(batch, row);
    await batch.commit(noResult: true);
  }

  void _batchInsertVault(Batch batch, VaultDetails row) {
    batch.insert(
      vaultTable,
      row.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> removeVaults(Set<VaultDetails> rows) async {
    if (rows.isEmpty) return;

    // using array in `whereArgs` and using it with `where id IN ?` is a pain, so we prefer `batch` instead
    final batch = _db.batch();
    rows.map((v) => v.name).forEach((name) => batch.delete(vaultTable, where: 'name = ?', whereArgs: [name]));
    await batch.commit(noResult: true);
  }

  // trash

  @override
  Future<void> clearTrashDetails() async {
    final count = await _db.delete(trashTable, where: '1');
    debugPrint('$runtimeType clearTrashDetails deleted $count rows');
  }

  @override
  Future<Set<TrashDetails>> loadAllTrashDetails() async {
    final result = <TrashDetails>{};
    final cursor = await _db.queryCursor(trashTable, bufferSize: _queryCursorBufferSize);
    while (await cursor.moveNext()) {
      result.add(TrashDetails.fromMap(cursor.current));
    }
    return result;
  }

  @override
  Future<void> updateTrash(int id, TrashDetails? details) async {
    final batch = _db.batch();
    batch.delete(trashTable, where: 'id = ?', whereArgs: [id]);
    _batchInsertTrashDetails(batch, details);
    await batch.commit(noResult: true);
  }

  void _batchInsertTrashDetails(Batch batch, TrashDetails? details) {
    if (details == null) return;
    batch.insert(
      trashTable,
      details.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // favourites

  @override
  Future<void> clearFavourites() async {
    final count = await _db.delete(favouriteTable, where: '1');
    debugPrint('$runtimeType clearFavourites deleted $count rows');
  }

  @override
  Future<Set<FavouriteRow>> loadAllFavourites() async {
    final result = <FavouriteRow>{};
    final cursor = await _db.queryCursor(favouriteTable, bufferSize: _queryCursorBufferSize);
    while (await cursor.moveNext()) {
      result.add(FavouriteRow.fromMap(cursor.current));
    }
    return result;
  }

  @override
  Future<void> addFavourites(Set<FavouriteRow> rows) async {
    if (rows.isEmpty) return;
    final batch = _db.batch();
    rows.forEach((row) => _batchInsertFavourite(batch, row));
    await batch.commit(noResult: true);
  }

  @override
  Future<void> updateFavouriteId(int id, FavouriteRow row) async {
    final batch = _db.batch();
    batch.delete(favouriteTable, where: 'id = ?', whereArgs: [id]);
    _batchInsertFavourite(batch, row);
    await batch.commit(noResult: true);
  }

  void _batchInsertFavourite(Batch batch, FavouriteRow row) {
    batch.insert(
      favouriteTable,
      row.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> removeFavourites(Set<FavouriteRow> rows) async {
    if (rows.isEmpty) return;
    final ids = rows.map((row) => row.entryId);
    if (ids.isEmpty) return;

    // using array in `whereArgs` and using it with `where id IN ?` is a pain, so we prefer `batch` instead
    final batch = _db.batch();
    ids.forEach((id) => batch.delete(favouriteTable, where: 'id = ?', whereArgs: [id]));
    await batch.commit(noResult: true);
  }

  // covers

  @override
  Future<void> clearCovers() async {
    final count = await _db.delete(coverTable, where: '1');
    debugPrint('$runtimeType clearCovers deleted $count rows');
  }

  @override
  Future<Set<CoverRow>> loadAllCovers() async {
    final result = <CoverRow>{};
    final cursor = await _db.queryCursor(coverTable, bufferSize: _queryCursorBufferSize);
    while (await cursor.moveNext()) {
      final row = CoverRow.fromMap(cursor.current);
      if (row != null) {
        result.add(row);
      }
    }
    return result;
  }

  @override
  Future<void> addCovers(Set<CoverRow> rows) async {
    if (rows.isEmpty) return;

    final batch = _db.batch();
    rows.forEach((row) => _batchInsertCover(batch, row));
    await batch.commit(noResult: true);
  }

  @override
  Future<void> updateCoverEntryId(int id, CoverRow row) async {
    final batch = _db.batch();
    batch.delete(coverTable, where: 'entryId = ?', whereArgs: [id]);
    _batchInsertCover(batch, row);
    await batch.commit(noResult: true);
  }

  void _batchInsertCover(Batch batch, CoverRow row) {
    batch.insert(
      coverTable,
      row.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> removeCovers(Set<CollectionFilter> filters) async {
    if (filters.isEmpty) return;

    // for backward compatibility, remove stored JSON instead of removing de/reserialized filters
    final obsoleteFilterJson = <String>{};

    final rows = await _db.query(coverTable);
    rows.forEach((row) {
      final filterJson = row['filter'] as String?;
      if (filterJson != null) {
        final filter = CollectionFilter.fromJson(filterJson);
        if (filters.any((v) => filter == v)) {
          obsoleteFilterJson.add(filterJson);
        }
      }
    });

    // using array in `whereArgs` and using it with `where filter IN ?` is a pain, so we prefer `batch` instead
    final batch = _db.batch();
    obsoleteFilterJson.forEach((filterJson) => batch.delete(coverTable, where: 'filter = ?', whereArgs: [filterJson]));
    await batch.commit(noResult: true);
  }

  // video playback

  @override
  Future<void> clearVideoPlayback() async {
    final count = await _db.delete(videoPlaybackTable, where: '1');
    debugPrint('$runtimeType clearVideoPlayback deleted $count rows');
  }

  @override
  Future<Set<VideoPlaybackRow>> loadAllVideoPlayback() async {
    final result = <VideoPlaybackRow>{};
    final cursor = await _db.queryCursor(videoPlaybackTable, bufferSize: _queryCursorBufferSize);
    while (await cursor.moveNext()) {
      final row = VideoPlaybackRow.fromMap(cursor.current);
      if (row != null) {
        result.add(row);
      }
    }
    return result;
  }

  @override
  Future<VideoPlaybackRow?> loadVideoPlayback(int id) async {
    final rows = await _db.query(videoPlaybackTable, where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;

    return VideoPlaybackRow.fromMap(rows.first);
  }

  @override
  Future<void> addVideoPlayback(Set<VideoPlaybackRow> rows) async {
    if (rows.isEmpty) return;

    final batch = _db.batch();
    rows.forEach((row) => _batchInsertVideoPlayback(batch, row));
    await batch.commit(noResult: true);
  }

  void _batchInsertVideoPlayback(Batch batch, VideoPlaybackRow row) {
    batch.insert(
      videoPlaybackTable,
      row.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> removeVideoPlayback(Set<int> ids) async {
    if (ids.isEmpty) return;

    // using array in `whereArgs` and using it with `where filter IN ?` is a pain, so we prefer `batch` instead
    final batch = _db.batch();
    ids.forEach((id) => batch.delete(videoPlaybackTable, where: 'id = ?', whereArgs: [id]));
    await batch.commit(noResult: true);
  }

  // convenience methods

  Future<Set<T>> _getByIds<T>(Set<int> ids, String table, T Function(Map<String, Object?> row) mapRow) async {
    final result = <T>{};
    if (ids.isNotEmpty) {
      final cursor = await _db.queryCursor(table, where: 'id IN (${ids.join(',')})', bufferSize: _queryCursorBufferSize);
      while (await cursor.moveNext()) {
        result.add(mapRow(cursor.current));
      }
    }
    return result;
  }

  // t4y part:
  // Privacy Guard LevelS
  @override
  Future<void> clearFgwGuardLevel() async {
    final count = await _db.delete(fgwGuardLevelTable, where: '1');
    debugPrint('clearFgwGuardLevel deleted $count rows');
  }

  @override
  Future<Set<FgwGuardLevelRow>> loadAllFgwGuardLevels() async {
    final rows = await _db.query(fgwGuardLevelTable);
    return rows.map(FgwGuardLevelRow.fromMap).where((row) => row != null).toSet();
  }

  @override
  Future<void> addFgwGuardLevels(Set<FgwGuardLevelRow> rows) async {
    if (rows.isEmpty) return;

    final batch = _db.batch();
    rows.forEach((row) => _batchInsertFgwGuardLevel(batch, row));
    await batch.commit(noResult: true);
  }

  @override
  Future<void> updateFgwGuardLevelId(int id, FgwGuardLevelRow row) async {
    final batch = _db.batch();
    batch.delete(fgwGuardLevelTable, where: 'id = ?', whereArgs: [id]);
    _batchInsertFgwGuardLevel(batch, row);
    await batch.commit(noResult: true);
  }

  @override
  Future<void> removeFgwGuardLevels(Set<FgwGuardLevelRow> rows) async {
    if (rows.isEmpty) return;

    final batch = _db.batch();
    rows.forEach((row) {
      batch.delete(fgwGuardLevelTable, where: 'id = ?', whereArgs: [row.id]);
    });
    await batch.commit(noResult: true);
  }

  void _batchInsertFgwGuardLevel(Batch batch, FgwGuardLevelRow row) {
    batch.insert(
      fgwGuardLevelTable,
      row.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Filter Set for wallpaper,
  @override
  Future<void> clearFilterSet() async {
    final count = await _db.delete(filtersSetTable, where: '1');
    debugPrint('clearFilterSet deleted $count rows');
  }

  @override
  Future<Set<FiltersSetRow>> loadAllFilterSet() async {
    final rows = await _db.query(filtersSetTable);
    return rows.map(FiltersSetRow.fromMap).where((row) => row != null).toSet();
  }

  @override
  Future<void> addFilterSet(Set<FiltersSetRow> rows) async {
    if (rows.isEmpty) return;

    final batch = _db.batch();
    rows.forEach((row) => _batchInsertFilterSet(batch, row));
    await batch.commit(noResult: true);
  }

  @override
  Future<void> updateFilterSetId(int id, FiltersSetRow row) async {
    final batch = _db.batch();
    batch.delete(filtersSetTable, where: 'id = ?', whereArgs: [id]);
    _batchInsertFilterSet(batch, row);
    await batch.commit(noResult: true);
  }

  @override
  Future<void> removeFilterSet(Set<FiltersSetRow> rows) async {
    if (rows.isEmpty) return;

    final batch = _db.batch();
    rows.forEach((row) {
      batch.delete(filtersSetTable, where: 'id = ?', whereArgs: [row.id]);
    });
    await batch.commit(noResult: true);
  }

  void _batchInsertFilterSet(Batch batch, FiltersSetRow row) {
    batch.insert(
      filtersSetTable,
      row.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // wallpaper Schedule Table
  @override
  Future<void> clearFgwSchedules() async {
    final count = await _db.delete(fgwScheduleTable, where: '1');
    debugPrint('clearFilterSet deleted $count rows');
  }

  @override
  Future<Set<FgwScheduleRow>> loadAllFgwSchedules() async {
    final rows = await _db.query(fgwScheduleTable);
    return rows.map(FgwScheduleRow.fromMap).where((row) => row != null).toSet();
  }

  @override
  Future<void> addFgwSchedules(Set<FgwScheduleRow> rows) async {
    if (rows.isEmpty) return;
    final batch = _db.batch();
    rows.forEach((row) => _batchInsertWallpaperSchedule(batch, row));
    await batch.commit(noResult: true);
  }

  @override
  Future<void> updateFgwSchedules(int id, FgwScheduleRow row) async {
    final batch = _db.batch();
    batch.delete(fgwScheduleTable, where: 'id = ?', whereArgs: [id]);
    _batchInsertWallpaperSchedule(batch, row);
    await batch.commit(noResult: true);
  }

  @override
  Future<void> removeFgwSchedules(Set<FgwScheduleRow> rows) async {
    if (rows.isEmpty) return;

    final batch = _db.batch();
    rows.forEach((row) {
      batch.delete(fgwScheduleTable, where: 'id = ?', whereArgs: [row.id]);
    });
    await batch.commit(noResult: true);
  }

  void _batchInsertWallpaperSchedule(Batch batch, FgwScheduleRow row) {
    batch.insert(
      fgwScheduleTable,
      row.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // foreground wallpaper used entry record Table
  @override
  Future<void> clearFgwUsedEntryRecord() async {
    final count = await _db.delete(fgwUsedEntryTable, where: '1');
    debugPrint('clearFilterSet deleted $count rows');
  }

  @override
  Future<Set<FgwUsedEntryRecordRow>> loadAllFgwUsedEntryRecord() async {
    final rows = await _db.query(fgwUsedEntryTable);
    return rows.map(FgwUsedEntryRecordRow.fromMap).where((row) => row != null).toSet();
  }

  @override
  Future<void> addFgwUsedEntryRecord(Set<FgwUsedEntryRecordRow> rows) async {
    if (rows.isEmpty) return;
    final batch = _db.batch();
    rows.forEach((row) => _batchInsertFgwUsedEntryRecord(batch, row));
    await batch.commit(noResult: true);
  }

  @override
  Future<void> updateFgwUsedEntryRecord(int id, FgwUsedEntryRecordRow row) async {
    final batch = _db.batch();
    batch.delete(fgwUsedEntryTable, where: 'id = ?', whereArgs: [id]);
    _batchInsertFgwUsedEntryRecord(batch, row);
    await batch.commit(noResult: true);
  }

  @override
  Future<void> removeFgwUsedEntryRecord(Set<FgwUsedEntryRecordRow> rows) async {
    if (rows.isEmpty) return;

    final batch = _db.batch();
    rows.forEach((row) {
      batch.delete(fgwUsedEntryTable, where: 'id = ?', whereArgs: [row.id]);
    });
    await batch.commit(noResult: true);
  }

  void _batchInsertFgwUsedEntryRecord(Batch batch, FgwUsedEntryRecordRow row) {
    batch.insert(
      fgwUsedEntryTable,
      row.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  //t4y: share by copy copied entries
  @override
  Future<void> clearShareCopiedEntries() async {
    final count = await _db.delete(shareCopiedEntryTable, where: '1');
    debugPrint('clearShareCopiedEntries $shareCopiedEntryTable deleted $count rows');
  }

  @override
  Future<Set<ShareCopiedEntryRow>> loadAllShareCopiedEntries() async {
    final rows = await _db.query(shareCopiedEntryTable);
    return rows.map(ShareCopiedEntryRow.fromMap).where((row) => row != null).toSet();
  }

  @override
  Future<void> addShareCopiedEntries(Set<ShareCopiedEntryRow> rows) async {
    //debugPrint('addShareCopiedEntries.add(_db:\n$rows');
    if (rows.isEmpty) return;
    final batch = _db.batch();
    rows.forEach((row) => _batchInsertShareCopiedEntries(batch, row));
    await batch.commit(noResult: true);
  }

  @override
  Future<void> updateShareCopiedEntries(int id, ShareCopiedEntryRow row) async {
    final batch = _db.batch();
    batch.delete(shareCopiedEntryTable, where: 'id = ?', whereArgs: [id]);
    _batchInsertShareCopiedEntries(batch, row);
    await batch.commit(noResult: true);
  }

  @override
  Future<void> removeShareCopiedEntries(Set<ShareCopiedEntryRow> rows) async {
    if (rows.isEmpty) return;

    final batch = _db.batch();
    rows.forEach((row) {
      batch.delete(shareCopiedEntryTable, where: 'id = ?', whereArgs: [row.id]);
    });
    await batch.commit(noResult: true);
  }

  void _batchInsertShareCopiedEntries(Batch batch, ShareCopiedEntryRow row) {
    //debugPrint('addShareCopiedEntries.add(_batchInsertShareCopiedEntries:\n$batch \n $row');
    batch.insert(
      shareCopiedEntryTable,
      row.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Scenario
  @override
  Future<void> clearScenarios() async {
    final count = await _db.delete(scenarioTable, where: '1');
    debugPrint('clearScenarios deleted $count rows');
  }

  @override
  Future<Set<ScenarioRow>> loadAllScenarios() async {
    final rows = await _db.query(scenarioTable);
    return rows.map(ScenarioRow.fromMap).where((row) => row != null).toSet();
  }

  @override
  Future<void> addScenarios(Set<ScenarioRow> rows) async {
    if (rows.isEmpty) return;

    final batch = _db.batch();
    rows.forEach((row) => _batchInsertScenarios(batch, row));
    await batch.commit(noResult: true);
  }

  @override
  Future<void> updateScenarioById(int id, ScenarioRow row) async {
    final batch = _db.batch();
    batch.delete(scenarioTable, where: 'id = ?', whereArgs: [id]);
    _batchInsertScenarios(batch, row);
    await batch.commit(noResult: true);
  }

  @override
  Future<void> removeScenarios(Set<ScenarioRow> rows) async {
    if (rows.isEmpty) return;

    final batch = _db.batch();
    rows.forEach((row) {
      batch.delete(scenarioTable, where: 'id = ?', whereArgs: [row.id]);
    });
    await batch.commit(noResult: true);
  }

  void _batchInsertScenarios(Batch batch, ScenarioRow row) {
    batch.insert(
      scenarioTable,
      row.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Scenario step
  @override
  Future<void> clearScenarioSteps() async {
    final count = await _db.delete(scenarioStepTable, where: '1');
    debugPrint('clearScenarioSteps deleted $count rows');
  }

  @override
  Future<Set<ScenarioStepRow>> loadAllScenarioSteps() async {
    final rows = await _db.query(scenarioStepTable);
    return rows.map(ScenarioStepRow.fromMap).where((row) => row != null).toSet();
  }

  @override
  Future<void> addScenarioSteps(Set<ScenarioStepRow> rows) async {
    if (rows.isEmpty) return;

    final batch = _db.batch();
    rows.forEach((row) => _batchInsertScenarioSteps(batch, row));
    await batch.commit(noResult: true);
  }

  @override
  Future<void> updateScenarioStepById(int id, ScenarioStepRow row) async {
    final batch = _db.batch();
    batch.delete(scenarioStepTable, where: 'id = ?', whereArgs: [id]);
    _batchInsertScenarioSteps(batch, row);
    await batch.commit(noResult: true);
  }

  @override
  Future<void> removeScenarioSteps(Set<ScenarioStepRow> rows) async {
    if (rows.isEmpty) return;

    final batch = _db.batch();
    rows.forEach((row) {
      batch.delete(scenarioStepTable, where: 'id = ?', whereArgs: [row.id]);
    });
    await batch.commit(noResult: true);
  }

  void _batchInsertScenarioSteps(Batch batch, ScenarioStepRow row) {
    batch.insert(
      scenarioStepTable,
      row.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // AssignRecord
  @override
  Future<void> clearAssignRecords() async {
    final count = await _db.delete(assignRecordTable, where: '1');
    debugPrint('clearAssignRecords deleted $count rows');
  }

  @override
  Future<Set<AssignRecordRow>> loadAllAssignRecords() async {
    final rows = await _db.query(assignRecordTable);
    return rows.map(AssignRecordRow.fromMap).where((row) => row != null).toSet();
  }

  @override
  Future<void> addAssignRecords(Set<AssignRecordRow> rows) async {
    if (rows.isEmpty) return;

    final batch = _db.batch();
    rows.forEach((row) => _batchInsertAssignRecords(batch, row));
    await batch.commit(noResult: true);
  }

  @override
  Future<void> updateAssignRecordById(int id, AssignRecordRow row) async {
    final batch = _db.batch();
    batch.delete(assignRecordTable, where: 'id = ?', whereArgs: [id]);
    _batchInsertAssignRecords(batch, row);
    await batch.commit(noResult: true);
  }

  @override
  Future<void> removeAssignRecords(Set<AssignRecordRow> rows) async {
    if (rows.isEmpty) return;

    final batch = _db.batch();
    rows.forEach((row) {
      batch.delete(assignRecordTable, where: 'id = ?', whereArgs: [row.id]);
    });
    await batch.commit(noResult: true);
  }

  void _batchInsertAssignRecords(Batch batch, AssignRecordRow row) {
    batch.insert(
      assignRecordTable,
      row.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  //t4y: share by copy copied entries
  @override
  Future<void> clearAssignEntries() async {
    final count = await _db.delete(assignEntryTable, where: '1');
    debugPrint('clearAssignEntries $assignEntryTable deleted $count rows');
  }

  @override
  Future<Set<AssignEntryRow>> loadAllAssignEntries() async {
    final rows = await _db.query(assignEntryTable);
    return rows.map(AssignEntryRow.fromMap).where((row) => row != null).toSet();
  }

  @override
  Future<void> addAssignEntries(Set<AssignEntryRow> rows) async {
    debugPrint('addAssignEntries.add(_db:\n$rows');
    if (rows.isEmpty) return;
    final batch = _db.batch();
    rows.forEach((row) => _batchInsertAssignEntries(batch, row));
    await batch.commit(noResult: true);
  }

  @override
  Future<void> updateAssignEntries(int id, AssignEntryRow row) async {
    final batch = _db.batch();
    batch.delete(assignEntryTable, where: 'id = ?', whereArgs: [id]);
    _batchInsertAssignEntries(batch, row);
    await batch.commit(noResult: true);
  }

  @override
  Future<void> removeAssignEntries(Set<AssignEntryRow> rows) async {
    if (rows.isEmpty) return;

    final batch = _db.batch();
    rows.forEach((row) {
      batch.delete(assignEntryTable, where: 'id = ?', whereArgs: [row.id]);
    });
    await batch.commit(noResult: true);
  }

  void _batchInsertAssignEntries(Batch batch, AssignEntryRow row) {
    //debugPrint('addAssignEntries.add(_batchInsertAssignEntries:\n$batch \n $row');
    batch.insert(
      assignEntryTable,
      row.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
