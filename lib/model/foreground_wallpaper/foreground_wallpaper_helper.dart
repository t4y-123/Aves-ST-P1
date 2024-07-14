import 'dart:async';
import 'dart:convert';
import 'package:aves/model/foreground_wallpaper/filterSet.dart';
import 'package:aves/model/foreground_wallpaper/privacy_guard_level.dart';
import 'package:aves/model/foreground_wallpaper/wallpaper_schedule.dart';
import 'package:aves/services/common/services.dart';
import 'package:collection/collection.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/painting.dart';
import 'fgw_used_entry_record.dart';

final ForegroundWallpaperHelper foregroundWallpaperHelper = ForegroundWallpaperHelper._private();

enum FgwExportItem { privacyGuardLevel, filterSet, schedule }

extension ExtraAppExportItem on FgwExportItem {

  dynamic export() {
    return switch (this) {
      FgwExportItem.privacyGuardLevel => privacyGuardLevels.export(),
      FgwExportItem.filterSet => filterSet.export(),
      FgwExportItem.schedule => wallpaperSchedules.export(),
    };
  }

  Future<void> import(dynamic jsonMap) async {
    switch (this) {
      case FgwExportItem.privacyGuardLevel:
        await privacyGuardLevels.import(jsonMap);
      case FgwExportItem.filterSet:
        await filterSet.import(jsonMap);
      case FgwExportItem.schedule:
        await wallpaperSchedules.import(jsonMap);
    }
  }
}

class ForegroundWallpaperHelper {
  ForegroundWallpaperHelper._private();

  Future<void> initWallpaperSchedules() async {
    final currentWallpaperSchedules = await metadataDb.loadAllWallpaperSchedules();
    await privacyGuardLevels.init();
    await filterSet.init();
    await wallpaperSchedules.init();
    if (currentWallpaperSchedules.isEmpty) {
      await addType346Schedules();
    }
    await fgwUsedEntryRecord.init();
  }

  Future<void> clearWallpaperSchedules() async {
    await privacyGuardLevels.clear();
    await filterSet.clear();
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

    Set<FilterSetRow> type346FilterSets = {
      filterSet.newRow(1, aliasName: filterSet.all.isEmpty ? 'Home: Exposure' : null),
      filterSet.newRow(2, aliasName: filterSet.all.isEmpty ? 'Home: Moderate' : null),
      filterSet.newRow(3, aliasName: filterSet.all.isEmpty ? 'Lock: Moderate & Exposure' : null),
      filterSet.newRow(4, aliasName: filterSet.all.isEmpty ? 'Home & Lock: Safe' : null),
    };
    // must add first, for wallpaperSchedules.newRow will try to get item form them.
    await privacyGuardLevels.add(newLevels);
    await filterSet.add(type346FilterSets);

    final glIds = privacyGuardLevels.all.map((e) => e.privacyGuardLevelID).toList();
    final fsIds = type346FilterSets.map((e) => e.filterSetId).toList();

    List<WallpaperScheduleRow> type346Schedules = [
      wallpaperSchedules.newRow(1, glIds[0], fsIds[0], WallpaperUpdateType.home),
      wallpaperSchedules.newRow(2, glIds[0], fsIds[2], WallpaperUpdateType.lock, intervalTime: 0),
      wallpaperSchedules.newRow(3, glIds[1], fsIds[1], WallpaperUpdateType.home),
      wallpaperSchedules.newRow(4, glIds[1], fsIds[2], WallpaperUpdateType.lock, intervalTime: 0),
      wallpaperSchedules.newRow(5, glIds[2], fsIds[3], WallpaperUpdateType.home),
      wallpaperSchedules.newRow(6, glIds[2], fsIds[3], WallpaperUpdateType.lock, intervalTime: 0),
    ];
    await wallpaperSchedules.add(type346Schedules.toSet());
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
    // final privacyGuardlevelMap = jsonDecode(jsonMap['privacyGuardLevel'].toList().first);
    // debugPrint('privacyGuardlevelMap = \n$privacyGuardlevelMap');
    // privacyGuardLevels.import(privacyGuardlevelMap);
  }
}