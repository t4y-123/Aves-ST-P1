import 'dart:async';
import 'dart:convert';
import 'package:aves/model/foreground_wallpaper/filtersSet.dart';
import 'package:aves/model/foreground_wallpaper/privacy_guard_level.dart';
import 'package:aves/model/foreground_wallpaper/wallpaper_schedule.dart';
import 'package:aves/services/common/services.dart';
import 'package:collection/collection.dart';
import 'package:flutter/cupertino.dart';
import 'enum/fgw_schedule_item.dart';
import 'fgw_used_entry_record.dart';

final ForegroundWallpaperHelper foregroundWallpaperHelper = ForegroundWallpaperHelper._private();



class ForegroundWallpaperHelper {
  ForegroundWallpaperHelper._private();

  Future<void> initWallpaperSchedules() async {
    final currentWallpaperSchedules = await metadataDb.loadAllWallpaperSchedules();
    await privacyGuardLevels.init();
    await filtersSets.init();
    await wallpaperSchedules.init();
    if (currentWallpaperSchedules.isEmpty) {
      await addType346Schedules();
    }
    await fgwUsedEntryRecord.init();
  }

  Future<void> clearWallpaperSchedules() async {
    await privacyGuardLevels.clear();
    await filtersSets.clear();
    await wallpaperSchedules.clear();
    await fgwUsedEntryRecord.clear();
  }

  Set<PrivacyGuardLevelRow> commonType3GuardLevels() {
    return {
      privacyGuardLevels.newRow(1, 'Exposure',
          newColor: privacyGuardLevels.all.isEmpty ? const Color(0xFF808080) : null),
      privacyGuardLevels.newRow(2, 'Moderate',
          newColor: privacyGuardLevels.all.isEmpty ? const Color(0xFF8D4FF8) : null),
      privacyGuardLevels.newRow(3, 'Safe', newColor: privacyGuardLevels.all.isEmpty ? const Color(0xFF2986cc) : null),
    };
  }

  // 3level, 4filters set, 6 schedule. for default both home and lock screen wallpaper .
  Future<void> addType346Schedules() async {
    final newLevels = commonType3GuardLevels();

    Set<FiltersSetRow> type346FilterSets = {
      filtersSets.newRow(1, labelName: filtersSets.all.isEmpty ? 'Home: Exposure' : null),
      filtersSets.newRow(2, labelName: filtersSets.all.isEmpty ? 'Home: Moderate' : null),
      filtersSets.newRow(3, labelName: filtersSets.all.isEmpty ? 'Lock: Moderate & Exposure' : null),
      filtersSets.newRow(4, labelName: filtersSets.all.isEmpty ? 'Home & Lock: Safe' : null),
    };
    // must add first, for wallpaperSchedules.newRow will try to get item form them.
    await privacyGuardLevels.add(newLevels);
    await filtersSets.add(type346FilterSets);

    final glIds = privacyGuardLevels.all.map((e) => e.privacyGuardLevelID).toList();
    final fsIds = type346FilterSets.map((e) => e.id).toList();

    List<WallpaperScheduleRow> type346Schedules = [
      newSchedule(1, glIds[0], fsIds[0], WallpaperUpdateType.home),
      newSchedule(2, glIds[0], fsIds[2], WallpaperUpdateType.lock, 0),
      newSchedule(3, glIds[1], fsIds[1], WallpaperUpdateType.home),
      newSchedule(4, glIds[1], fsIds[2], WallpaperUpdateType.lock, 0),
      newSchedule(5, glIds[2], fsIds[3], WallpaperUpdateType.home),
      newSchedule(6, glIds[2], fsIds[3], WallpaperUpdateType.lock, 0),
    ];
    await wallpaperSchedules.add(type346Schedules.toSet());
  }

  WallpaperScheduleRow newSchedule(int offset,int levelId,int filtersSetId,updateType,[int? interval]){
    return wallpaperSchedules.newRow(
      existMaxOrderNumOffset: offset,
      privacyGuardLevelId: levelId,
      filtersSetId: filtersSetId,
      updateType: updateType,
      interval: interval,
    );
  }

  // import/export
  Map<String, List<String>>? export() {
    final fgwMap = Map.fromEntries(FgwExportItem.values.map((v) {
      final jsonMap = [jsonEncode(v.export())];
      return jsonMap != null ? MapEntry(v.name, jsonMap) : null;
    }).whereNotNull());
    return fgwMap;
  }

  Future<void> import(dynamic jsonMap)  async {
    debugPrint('foregroundWallpaperHelper import json Map $jsonMap');
    if (jsonMap is! Map) {
      debugPrint('failed to import privacy guard levels for jsonMap=$jsonMap');
      return;
    }
    await Future.forEach<FgwExportItem>(FgwExportItem.values, (item) async {
      debugPrint('\nFgwExportItem item $item ${jsonMap[item.name]}');
      return item.import(jsonDecode(jsonMap[item.name].toList().first));
    });
  }
}