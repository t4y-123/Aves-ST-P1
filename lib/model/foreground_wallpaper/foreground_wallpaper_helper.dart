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

final ForegroundWallpaperHelper foregroundWallpaperHelper = ForegroundWallpaperHelper._private();

class ForegroundWallpaperHelper  {
  ForegroundWallpaperHelper._private();

   Future<void> initWallpaperSchedules() async {
    // Initialize wallpaperSchedules and wallpaperScheduleDetails
    final currentWallpaperSchedules = await metadataDb.loadAllWallpaperSchedules();
    if (currentWallpaperSchedules.isEmpty) {
      await initializePrivacyGuardLevels(initialPrivacyGuardLevels);
      await wallpaperScheduleDetails.init();
      await initializeFilterSets(initialFilterSets);
      // Add schedule data to the database
      await wallpaperSchedules.add(scheduleData.toSet());
      // Add details data to the database
      await wallpaperScheduleDetails.add(detailsData.toSet());
    }else{
      await privacyGuardLevels.init();
      await filterSet.init();
      await wallpaperSchedules.init();
      await wallpaperScheduleDetails.init();
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

  static const int defaultInterval = 5; // seconds.

  // init Guard Levels first.
  final initialPrivacyGuardLevels = {
    const PrivacyGuardLevelRow(
      privacyGuardLevelID: 1,
      guardLevel: 1,
      aliasName: 'Exposure',
      color: Color(0xFFFF0000), // Red
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
      color: Color(0xFF7AB7EF), // Blue
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

  final scheduleData = [
    const WallpaperScheduleRow(
      id: 1,
      scheduleNum: 1,
      scheduleName: 'Home: Exposure',
      isActive: true,
    ),
    const WallpaperScheduleRow(
      id: 2,
      scheduleNum: 2,
      scheduleName: 'Home: Moderate',
      isActive: true,
    ),
    const WallpaperScheduleRow(
      id: 3,
      scheduleNum: 3,
      scheduleName: 'Lock: Exposure & Moderate',
      isActive: true,
    ),
    const WallpaperScheduleRow(
      id: 4,
      scheduleNum: 4,
      scheduleName: 'Home: Safe',
      isActive: true,
    ),
    const WallpaperScheduleRow(
      id: 5,
      scheduleNum: 5,
      scheduleName: 'Lock: Safe',
      isActive: true,
    ),
  ];
  // Details data
  final detailsData = [
    const WallpaperScheduleDetailRow(
      wallpaperScheduleDetailId: 1,
      wallpaperScheduleId: 1,
      filterSetId: 1,
      privacyGuardLevelId: 1,
      updateType: {WallpaperUpdateType.home},
      widgetId: 0,
      intervalTime: defaultInterval,
    ),
    const WallpaperScheduleDetailRow(
      wallpaperScheduleDetailId: 2,
      wallpaperScheduleId: 2,
      filterSetId: 2,
      privacyGuardLevelId: 2,
      updateType:  {WallpaperUpdateType.lock},
      widgetId: 0,
      intervalTime: defaultInterval,
    ),
    const WallpaperScheduleDetailRow(
      wallpaperScheduleDetailId: 3,
      wallpaperScheduleId: 3,
      filterSetId: 3,
      privacyGuardLevelId: 1,
      updateType:  {WallpaperUpdateType.lock},
      widgetId: 0,
      intervalTime: 0,
    ),
    const WallpaperScheduleDetailRow(
      wallpaperScheduleDetailId: 4,
      wallpaperScheduleId: 3,
      filterSetId: 3,
      privacyGuardLevelId: 2,
      updateType:  {WallpaperUpdateType.lock},
      widgetId: 0,
      intervalTime: 0,
    ),
    const WallpaperScheduleDetailRow(
      wallpaperScheduleDetailId: 5,
      wallpaperScheduleId: 4,
      filterSetId: 4,
      privacyGuardLevelId: 3,
      updateType:  {WallpaperUpdateType.home},
      widgetId: 0,
      intervalTime: defaultInterval,
    ),
    const WallpaperScheduleDetailRow(
      wallpaperScheduleDetailId: 6,
      wallpaperScheduleId: 5,
      filterSetId: 4,
      privacyGuardLevelId: 3,
      updateType: {WallpaperUpdateType.lock},
      widgetId: 0,
      intervalTime: 0,
    ),
  ];

}

