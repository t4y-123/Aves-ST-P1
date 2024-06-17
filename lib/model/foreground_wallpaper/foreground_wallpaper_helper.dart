import 'dart:async';
import 'package:aves/model/foreground_wallpaper/filterSet.dart';
import 'package:aves/model/foreground_wallpaper/privacyGuardLevel.dart';
import 'package:aves/model/foreground_wallpaper/wallpaperSchedule.dart';
import 'package:aves/services/common/services.dart';
import 'package:flutter/painting.dart';
import '../filters/aspect_ratio.dart';
import '../filters/mime.dart';
final ForegroundWallpaperHelper foregroundWallpaperHelper = ForegroundWallpaperHelper._private();

class ForegroundWallpaperHelper {
  ForegroundWallpaperHelper._private();

  Future<void> initWallpaperSchedules() async {
    final currentWallpaperSchedules = await metadataDb.loadAllWallpaperSchedules();
    if (currentWallpaperSchedules.isEmpty) {
      //Must initializeSchedules For it will generate twice guard levels and filter sets.
      await initializeSchedules();
      await initializePrivacyGuardLevels();
      await initializeFilterSets();
    } else {
      await privacyGuardLevels.init();
      await filterSet.init();
      await wallpaperSchedules.init();
    }
  }

  Future<void> clearWallpaperSchedules() async {
      await privacyGuardLevels.clear();
      await filterSet.clear();
      await wallpaperSchedules.clear();
  }

  Future<void> initializePrivacyGuardLevels() async {
    await privacyGuardLevels.init();
    final currentLevels = await metadataDb.loadAllPrivacyGuardLevels();
    if (currentLevels.isEmpty) {
      final newLevels = generatePrivacyGuardLevels();
      await privacyGuardLevels.add(newLevels);
    }
  }

  Future<void> initializeFilterSets() async {
    await filterSet.init();
    final currentFilterSets = await metadataDb.loadAllFilterSet();
    if (currentFilterSets.isEmpty) {
      final newFilterSets = generateFilterSets();
      await filterSet.add(newFilterSets);
    }
  }

  Future<void> initializeSchedules() async {
    final newSchedules = generateSchedules();
    await wallpaperSchedules.add(newSchedules.toSet());
  }

  Set<PrivacyGuardLevelRow> generatePrivacyGuardLevels() {
    final int maxId = privacyGuardLevels.all.map((e) => e.privacyGuardLevelID).fold(0, (prev, next) => prev > next ? prev : next);
    final int maxGuardLevel = privacyGuardLevels.all.map((e) => e.guardLevel).fold(0, (prev, next) => prev > next ? prev : next);
    return {
      PrivacyGuardLevelRow(
        privacyGuardLevelID: maxId + 1,
        guardLevel: maxGuardLevel +1 ,
        aliasName: 'Exposure',
        color: privacyGuardLevels.all.isEmpty? const Color(0xFF808080): privacyGuardLevels.getRandomColor(), // Grey
        isActive: true,
      ),
      PrivacyGuardLevelRow(
        privacyGuardLevelID: maxId + 2,
        guardLevel: maxGuardLevel + 2,
        aliasName: 'Moderate',
        color: privacyGuardLevels.all.isEmpty? const Color(0xFF8D4FF8): privacyGuardLevels.getRandomColor(), // Purple
        isActive: true,
      ),
      PrivacyGuardLevelRow(
        privacyGuardLevelID: maxId + 3,
        guardLevel: maxGuardLevel + 3,
        aliasName: 'Safe',
        color:privacyGuardLevels.all.isEmpty? const Color(0xFF2986cc): privacyGuardLevels.getRandomColor(), // Blue
        isActive: true,
      ),
    };
  }

  Set<FilterSetRow> generateFilterSets() {
    final int maxId = filterSet.all.map((e) => e.filterSetId).fold(0, (prev, next) => prev > next ? prev : next);
    final int maxFilterSetNum = filterSet.all.map((e) => e.filterSetNum).fold(0, (prev, next) => prev > next ? prev : next);
    return {
      FilterSetRow(
        filterSetId: maxId + 1,
        filterSetNum: maxFilterSetNum + 1,
        aliasName: 'Home: Exposure',
        filters: {AspectRatioFilter.portrait, MimeFilter.image},
        isActive: true,
      ),
      FilterSetRow(
        filterSetId: maxId + 2,
        filterSetNum: maxFilterSetNum + 2,
        aliasName: 'Home: Moderate',
        filters: {AspectRatioFilter.portrait, MimeFilter.image},
        isActive: true,
      ),
      FilterSetRow(
        filterSetId: maxId + 3,
        filterSetNum: maxFilterSetNum + 3,
        aliasName: 'Lock: Moderate & Exposure',
        filters: {AspectRatioFilter.portrait, MimeFilter.image},
        isActive: true,
      ),
      FilterSetRow(
        filterSetId: maxId + 4,
        filterSetNum: maxFilterSetNum + 4,
        aliasName: 'Home: Safe',
        filters: {AspectRatioFilter.portrait, MimeFilter.image},
        isActive: true,
      ),
      FilterSetRow(
        filterSetId: maxId + 5,
        filterSetNum: maxFilterSetNum + 5,
        aliasName: 'Lock: Safe',
        filters: {AspectRatioFilter.portrait, MimeFilter.image},
        isActive: true,
      ),
    };
  }

  List<WallpaperScheduleRow> generateSchedules() {
    final int maxId = wallpaperSchedules.all.map((e) => e.id).fold(0, (prev, next) => prev > next ? prev : next);
    final int maxScheduleNum = wallpaperSchedules.all.map((e) => e.scheduleNum).fold(0, (prev, next) => prev > next ? prev : next);
    const int defaultInterval = 3; // seconds.

    // Retrieve dynamically generated privacy guard levels and filter sets
    final privacyGuardLevels = generatePrivacyGuardLevels();
    final filterSets = generateFilterSets();

    final List<int> privacyGuardLevelIds = privacyGuardLevels.map((e) => e.privacyGuardLevelID).toList();
    final List<int> filterSetIds = filterSets.map((e) => e.filterSetId).toList();

    return [
      WallpaperScheduleRow(
        id: maxId + 1,
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
        id: maxId + 2,
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
        id: maxId + 3,
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
        id: maxId + 4,
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
        id: maxId + 5,
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
        id: maxId + 6,
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
    // Must first generate Schedules.
    final newSchedules = generateSchedules();
    await wallpaperSchedules.add(newSchedules.toSet());

    final newLevels = generatePrivacyGuardLevels();
    await privacyGuardLevels.add(newLevels);

    final newFilterSets = generateFilterSets();
    await filterSet.add(newFilterSets);
  }
}
