import 'dart:async';
import 'package:aves/model/foreground_wallpaper/filterSet.dart';
import 'package:aves/model/foreground_wallpaper/privacy_guard_level.dart';
import 'package:aves/model/foreground_wallpaper/wallpaper_schedule.dart';
import 'package:collection/collection.dart';
import 'package:flutter/cupertino.dart';
import '../entry/entry.dart';
import '../filters/filters.dart';
import '../settings/settings.dart';
import '../source/collection_lens.dart';
import '../source/collection_source.dart';
import 'fgw_used_entry_record.dart';

final FgwScheduleHelper fgwScheduleHelper = FgwScheduleHelper._private();

class FgwScheduleHelper {
  FgwScheduleHelper._private();

  Future<PrivacyGuardLevelRow> getPrivacyGuardLevel() async {
    debugPrint('$runtimeType  getPrivacyGuardLevel start');
    final activeItems = privacyGuardLevels.all.where((e) => e.isActive).toSet();
    if (activeItems.isEmpty) {
      debugPrint('No active PrivacyGuardLevels found.');
      throw ('PrivacyGuardLevels.all active items is empty ');
    }
    final result =activeItems.firstWhere(
          (e) => e.guardLevel == settings.curPrivacyGuardLevel,
      orElse: () => activeItems.first,
    );
    debugPrint('$runtimeType  getPrivacyGuardLevel result $result');
    return result;
  }

  Future<Set<CollectionFilter>> getScheduleFilters(WallpaperUpdateType updateType,
      {int widgetId =0 ,PrivacyGuardLevelRow? curPrivacyGuardLevel}) async {

    curPrivacyGuardLevel ??= await getPrivacyGuardLevel();
    final filterSetId = wallpaperSchedules.all
        .firstWhere(
          (schedule) =>
              schedule.updateType == updateType &&
              schedule.widgetId == widgetId &&
              schedule.privacyGuardLevelId == curPrivacyGuardLevel!.privacyGuardLevelID,
        )
        .filterSetId;

    final filters =
        filterSet.all.firstWhere((filterRow) => filterRow.filterSetId == filterSetId).filters ?? <CollectionFilter>{};
    debugPrint('$runtimeType getScheduleEntries filterSetId  $filterSetId ');
    debugPrint('$runtimeType getScheduleEntries filters :$filters');

    return filters;
  }

  Future<List<AvesEntry>> getScheduleEntries(CollectionSource source, WallpaperUpdateType updateType,
      {int widgetId =0 ,PrivacyGuardLevelRow? curPrivacyGuardLevel}) async {
    curPrivacyGuardLevel ??= await getPrivacyGuardLevel();
    final filters = await getScheduleFilters(updateType,widgetId:  widgetId, curPrivacyGuardLevel: curPrivacyGuardLevel);
    final entries = CollectionLens(source: source, filters: filters).sortedEntries;
    debugPrint('$runtimeType getScheduleEntries entries :$entries');
    return entries;
  }

  Future<List<FgwUsedEntryRecordRow>> getRecentEntryRecord(WallpaperUpdateType updateType,
      {int widgetId = 0,PrivacyGuardLevelRow? curPrivacyGuardLevel}) async {

    curPrivacyGuardLevel ??= await getPrivacyGuardLevel();
    final result = fgwUsedEntryRecord.all
        .where(
          (row) =>
      row.updateType == updateType &&
          row.widgetId == widgetId &&
          row.privacyGuardLevelId == curPrivacyGuardLevel!.privacyGuardLevelID,
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
        '${settings.getFgwCurEntryMime(updateType, widgetId)}\n'
    );
  }

  Future<AvesEntry?> getPreviousEntry(CollectionSource source,WallpaperUpdateType updateType,
      {int widgetId = 0, List<AvesEntry>? entries, List<FgwUsedEntryRecordRow>? recentUsedEntryRecord}) async {
    AvesEntry? previousEntry;
    entries ??= await getScheduleEntries(source,updateType);
    recentUsedEntryRecord ??= await getRecentEntryRecord(updateType);
    final curEntryId = settings.getFgwCurEntryId(updateType, widgetId);
    final curEntry = entries?.firstWhereOrNull((entry) => entry.id == curEntryId);
    final mostRecentUsedEntryRecord = recentUsedEntryRecord?.reduce((a, b) => a.dateMillis > b.dateMillis ? a : b);

    if (curEntry == null) {
      previousEntry = entries?.firstWhere((entry) => entry.id == mostRecentUsedEntryRecord!.entryId);
    } else {
      final curUsedRecord = recentUsedEntryRecord?.firstWhereOrNull((usedEntry) => usedEntry.entryId == curEntryId);
      if (curUsedRecord != null) {
        final olderEntries = recentUsedEntryRecord?.where((usedEntry) => usedEntry.dateMillis < curUsedRecord.dateMillis);
        final mostRecentOlderEntry = olderEntries!.isNotEmpty ? olderEntries.reduce((a, b) => a.dateMillis > b.dateMillis ? a : b) : null;
        if (entries!.isNotEmpty) {
          previousEntry = entries.firstWhere((entry) => entry.id == mostRecentOlderEntry?.entryId);
        }
      } else {
        previousEntry = entries?.firstWhere((entry) => entry.id == mostRecentUsedEntryRecord!.entryId);
      }
    }
    return previousEntry;
  }
}
