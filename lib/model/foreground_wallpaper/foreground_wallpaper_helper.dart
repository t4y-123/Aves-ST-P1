import 'dart:async';
import 'package:aves/model/foreground_wallpaper/filterSet.dart';
import 'package:aves/model/foreground_wallpaper/privacyGuardLevel.dart';
import 'package:aves/model/foreground_wallpaper/wallpaperSchedule.dart';
import 'package:aves/services/common/services.dart';
import 'package:flutter/painting.dart';
import '../filters/aspect_ratio.dart';
import '../filters/mime.dart';
import '../settings/settings.dart';
import 'fgw_used_entry_record.dart';
final ForegroundWallpaperHelper foregroundWallpaperHelper = ForegroundWallpaperHelper._private();

class ForegroundWallpaperHelper {
  ForegroundWallpaperHelper._private();

  Future<void> initWallpaperSchedules() async {
    final currentWallpaperSchedules = await metadataDb.loadAllWallpaperSchedules();
    await privacyGuardLevels.init();
    await filterSet.init();
    await wallpaperSchedules.init();
    if (currentWallpaperSchedules.isEmpty) {
      await addDynamicSets();
    }
    await fgwUsedEntryRecord.init();
  }

  Future<void> clearWallpaperSchedules() async {
      await privacyGuardLevels.clear();
      await filterSet.clear();
      await wallpaperSchedules.clear();
      await fgwUsedEntryRecord.clear();
  }

  Set<PrivacyGuardLevelRow> generatePrivacyGuardLevels() {
    final int maxGuardLevel = privacyGuardLevels.all.isNotEmpty
        ? privacyGuardLevels.all.map((e) => e.guardLevel).fold(0, (prev, next) => prev > next ? prev : next)
    : 0;
    return {
      PrivacyGuardLevelRow(
        privacyGuardLevelID:  metadataDb.nextId,
        guardLevel: maxGuardLevel +1 ,
        aliasName: 'Exposure',
        color: privacyGuardLevels.all.isEmpty? const Color(0xFF808080): privacyGuardLevels.getRandomColor(), // Grey
        isActive: true,
      ),
      PrivacyGuardLevelRow(
        privacyGuardLevelID:  metadataDb.nextId,
        guardLevel: maxGuardLevel + 2,
        aliasName: 'Moderate',
        color: privacyGuardLevels.all.isEmpty? const Color(0xFF8D4FF8): privacyGuardLevels.getRandomColor(), // Purple
        isActive: true,
      ),
      PrivacyGuardLevelRow(
        privacyGuardLevelID: metadataDb.nextId,
        guardLevel: maxGuardLevel + 3,
        aliasName: 'Safe',
        color:privacyGuardLevels.all.isEmpty? const Color(0xFF2986cc): privacyGuardLevels.getRandomColor(), // Blue
        isActive: true,
      ),
    };
  }

  Set<FilterSetRow> generateFilterSets() {
    final int maxFilterSetNum = filterSet.all.isNotEmpty
        ? filterSet.all.map((e) => e.filterSetNum).fold(0, (prev, next) => prev > next ? prev : next)
        : 0;
    return {
      FilterSetRow(
        filterSetId: metadataDb.nextId,
        filterSetNum: maxFilterSetNum + 1,
        aliasName: 'Home: Exposure',
        filters: {AspectRatioFilter.portrait, MimeFilter.image},
        isActive: true,
      ),
      FilterSetRow(
        filterSetId: metadataDb.nextId,
        filterSetNum: maxFilterSetNum + 2,
        aliasName: 'Home: Moderate',
        filters: {AspectRatioFilter.portrait, MimeFilter.image},
        isActive: true,
      ),
      FilterSetRow(
        filterSetId: metadataDb.nextId,
        filterSetNum: maxFilterSetNum + 3,
        aliasName: 'Lock: Moderate & Exposure',
        filters: {AspectRatioFilter.portrait, MimeFilter.image},
        isActive: true,
      ),
      FilterSetRow(
        filterSetId: metadataDb.nextId,
        filterSetNum: maxFilterSetNum + 4,
        aliasName: 'Home: Safe',
        filters: {AspectRatioFilter.portrait, MimeFilter.image},
        isActive: true,
      ),
      FilterSetRow(
        filterSetId: metadataDb.nextId,
        filterSetNum: maxFilterSetNum + 5,
        aliasName: 'Lock: Safe',
        filters: {AspectRatioFilter.portrait, MimeFilter.image},
        isActive: true,
      ),
    };
  }

  List<WallpaperScheduleRow> generateSchedules(Set<PrivacyGuardLevelRow> privacyGuardLevels,Set<FilterSetRow> filterSets) {

    final int maxScheduleNum = wallpaperSchedules.all.isNotEmpty
        ? wallpaperSchedules.all.map((e) => e.scheduleNum).fold(0, (prev, next) => prev > next ? prev : next)
        : 0;
    final int defaultInterval = settings.defaultNewUpdateInterval; // seconds.

    final List<int> privacyGuardLevelIds = privacyGuardLevels.map((e) => e.privacyGuardLevelID).toList();
    final List<int> filterSetIds = filterSets.map((e) => e.filterSetId).toList();

    return [
      WallpaperScheduleRow(
        id: metadataDb.nextId,
        scheduleNum: maxScheduleNum + 1,
        aliasName: 'L${privacyGuardLevelIds[0]}-ID_${privacyGuardLevelIds[0]}-HOME',
        filterSetId: filterSetIds[0],
        privacyGuardLevelId: privacyGuardLevelIds[0],
        updateType: WallpaperUpdateType.home,
        widgetId: 0,
        intervalTime: defaultInterval,
        isActive: true,
      ),
      WallpaperScheduleRow(
        id: metadataDb.nextId,
        scheduleNum: maxScheduleNum + 2,
        aliasName: 'L${privacyGuardLevelIds[0]}-ID_${privacyGuardLevelIds[0]}-LOCK',
        filterSetId: filterSetIds[2],
        privacyGuardLevelId: privacyGuardLevelIds[0],
        updateType: WallpaperUpdateType.lock,
        widgetId: 0,
        intervalTime: 0,
        isActive: true,
      ),
      WallpaperScheduleRow(
        id: metadataDb.nextId,
        scheduleNum: maxScheduleNum + 3,
        aliasName: 'L${privacyGuardLevelIds[1]}-ID_${privacyGuardLevelIds[1]}-HOME',
        filterSetId: filterSetIds[1],
        privacyGuardLevelId: privacyGuardLevelIds[1],
        updateType: WallpaperUpdateType.home,
        widgetId: 0,
        intervalTime: defaultInterval,
        isActive: true,
      ),
      WallpaperScheduleRow(
        id: metadataDb.nextId,
        scheduleNum: maxScheduleNum + 4,
        aliasName: 'L${privacyGuardLevelIds[1]}-ID_${privacyGuardLevelIds[1]}-LOCK',
        filterSetId: filterSetIds[2],
        privacyGuardLevelId: privacyGuardLevelIds[1],
        updateType: WallpaperUpdateType.lock,
        widgetId: 0,
        intervalTime: 0,
        isActive: true,
      ),
      WallpaperScheduleRow(
        id: metadataDb.nextId,
        scheduleNum: maxScheduleNum + 5,
        aliasName: 'L${privacyGuardLevelIds[2]}-ID_${privacyGuardLevelIds[2]}-HOME',
        filterSetId: filterSetIds[3],
        privacyGuardLevelId: privacyGuardLevelIds[2],
        updateType: WallpaperUpdateType.home,
        widgetId: 0,
        intervalTime: defaultInterval,
        isActive: true,
      ),
      WallpaperScheduleRow(
        id: metadataDb.nextId,
        scheduleNum: maxScheduleNum + 6,
        aliasName: 'L${privacyGuardLevelIds[2]}-ID_${privacyGuardLevelIds[2]}-LOCK',
        filterSetId: filterSetIds[4],
        privacyGuardLevelId: privacyGuardLevelIds[2],
        updateType: WallpaperUpdateType.lock,
        widgetId: 0,
        intervalTime: 0,
        isActive: true,
      ),
    ];
  }

  Future<void> addDynamicSets() async {
    final newLevels = generatePrivacyGuardLevels();
    await privacyGuardLevels.add(newLevels);

    final newFilterSets = generateFilterSets();
    await filterSet.add(newFilterSets);

    final newSchedules = generateSchedules(newLevels,newFilterSets);
    await wallpaperSchedules.add(newSchedules.toSet());
  }
}
