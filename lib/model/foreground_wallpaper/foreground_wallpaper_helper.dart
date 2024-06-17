import 'dart:async';


import 'package:aves/model/foreground_wallpaper/filterSet.dart';
import 'package:aves/model/foreground_wallpaper/privacyGuardLevel.dart';
import 'package:aves/model/foreground_wallpaper/wallpaperSchedule.dart';
import 'package:aves/services/common/services.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

import '../filters/aspect_ratio.dart';
import '../filters/mime.dart';
import '../settings/settings.dart';

final ForegroundWallpaperHelper foregroundWallpaperHelper = ForegroundWallpaperHelper._private();

class ForegroundWallpaperHelper  {
  ForegroundWallpaperHelper._private();

   Future<void> initWallpaperSchedules() async {
    final currentWallpaperSchedules = await metadataDb.loadAllWallpaperSchedules();
    if (currentWallpaperSchedules.isEmpty) {
      await initializePrivacyGuardLevels(initialPrivacyGuardLevels);
      await initializeFilterSets(initialFilterSets);
      // Add schedule data to the database
      await wallpaperSchedules.add(scheduleData.toSet());
    }else{
      await privacyGuardLevels.init();
      await filterSet.init();
      await wallpaperSchedules.init();
    }
  }

  Future<void> initializeFilterSets(Set<FilterSetRow> initialFilterSets) async {
    await filterSet.init();
    final currentFilterSets = await metadataDb.loadAllFilterSet();
    if (currentFilterSets.isEmpty) {
      await filterSet.add(initialFilterSets);
    }
  }

  Future<void> initializePrivacyGuardLevels(Set<PrivacyGuardLevelRow> initialPrivacyGuardLevels) async {
    await privacyGuardLevels.init();
    final currentLevels = await metadataDb.loadAllPrivacyGuardLevels();
    if (currentLevels.isEmpty) {
      await privacyGuardLevels.add(initialPrivacyGuardLevels);
    }
  }

  // init Guard Levels first.
  final initialPrivacyGuardLevels = {
    const PrivacyGuardLevelRow(
      privacyGuardLevelID: 1,
      guardLevel: 1,
      aliasName: 'Exposure',
      color: Color(0xFF808080), // Grey
      isActive: true,
    ),
    const PrivacyGuardLevelRow(
      privacyGuardLevelID: 2,
      guardLevel: 2,
      aliasName: 'Moderate',
      color: Color(0xFF8D4FF8), // Purple
      isActive: true,
    ),
    const PrivacyGuardLevelRow(
      privacyGuardLevelID: 3,
      guardLevel: 3,
      aliasName: 'Safe',
      color: Color(0xFF2986cc), // Blue
      isActive: true,
    ),
  };

  // initiate FilterSet secondly.
  final initialFilterSets = {
    FilterSetRow(
      filterSetId: 1,
      filterSetNum: 1,
      aliasName: 'Home: Exposure',
      filters: {AspectRatioFilter.portrait, MimeFilter.image},
      isActive: true,
    ),
    FilterSetRow(
      filterSetId: 2,
      filterSetNum: 2,
      aliasName: 'Home: Moderate',
      filters: {AspectRatioFilter.portrait, MimeFilter.image},
      isActive: true,
    ),
    FilterSetRow(
      filterSetId: 3,
      filterSetNum: 3,
      aliasName: 'Lock: Moderate & Exposure',
      filters: {AspectRatioFilter.portrait, MimeFilter.image},
      isActive: true,
    ),
    FilterSetRow(
      filterSetId: 4,
      filterSetNum: 4,
      aliasName: 'Home: Safe',
      filters: {AspectRatioFilter.portrait, MimeFilter.image},
      isActive: true,
    ),
    FilterSetRow(
      filterSetId: 5,
      filterSetNum: 5,
      aliasName: 'Lock: Safe',
      filters: {AspectRatioFilter.portrait, MimeFilter.image},
      isActive: true,
    ),
  };

  // Third, make schedule.

  //Schedule data

  static const int defaultInterval = 3; // seconds.

  final scheduleData = [
    const WallpaperScheduleRow(
      id: 1,
      scheduleNum: 1,
      aliasName: 'L1-ID_1-HOME',
      filterSetId: 1,
      privacyGuardLevelId: 1,
      updateType: WallpaperUpdateType.home,
      widgetId: 0,
      intervalTime: defaultInterval,
      isActive: true,
    ),
    const WallpaperScheduleRow(
      id: 2,
      scheduleNum: 2,
      aliasName: 'L1-ID_1-LOCK',
      filterSetId: 3,
      privacyGuardLevelId: 1,
      updateType: WallpaperUpdateType.lock,
      widgetId: 0,
      intervalTime: 0,
      isActive: true,
    ),
    const WallpaperScheduleRow(
      id: 3,
      scheduleNum: 3,
      aliasName: 'L2-ID_2-HOME',
      filterSetId: 2,
      privacyGuardLevelId: 2,
      updateType: WallpaperUpdateType.home,
      widgetId: 0,
      intervalTime: defaultInterval,
      isActive: true,
    ),
    const WallpaperScheduleRow(
      id: 4,
      scheduleNum: 4,
      aliasName: 'L2-ID_2-LOCK',
      filterSetId: 3,
      privacyGuardLevelId: 2,
      updateType: WallpaperUpdateType.lock,
      widgetId: 0,
      intervalTime: 0,
      isActive: true,
    ),
    const WallpaperScheduleRow(
      id: 5,
      scheduleNum: 5,
      aliasName: 'L3-ID_3-HOME',
      filterSetId: 4,
      privacyGuardLevelId: 3,
      updateType: WallpaperUpdateType.home,
      widgetId: 0,
      intervalTime: defaultInterval,
      isActive: true,
    ),
    const WallpaperScheduleRow(
      id: 6,
      scheduleNum: 6,
      aliasName: 'L2-ID_2-LOCK',
      filterSetId: 5,
      privacyGuardLevelId: 3,
      updateType: WallpaperUpdateType.lock,
      widgetId: 0,
      intervalTime: 0,
      isActive: true,
    ),
  ];
}

