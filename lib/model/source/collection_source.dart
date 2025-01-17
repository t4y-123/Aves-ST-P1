import 'dart:async';
import 'dart:ui';

import 'package:aves/model/assign/assign_entries.dart';
import 'package:aves/model/assign/assign_record.dart';
import 'package:aves/model/covers.dart';
import 'package:aves/model/entry/entry.dart';
import 'package:aves/model/entry/extensions/catalog.dart';
import 'package:aves/model/entry/extensions/location.dart';
import 'package:aves/model/entry/sort.dart';
import 'package:aves/model/favourites.dart';
import 'package:aves/model/fgw/fgw_used_entry_record.dart';
import 'package:aves/model/fgw/share_copied_entry.dart';
import 'package:aves/model/filters/album.dart';
import 'package:aves/model/filters/assign.dart';
import 'package:aves/model/filters/filters.dart';
import 'package:aves/model/filters/location.dart';
import 'package:aves/model/filters/scenario.dart';
import 'package:aves/model/filters/tag.dart';
import 'package:aves/model/filters/trash.dart';
import 'package:aves/model/metadata/trash.dart';
import 'package:aves/model/scenario/enum/scenario_item.dart';
import 'package:aves/model/scenario/scenario.dart';
import 'package:aves/model/scenario/scenario_step.dart';
import 'package:aves/model/settings/modules/scenario.dart';
import 'package:aves/model/settings/settings.dart';
import 'package:aves/model/source/album.dart';
import 'package:aves/model/source/analysis_controller.dart';
import 'package:aves/model/source/assign.dart';
import 'package:aves/model/source/events.dart';
import 'package:aves/model/source/location/country.dart';
import 'package:aves/model/source/location/location.dart';
import 'package:aves/model/source/location/place.dart';
import 'package:aves/model/source/location/state.dart';
import 'package:aves/model/source/scenario.dart';
import 'package:aves/model/source/tag.dart';
import 'package:aves/model/source/trash.dart';
import 'package:aves/model/vaults/vaults.dart';
import 'package:aves/services/analysis_service.dart';
import 'package:aves/services/common/image_op_events.dart';
import 'package:aves/services/common/services.dart';
import 'package:aves/widgets/aves_app.dart';
import 'package:aves_model/aves_model.dart';
import 'package:collection/collection.dart';
import 'package:event_bus/event_bus.dart';
import 'package:flutter/foundation.dart';
import 'package:leak_tracker/leak_tracker.dart';

typedef SourceScope = Set<CollectionFilter>?;

mixin SourceBase {
  EventBus get eventBus;

  Map<int, AvesEntry> get entryById;

  Set<AvesEntry> get allEntries;

  Set<AvesEntry> get visibleEntries;

  Set<AvesEntry> get trashedEntries;

  List<AvesEntry> get sortedEntriesByDate;

  ValueNotifier<SourceState> stateNotifier = ValueNotifier(SourceState.ready);

  set state(SourceState value) => stateNotifier.value = value;

  SourceState get state => stateNotifier.value;

  bool get isReady => state == SourceState.ready;

  ValueNotifier<ProgressEvent> progressNotifier = ValueNotifier(const ProgressEvent(done: 0, total: 0));

  void setProgress({required int done, required int total}) => progressNotifier.value = ProgressEvent(done: done, total: total);

  void invalidateEntries();
}

abstract class CollectionSource with SourceBase, AlbumMixin, CountryMixin, PlaceMixin, StateMixin, LocationMixin, TagMixin, TrashMixin, ScenarioMixin,
AssignMixin  {
  static const fullScope = <CollectionFilter>{};

  CollectionSource() {
    if (kFlutterMemoryAllocationsEnabled) {
      LeakTracking.dispatchObjectCreated(
        library: 'aves',
        className: '$CollectionSource',
        object: this,
      );
    }
    settings.updateStream.where((event) => event.key == SettingKeys.localeKey).listen((_) => invalidateAlbumDisplayNames());
    settings.updateStream.where((event) => event.key == SettingKeys.hiddenFiltersKey).listen((event) {
      final oldValue = event.oldValue;
      if (oldValue is List<String>?) {
        final oldHiddenFilters = (oldValue ?? []).map(CollectionFilter.fromJson).nonNulls.toSet();
        final newlyVisibleFilters = oldHiddenFilters.whereNot(settings.hiddenFilters.contains).toSet();
        _onFilterVisibilityChanged(newlyVisibleFilters);
      }
    });
    vaults.addListener(_onVaultsChanged);
    // t4y: add for listen the scenario change.
    settings.updateStream
        .where((event) =>
    event.key == ScenarioSettings.scenarioPinnedExcludeFiltersKey ||
        event.key == ScenarioSettings.scenarioPinnedIntersectFiltersKey ||
        event.key == ScenarioSettings.scenarioPinnedUnionFiltersKey)
        .listen((event) {
      final oldValue = event.oldValue;
      if (oldValue is List<String>?) {
        _onScenarioChanged();
      }
    });
    //
    assignRecords.addListener(updateScenario);
    assignRecords.addListener(updateAssigns);
    assignEntries.addListener(updateAssigns);
    scenarios.addListener(updateScenario);
    scenarios.addListener(updateAssigns);
    scenarioSteps.addListener(updateScenario);
  }

  @mustCallSuper
  void dispose() {
    if (kFlutterMemoryAllocationsEnabled) {
      LeakTracking.dispatchObjectDisposed(object: this);
    }
    vaults.removeListener(_onVaultsChanged);
    _rawEntries.forEach((v) => v.dispose());
  }

  set canAnalyze(bool enabled);

  final EventBus _eventBus = EventBus();

  @override
  EventBus get eventBus => _eventBus;

  final Map<int, AvesEntry> _entryById = {};

  @override
  Map<int, AvesEntry> get entryById => Map.unmodifiable(_entryById);

  final Set<AvesEntry> _rawEntries = {};

  @override
  Set<AvesEntry> get allEntries => Set.unmodifiable(_rawEntries);

  Set<AvesEntry>? _visibleEntries, _trashedEntries, _noneScenarioVisibleEntries;

  @override
  Set<AvesEntry> get visibleEntries {
    _visibleEntries ??= Set.unmodifiable(_applyHiddenFilters(_rawEntries, useScenario: settings.useScenarios));
    return _visibleEntries!;
  }

  Set<AvesEntry> get noneScenarioVisibleEntries {
    _noneScenarioVisibleEntries ??= Set.unmodifiable(_applyHiddenFilters(_rawEntries, useScenario: false));
    return _noneScenarioVisibleEntries!;
  }

  @override
  Set<AvesEntry> get trashedEntries {
    _trashedEntries ??= Set.unmodifiable(_applyTrashFilter(_rawEntries));
    return _trashedEntries!;
  }

  List<AvesEntry>? _sortedEntriesByDate;

  @override
  List<AvesEntry> get sortedEntriesByDate {
    _sortedEntriesByDate ??= List.unmodifiable(visibleEntries.toList()..sort(AvesEntrySort.compareByDate));
    return _sortedEntriesByDate!;
  }

  // known date by entry ID
  late Map<int?, int?> _savedDates;

  Future<void> loadDates() async {
    _savedDates = Map.unmodifiable(await localMediaDb.loadDates());
  }

  Set<CollectionFilter> _getAppHiddenFilters() => {
        ...settings.hiddenFilters,
        ...vaults.vaultDirectories.where(vaults.isLocked).map((v) => AlbumFilter(v, null)),
      };

  Iterable<AvesEntry> _applyHiddenFilters(Iterable<AvesEntry> entries, {bool useScenario = true}) {
    final hiddenFilters = {
      TrashFilter.instance,
      ..._getAppHiddenFilters(),
    };

    if (!useScenario) {
      return entries.where((entry) => !hiddenFilters.any((filter) => filter.test(entry)));
    }
    if (settings.scenarioPinnedExcludeFilters.isEmpty) {
      return entries.where((entry) => false);
    }
    // Separate the filters by type once
    return applyScenarioFilters(entries);
  }

  Iterable<AvesEntry> applyScenarioFilters(Iterable<AvesEntry> entries) {
    final hiddenFilters = {
      TrashFilter.instance,
      ..._getAppHiddenFilters(),
    };

    final excludeUniqueFilters = settings.scenarioPinnedExcludeFilters;
    final intersectAndFilters = settings.scenarioPinnedIntersectFilters;
    final unionOrFilters = settings.scenarioPinnedUnionFilters;

    // debugPrint('applyScenarioFilters excludeUniqueFilters $excludeUniqueFilters \n'
    //     'intersectAndFilters $intersectAndFilters \n'
    //     'unionOrFilters $unionOrFilters ');

    final hasUnionOr = unionOrFilters.isNotEmpty;
    final hasIntersectAnd = intersectAndFilters.isNotEmpty;

    return entries.where((entry) {
      if (hiddenFilters.any((filter) => filter.test(entry))) return false;

      final uniqueFilterResult = excludeUniqueFilters.any((filter) => filter.test(entry));

      switch (settings.scenarioGroupFactor) {
        case ScenarioChipGroupFactor.intersectBeforeUnion:
          if (hasUnionOr) {
            //skip intersect if entry in in union post.
            if (unionOrFilters.any((filter) => filter.test(entry))) return true;
          }
          //if a entry is not in union post, check if exist entry fit limit intersect.
          if (uniqueFilterResult && hasIntersectAnd) {
            return intersectAndFilters.every((filter) => filter.test(entry));
          }
          // if a entry is get in by union, it is always in ,
          // if a entry is not in by union, its value is base the exclude value and intersect value,
          // when have none intersect, it the same as unique.
          return uniqueFilterResult;

        case ScenarioChipGroupFactor.unionBeforeIntersect:
          //skip union if entry is get rid in interject post.
          if (hasIntersectAnd) {
            if (!intersectAndFilters.every((filter) => filter.test(entry))) return false;
          }
          // try get union entry if not in exclude fit limit intersect.
          if (!uniqueFilterResult && hasUnionOr) {
            return unionOrFilters.any((filter) => filter.test(entry));
          }
          // if a entry is not get rid by intersect when exist,
          // or not get in by union when not exist,
          // the value is the same as exclude.
          return uniqueFilterResult;
      }
    });
  }

  Iterable<AvesEntry> _applyTrashFilter(Iterable<AvesEntry> entries) {
    final hiddenFilters = _getAppHiddenFilters();
    return entries.where(TrashFilter.instance.test).where((entry) => !hiddenFilters.any((filter) => filter.test(entry)));
  }

  void _invalidate({Set<AvesEntry>? entries, bool notify = true}) {
    invalidateEntries();
    invalidateAlbumFilterSummary(entries: entries, notify: notify);
    invalidateCountryFilterSummary(entries: entries, notify: notify);
    invalidatePlaceFilterSummary(entries: entries, notify: notify);
    invalidateStateFilterSummary(entries: entries, notify: notify);
    invalidateTagFilterSummary(entries: entries, notify: notify);
    invalidateScenarioFilterSummary(entries: entries, notify: notify);
    invalidateAssignFilterSummary(entries: entries, notify: notify);
  }

  @override
  void invalidateEntries() {
    _visibleEntries = null;
    _trashedEntries = null;
    _sortedEntriesByDate = null;
  }

  void updateDerivedFilters([Set<AvesEntry>? entries]) {
    _invalidate(entries: entries);
    // it is possible for entries hidden by a filter type, to have an impact on other types
    // e.g. given a sole entry for country C and tag T, hiding T should make C disappear too
    updateDirectories();
    updateLocations();
    updateTags();
  }

  final Map<String, AvesEntry> _entriesByPath = {};

  void addOrUpdateEntry(AvesEntry entry) {
    final path = entry.path;
    if (path != null) {
      // Optionally update the existing entry
      if (_entriesByPath.containsKey(path)) {
        final preEntry = _entriesByPath[path];
        //t4y: if share by copied exist with a same file,mean this duplicate happen in a share copy op,
        // but as not sure which one will be added to db in multi progress,
        // I add them all to share by copy record.
        // and remove when remove expired share copied.
        if (preEntry != null && shareCopiedEntries.all.contains(preEntry.contentId)) {
          shareCopiedEntries.add({entry});
        }
        _rawEntries.remove(_entriesByPath[path]);
        _entriesByPath[path] = entry;
      } else {
        _entriesByPath[path] = entry;
      }
    }
  }

  void addEntries(Set<AvesEntry> entries, {bool notify = true}) {
    if (entries.isEmpty) return;

    for (var entry in entries) {
      addOrUpdateEntry(entry);
    }

    final newIdMapEntries = Map.fromEntries(entries.map((entry) => MapEntry(entry.id, entry)));
    if (_rawEntries.isNotEmpty) {
      final newIds = newIdMapEntries.keys.toSet();
      _rawEntries.removeWhere((entry) => newIds.contains(entry.id));
    }

    entries.where((entry) => entry.catalogDateMillis == null).forEach((entry) {
      entry.catalogDateMillis = _savedDates[entry.id];
    });

    _entryById.addAll(newIdMapEntries);
    _rawEntries.addAll(entries);
    _invalidate(entries: entries, notify: notify);

    addDirectories(albums: _applyHiddenFilters(entries).map((entry) => entry.directory).toSet(), notify: notify);
    if (notify) {
      eventBus.fire(EntryAddedEvent(entries));
    }
  }

  Future<void> removeEntries(Set<String> uris, {required bool includeTrash}) async {
    if (uris.isEmpty) return;

    final entries = _rawEntries.where((entry) => uris.contains(entry.uri)).toSet();
    if (!includeTrash) {
      entries.removeWhere(TrashFilter.instance.test);
    }
    if (entries.isEmpty) return;

    final ids = entries.map((entry) => entry.id).toSet();
    final mapContentIds = entries.map((entry) => entry.contentId ?? 0).toSet();
    await favourites.removeIds(ids);
    await covers.removeIds(ids);
    await localMediaDb.removeIds(ids);
    debugPrint('$runtimeType  removeEntries');
    await fgwUsedEntryRecord.removeEntryIds(ids);
    debugPrint('$runtimeType  await fgwUsedEntryRecord.removeEntryIds(ids); $ids');
    await shareCopiedEntries.removeEntryContentIds(mapContentIds);
    debugPrint('$runtimeType  await shareCopiedEntries.removeEntryIds(ids);; $ids\n mapContentIds $mapContentIds');

    ids.forEach((id) => _entryById.remove);
    _rawEntries.removeAll(entries);
    updateDerivedFilters(entries);
    eventBus.fire(EntryRemovedEvent(entries));
  }

  void clearEntries() {
    _entryById.clear();
    _rawEntries.clear();
    _invalidate();

    // do not update directories/locations/tags here
    // as it could reset filter dependent settings (pins, bookmarks, etc.)
    // caller should take care of updating these at the right time
  }

  Future<void> _moveEntry(AvesEntry entry, Map newFields, {required bool persist}) async {
    newFields.keys.forEach((key) {
      final newValue = newFields[key];
      switch (key) {
        case 'contentId':
          entry.contentId = newValue as int?;
        case 'dateModifiedSecs':
          // `dateModifiedSecs` changes when moving entries to another directory,
          // but it does not change when renaming the containing directory
          entry.dateModifiedSecs = newValue as int?;
        case 'path':
          entry.path = newValue as String?;
        case 'title':
          entry.sourceTitle = newValue as String?;
        case 'trashed':
          final trashed = newValue as bool;
          entry.trashed = trashed;
          entry.trashDetails = trashed
              ? TrashDetails(
                  id: entry.id,
                  path: newFields['trashPath'] as String,
                  dateMillis: DateTime.now().millisecondsSinceEpoch,
                )
              : null;
        case 'uri':
          entry.uri = newValue as String;
        case 'origin':
          entry.origin = newValue as int;
      }
    });
    if (entry.trashed) {
      final trashPath = entry.trashDetails?.path;
      if (trashPath != null) {
        entry.contentId = null;
        entry.uri = Uri.file(trashPath).toString();
      } else {
        debugPrint('failed to update uri from unknown trash path for uri=${entry.uri}');
      }
    }

    if (persist) {
      await covers.moveEntry(entry);
      final id = entry.id;
      await localMediaDb.updateEntry(id, entry);
      await localMediaDb.updateCatalogMetadata(id, entry.catalogMetadata);
      await localMediaDb.updateAddress(id, entry.addressDetails);
      await localMediaDb.updateTrash(id, entry.trashDetails);
    }
  }

  Future<void> renameAlbum(String sourceAlbum, String destinationAlbum, Set<AvesEntry> entries, Set<MoveOpEvent> movedOps) async {
    final oldFilter = AlbumFilter(sourceAlbum, null);
    final newFilter = AlbumFilter(destinationAlbum, null);

    final bookmark = settings.drawerAlbumBookmarks?.indexOf(sourceAlbum);
    final pinned = settings.pinnedFilters.contains(oldFilter);

    if (vaults.isVault(sourceAlbum)) {
      await vaults.rename(sourceAlbum, destinationAlbum);
    }

    final existingCover = covers.of(oldFilter);
    await covers.set(
      filter: newFilter,
      entryId: existingCover?.$1,
      packageName: existingCover?.$2,
      color: existingCover?.$3,
    );

    renameNewAlbum(sourceAlbum, destinationAlbum);
    await updateAfterMove(
      todoEntries: entries,
      moveType: MoveType.move,
      destinationAlbums: {destinationAlbum},
      movedOps: movedOps,
    );

    // restore bookmark and pin, as the obsolete album got removed and its associated state cleaned
    if (bookmark != null && bookmark != -1) {
      settings.drawerAlbumBookmarks = settings.drawerAlbumBookmarks?..insert(bookmark, destinationAlbum);
    }
    if (pinned) {
      settings.pinnedFilters = settings.pinnedFilters
        ..remove(oldFilter)
        ..add(newFilter);
    }
  }

  Future<void> updateAfterMove({
    required Set<AvesEntry> todoEntries,
    required MoveType moveType,
    required Set<String> destinationAlbums,
    required Set<MoveOpEvent> movedOps,
    Function(Set<AvesEntry>)? onUpdatedEntries,
  }) async {
    if (movedOps.isEmpty) return;

    final replacedUris = movedOps
        .map((movedOp) => movedOp.newFields['path'] as String?)
        .map((targetPath) {
          final existingEntry = _rawEntries.firstWhereOrNull((entry) => entry.path == targetPath && !entry.trashed);
          return existingEntry?.uri;
        })
        .nonNulls
        .toSet();
    await removeEntries(replacedUris, includeTrash: false);

    final fromAlbums = <String?>{};
    final movedEntries = <AvesEntry>{};
    final copy = moveType == MoveType.copy;
    final shareByCopy = moveType == MoveType.shareByCopy;
    if (copy || shareByCopy) {
      movedOps.forEach((movedOp) {
        final sourceUri = movedOp.uri;
        final newFields = movedOp.newFields;
        final sourceEntry = todoEntries.firstWhereOrNull((entry) => entry.uri == sourceUri);
        if (sourceEntry != null) {
          fromAlbums.add(sourceEntry.directory);
          movedEntries.add(sourceEntry.copyWith(
            id: localMediaDb.nextDateId,
            uri: newFields['uri'] as String?,
            path: newFields['path'] as String?,
            contentId: newFields['contentId'] as int?,
            // title can change when moved files are automatically renamed to avoid conflict
            title: newFields['title'] as String?,
            dateAddedSecs: newFields['dateAddedSecs'] as int?,
            dateModifiedSecs: newFields['dateModifiedSecs'] as int?,
            origin: newFields['origin'] as int?,
          ));
        } else {
          debugPrint('failed to find source entry with uri=$sourceUri');
        }
      });
      await localMediaDb.insertEntries(movedEntries);
      await localMediaDb.saveCatalogMetadata(movedEntries.map((entry) => entry.catalogMetadata).nonNulls.toSet());
      await localMediaDb.saveAddresses(movedEntries.map((entry) => entry.addressDetails).nonNulls.toSet());
      await localMediaDb.saveCatalogMetadata(movedEntries.map((entry) => entry.catalogMetadata).whereNotNull().toSet());
      await localMediaDb.saveAddresses(movedEntries.map((entry) => entry.addressDetails).whereNotNull().toSet());
      // t4y: for intuitively, the copied items should be the most recently.
      // And for functionally, somme apps  will still swallows you pic making it not be able to send to others unless made some modified.
      if (shareByCopy) {
        await shareCopiedEntries.add(movedEntries);
        debugPrint('shareCopiedEntries.add(movedEntries updateAfterMove:\n'
            '$movedEntries');
        // final dateTime = DateTime.now();
        // final modifier = DateModifier.setCustom(const {}, dateTime);
        // await Future.wait(movedEntries.map((entry) async {
        //   await entry.editDate(modifier);
        //   debugPrint('shareCopiedEntries.  await entry.editDate(modifier);\n[$entry]');
        // }));
      }
      if (onUpdatedEntries != null) {
        onUpdatedEntries(movedEntries);
      }
    } else {
      await Future.forEach<MoveOpEvent>(movedOps, (movedOp) async {
        final newFields = movedOp.newFields;
        if (newFields.isNotEmpty) {
          final sourceUri = movedOp.uri;
          final entry = todoEntries.firstWhereOrNull((entry) => entry.uri == sourceUri);
          if (entry != null) {
            if (moveType == MoveType.fromBin) {
              newFields['trashed'] = false;
            } else {
              fromAlbums.add(entry.directory);
            }
            movedEntries.add(entry);
            await _moveEntry(entry, newFields, persist: true);
          }
        }
      });
      // // t4y: content Id after move to bin is null
      // if (moveType == MoveType.toBin) {
      //   final contentIds = movedEntries.map((e) => e.contentId);
      //   debugPrint('$runtimeType  await shareCopiedEntries.removeEntries(movedEntries) in  updateAfterMove tobin'
      //       ' :\n$movedEntries\n'
      //       'movedEntries ContentIds:$contentIds');
      //   await shareCopiedEntries.removeEntries(movedEntries);
      // }
    }

    switch (moveType) {
      case MoveType.copy:
      case MoveType.shareByCopy:
        addEntries(movedEntries);
      case MoveType.move:
      case MoveType.export:
        cleanEmptyAlbums(fromAlbums.nonNulls.toSet());
        addDirectories(albums: destinationAlbums);
      case MoveType.toBin:
      case MoveType.fromBin:
        updateDerivedFilters(movedEntries);
    }
    invalidateAlbumFilterSummary(directories: fromAlbums);
    _invalidate(entries: movedEntries);
    eventBus.fire(EntryMovedEvent(moveType, movedEntries));
  }

  Future<void> updateAfterRename({
    required Set<AvesEntry> todoEntries,
    required Set<MoveOpEvent> movedOps,
    required bool persist,
  }) async {
    if (movedOps.isEmpty) return;

    final movedEntries = <AvesEntry>{};
    await Future.forEach<MoveOpEvent>(movedOps, (movedOp) async {
      final newFields = movedOp.newFields;
      if (newFields.isNotEmpty) {
        final sourceUri = movedOp.uri;
        final entry = todoEntries.firstWhereOrNull((entry) => entry.uri == sourceUri);
        if (entry != null) {
          movedEntries.add(entry);
          await _moveEntry(entry, newFields, persist: persist);
        }
      }
    });

    eventBus.fire(EntryMovedEvent(MoveType.move, movedEntries));
  }

  SourceScope get loadedScope;

  SourceScope get targetScope;

  Future<void> init({
    required SourceScope scope,
    AnalysisController? analysisController,
    bool loadTopEntriesFirst = false,
  });

  Future<Set<String>> refreshUris(Set<String> changedUris, {AnalysisController? analysisController});

  Future<void> refreshEntries(Set<AvesEntry> entries, Set<EntryDataType> dataTypes) async {
    const background = false;
    const persist = true;

    await Future.forEach(entries, (entry) async {
      await entry.refresh(background: background, persist: persist, dataTypes: dataTypes);
    });

    if (dataTypes.contains(EntryDataType.aspectRatio)) {
      onAspectRatioChanged();
    }

    if (dataTypes.contains(EntryDataType.catalog)) {
      // explicit GC before cataloguing multiple items
      await deviceService.requestGarbageCollection();
      await Future.forEach(entries, (entry) async {
        await entry.catalog(background: background, force: dataTypes.contains(EntryDataType.catalog), persist: persist);
        await localMediaDb.updateCatalogMetadata(entry.id, entry.catalogMetadata);
      });
      onCatalogMetadataChanged();
    }

    if (dataTypes.contains(EntryDataType.address)) {
      await Future.forEach(entries, (entry) async {
        await entry.locate(background: background, force: dataTypes.contains(EntryDataType.address), geocoderLocale: settings.appliedLocale);
        await localMediaDb.updateAddress(entry.id, entry.addressDetails);
      });
      onAddressMetadataChanged();
    }

    updateDerivedFilters(entries);
    eventBus.fire(EntryRefreshedEvent(entries));
  }

  Future<void> analyze(AnalysisController? analysisController, {Set<AvesEntry>? entries}) async {
    final todoEntries = entries ?? visibleEntries;
    final defaultAnalysisController = AnalysisController();
    final _analysisController = analysisController ?? defaultAnalysisController;
    final force = _analysisController.force;
    if (!_analysisController.isStopping) {
      var startAnalysisService = false;
      if (_analysisController.canStartService && settings.canUseAnalysisService) {
        // cataloguing
        if (!startAnalysisService) {
          final opCount = (force ? todoEntries : todoEntries.where(TagMixin.catalogEntriesTest)).length;
          if (opCount > TagMixin.commitCountThreshold) {
            startAnalysisService = true;
          }
        }
        // ignore locating countries
        // locating places
        if (!startAnalysisService && await availability.canLocatePlaces) {
          final opCount = (force ? todoEntries.where((entry) => entry.hasGps) : todoEntries.where(LocationMixin.locatePlacesTest)).length;
          if (opCount > LocationMixin.commitCountThreshold) {
            startAnalysisService = true;
          }
        }
      }

      if (startAnalysisService) {
        final lifecycleState = AvesApp.lifecycleStateNotifier.value;
        switch (lifecycleState) {
          case AppLifecycleState.resumed:
          case AppLifecycleState.inactive:
            await AnalysisService.startService(
              force: force,
              entryIds: entries?.map((entry) => entry.id).toList(),
            );
          default:
            unawaited(reportService.log('analysis service not started because app is in state=$lifecycleState'));
        }
      } else {
        // explicit GC before cataloguing multiple items
        await deviceService.requestGarbageCollection();
        await catalogEntries(_analysisController, todoEntries);
        updateDerivedFilters(todoEntries);
        await locateEntries(_analysisController, todoEntries);
        updateDerivedFilters(todoEntries);
      }
    }
    defaultAnalysisController.dispose();
    state = SourceState.ready;
  }

  void onAspectRatioChanged() => eventBus.fire(AspectRatioChangedEvent());

  // monitoring

  bool _canRefresh = true;

  void pauseMonitoring() => _canRefresh = false;

  void resumeMonitoring() => _canRefresh = true;

  bool get canRefresh => _canRefresh;

  // filter summary

  int count(CollectionFilter filter) {
    if (filter is AlbumFilter) return albumEntryCount(filter);
    if (filter is LocationFilter) {
      switch (filter.level) {
        case LocationLevel.country:
          return countryEntryCount(filter);
        case LocationLevel.state:
          return stateEntryCount(filter);
        case LocationLevel.place:
          return placeEntryCount(filter);
      }
    }
    if (filter is TagFilter) return tagEntryCount(filter);
    if (filter is ScenarioFilter) return scenarioEntryCount(filter);
    if (filter is AssignFilter) return assignEntryCount(filter);
    return 0;
  }

  int size(CollectionFilter filter) {
    if (filter is AlbumFilter) return albumSize(filter);
    if (filter is LocationFilter) {
      switch (filter.level) {
        case LocationLevel.country:
          return countrySize(filter);
        case LocationLevel.state:
          return stateSize(filter);
        case LocationLevel.place:
          return placeSize(filter);
      }
    }
    if (filter is TagFilter) return tagSize(filter);
    if (filter is ScenarioFilter) return scenarioSize(filter);
    if (filter is AssignFilter) return assignSize(filter);
    return 0;
  }

  AvesEntry? recentEntry(CollectionFilter filter) {
    if (filter is AlbumFilter) return albumRecentEntry(filter);
    if (filter is LocationFilter) {
      switch (filter.level) {
        case LocationLevel.country:
          return countryRecentEntry(filter);
        case LocationLevel.state:
          return stateRecentEntry(filter);
        case LocationLevel.place:
          return placeRecentEntry(filter);
      }
    }
    if (filter is TagFilter) return tagRecentEntry(filter);
    if (filter is ScenarioFilter) return scenarioRecentEntry(filter);
    if (filter is AssignFilter) return assignRecentEntry(filter);
    return null;
  }

  AvesEntry? coverEntry(CollectionFilter filter) {
    final id = covers.of(filter)?.$1;
    if (id != null) {
      final entry = visibleEntries.firstWhereOrNull((entry) => entry.id == id);
      if (entry != null) return entry;
    }
    return recentEntry(filter);
  }

  void _onFilterVisibilityChanged(Set<CollectionFilter> newlyVisibleFilters) {
    updateDerivedFilters();
    eventBus.fire(const FilterVisibilityChangedEvent());

    if (newlyVisibleFilters.isNotEmpty) {
      final candidateEntries = visibleEntries.where((entry) => newlyVisibleFilters.any((f) => f.test(entry))).toSet();
      analyze(null, entries: candidateEntries);
    }
  }

  void _onScenarioChanged() {
    debugPrint('$runtimeType  _onScenarioChanged ');
    updateDerivedFilters();
    eventBus.fire(const FilterVisibilityChangedEvent());
    _visibleEntries = Set.unmodifiable(_applyHiddenFilters(_rawEntries));
    final candidateEntries = visibleEntries;
    analyze(null, entries: candidateEntries);
    notifyScenariosChanged();
  }

  void _onVaultsChanged() {
    final newlyVisibleFilters = vaults.vaultDirectories.whereNot(vaults.isLocked).map((v) => AlbumFilter(v, null)).toSet();
    _onFilterVisibilityChanged(newlyVisibleFilters);
  }
}

class AspectRatioChangedEvent {}
