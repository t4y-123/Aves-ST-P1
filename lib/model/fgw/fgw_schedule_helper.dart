import 'dart:async';
import 'dart:math';

import 'package:aves/model/fgw/filters_set.dart';
import 'package:aves/model/fgw/guard_level.dart';
import 'package:aves/model/fgw/wallpaper_schedule.dart';
import 'package:aves/model/presentation/base_bridge_row.dart';
import 'package:collection/collection.dart';
import 'package:flutter/cupertino.dart';
import 'package:wallpaper_handler/wallpaper_handler.dart';

import '../entry/entry.dart';
import '../filters/filters.dart';
import '../settings/settings.dart';
import '../source/collection_lens.dart';
import '../source/collection_source.dart';
import 'enum/fgw_schedule_item.dart';
import 'fgw_used_entry_record.dart';

final FgwScheduleHelper fgwScheduleHelper = FgwScheduleHelper._private();

class FgwScheduleHelper {
  FgwScheduleHelper._private();

  Future<void> refreshSchedules() async {
    debugPrint('$runtimeType refreshSchedules ');
    await fgwGuardLevels.refresh();
    await filtersSets.refresh();
    await fgwSchedules.refresh();
    await fgwUsedEntryRecord.refresh();
  }

  Future<FgwGuardLevelRow> getCurGuardLevel() async {
    //debugPrint('$runtimeType  getFgwGuardLevel start');
    final activeItems = fgwGuardLevels.all.where((e) => e.isActive).toSet();
    if (activeItems.isEmpty) {
      //debugPrint('No active FgwGuardLevels found.');
      throw ('FgwGuardLevels.all active items is empty ');
    }
    final result = activeItems.firstWhere(
      (e) => e.guardLevel == settings.curFgwGuardLevelNum,
      orElse: () => activeItems.first,
    );
    debugPrint('$runtimeType  getFgwGuardLevel result ${result.toMap()}');
    return result;
  }

  Future<Set<FgwGuardLevelRow>> getActiveLevels({FgwGuardLevelRow? curFgwGuardLevel}) async {
    //debugPrint('$runtimeType  getFgwGuardLevel start');
    final activeItems = fgwGuardLevels.all.where((e) => e.isActive).toSet();
    if (activeItems.isEmpty) {
      //debugPrint('No active FgwGuardLevels found.');
      throw ('FgwGuardLevels.all active items is empty');
    }
    return activeItems;
  }

  Future<Set<CollectionFilter>> getScheduleFilters(WallpaperUpdateType updateType,
      {int widgetId = 0, FgwGuardLevelRow? curFgwGuardLevel}) async {
    curFgwGuardLevel ??= await getCurGuardLevel();
    final id = fgwSchedules.all
        .firstWhere(
          (schedule) =>
              schedule.updateType == updateType &&
              schedule.widgetId == widgetId &&
              schedule.guardLevelId == curFgwGuardLevel!.id,
        )
        .filtersSetId;

    final filters = filtersSets.all.firstWhere((filterRow) => filterRow.id == id).filters ?? <CollectionFilter>{};
    debugPrint('$runtimeType getScheduleEntries id  $id ');
    //debugPrint('$runtimeType getScheduleEntries filters :$filters');

    return filters;
  }

  Future<Set<FgwScheduleRow>> getGuardLevelSchedules(
      {FgwGuardLevelRow? curFgwGuardLevel, PresentationRowType rowsType = PresentationRowType.all}) async {
    curFgwGuardLevel ??= await getCurGuardLevel();

    final targetSet = fgwSchedules.getAll(rowsType);
    final curSchedules = targetSet.where((e) => e.guardLevelId == curFgwGuardLevel?.id).toSet();

    debugPrint('$runtimeType getScheduleEntries \n curFgwGuardLevel $curFgwGuardLevel \n curSchedules :$curSchedules');
    return curSchedules;
  }

  Future<Set<FgwScheduleRow>> getCurActiveSchedules(
      {FgwGuardLevelRow? curFgwGuardLevel, PresentationRowType rowsType = PresentationRowType.all}) async {
    curFgwGuardLevel ??= await getCurGuardLevel();
    final targetSet = fgwSchedules.getAll(rowsType);
    final curSchedules = targetSet.where((e) => e.guardLevelId == curFgwGuardLevel?.id && e.isActive).toSet();
    debugPrint(
        '$runtimeType getScheduleEntries \n curFgwGuardLevel ${curFgwGuardLevel.toMap()} \n curSchedules :${curSchedules.map((e) => e.toMap()).toString()}');
    return curSchedules;
  }

  Future<List<AvesEntry>> getScheduleEntries(CollectionSource source, WallpaperUpdateType updateType,
      {int widgetId = 0, FgwGuardLevelRow? curFgwGuardLevel}) async {
    curFgwGuardLevel ??= await getCurGuardLevel();
    final filters = await getScheduleFilters(updateType, widgetId: widgetId, curFgwGuardLevel: curFgwGuardLevel);
    final entries =
        CollectionLens(source: source, filters: filters, useScenario: settings.canScenarioAffectFgw).sortedEntries;
    final int itemsToPrint = min(entries.length, 10);
    debugPrint('$runtimeType getScheduleEntries ${entries.length} :'
        '${entries.length}\n${entries.getRange(0, itemsToPrint).map((e) => e.toMap())}');
    return entries;
  }

  Future<AvesEntry> getCurEntry(CollectionSource source, WallpaperUpdateType updateType,
      {int widgetId = 0, FgwGuardLevelRow? curFgwGuardLevel}) async {
    curFgwGuardLevel ??= await getCurGuardLevel();

    final entries = await fgwScheduleHelper.getScheduleEntries(source, updateType,
        widgetId: widgetId, curFgwGuardLevel: curFgwGuardLevel);
    AvesEntry? curEntry = entries.firstWhere((entry) => entry.id == settings.getFgwCurEntryId(updateType, widgetId));
    debugPrint('$runtimeType getCurEntry curEntry :$curEntry');
    return curEntry;
  }

  Future<List<FgwUsedEntryRecordRow>> getRecentEntryRecord(WallpaperUpdateType updateType,
      {int widgetId = 0, FgwGuardLevelRow? curFgwGuardLevel}) async {
    curFgwGuardLevel ??= await getCurGuardLevel();
    final result = fgwUsedEntryRecord.all
        .where(
          (row) => row.updateType == updateType && row.widgetId == widgetId && row.guardLevelId == curFgwGuardLevel!.id,
        )
        .toList();
    debugPrint('$runtimeType getRecentEntryRecord :$result');
    return result;
  }

  void updateCurEntrySettings(WallpaperUpdateType updateType, int widgetId, AvesEntry curEntry) {
    settings.setFgwCurEntryId(updateType, widgetId, curEntry.id);
    settings.setFgwCurEntryUri(updateType, widgetId, curEntry.uri);
    settings.setFgwCurEntryMime(updateType, widgetId, curEntry.mimeType);
    debugPrint('updateCurEntrySettings :\n'
        '$curEntry \n'
        '${settings.getFgwCurEntryId(updateType, widgetId)}\n'
        '${settings.getFgwCurEntryUri(updateType, widgetId)}\n'
        '${settings.getFgwCurEntryMime(updateType, widgetId)}\n');
  }

  Future<AvesEntry?> getPreviousEntry(CollectionSource source, WallpaperUpdateType updateType,
      {int widgetId = 0, List<AvesEntry>? entries, List<FgwUsedEntryRecordRow>? recentUsedEntryRecord}) async {
    AvesEntry? previousEntry;
    entries ??= await getScheduleEntries(source, updateType);
    recentUsedEntryRecord ??= await getRecentEntryRecord(updateType);
    final curEntryId = settings.getFgwCurEntryId(updateType, widgetId);
    final curEntry = entries.firstWhereOrNull((entry) => entry.id == curEntryId);
    final mostRecentUsedEntryRecord = recentUsedEntryRecord.reduce((a, b) => a.dateMillis > b.dateMillis ? a : b);

    if (curEntry == null) {
      previousEntry = entries.firstWhere((entry) => entry.id == mostRecentUsedEntryRecord.entryId);
    } else {
      final curUsedRecord = recentUsedEntryRecord.firstWhereOrNull((usedEntry) => usedEntry.entryId == curEntryId);
      if (curUsedRecord != null) {
        final olderEntries =
            recentUsedEntryRecord.where((usedEntry) => usedEntry.dateMillis < curUsedRecord.dateMillis);
        final mostRecentOlderEntry =
            olderEntries.isNotEmpty ? olderEntries.reduce((a, b) => a.dateMillis > b.dateMillis ? a : b) : null;
        if (entries.isNotEmpty) {
          previousEntry = entries.firstWhere((entry) => entry.id == mostRecentOlderEntry?.entryId);
        }
      } else {
        previousEntry = entries.firstWhere((entry) => entry.id == mostRecentUsedEntryRecord.entryId);
      }
    }
    return previousEntry;
  }

  Future<void> setFgWallpaper(AvesEntry entry,
      {WallpaperUpdateType updateType = WallpaperUpdateType.home, int widgetId = 0}) async {
    debugPrint(' setFgWallpaper');
    WallpaperLocation location = WallpaperLocation.homeScreen;
    switch (updateType) {
      case WallpaperUpdateType.home:
        location = WallpaperLocation.homeScreen;
        debugPrint(' location = WallpaperLocation.homeScreen;');
      case WallpaperUpdateType.lock:
        location = WallpaperLocation.lockScreen;
        debugPrint(' location = WallpaperLocation.lockScreen;');
      case WallpaperUpdateType.both:
        location = WallpaperLocation.bothScreens;
      case WallpaperUpdateType.widget:
        debugPrint('setFgWallpaper WallpaperUpdateType.widget wait for implementation');
        return;
      default:
        throw const FormatException('Invalid setWallpaper');
    }
    bool result = await WallpaperHandler.instance.setWallpaperFromFile(entry.path!, location);

    debugPrint('setFgWallpaper result: $result');
    if (!result) {
      debugPrint('setFgWallpaper fail result: $result');
    }
    // unawaited(WallpaperHandler.instance.setWallpaperFromFile(entry.path!, location).then((result) {
    //   debugPrint('setFgWallpaper result: $result with ${entry.path} in location $location');
    //   if (!result) {
    //     debugPrint('setFgWallpaper fail result: $result');
    //   }
    // }).catchError((error) {
    //   debugPrint('setFgWallpaper error: $error');
    // }));
  }
}
