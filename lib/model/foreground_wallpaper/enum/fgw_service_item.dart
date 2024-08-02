import 'dart:convert';

import '../../source/collection_source.dart';
import '../fgw_schedule_helper.dart';
import '../privacy_guard_level.dart';
import 'fgw_schedule_item.dart';

enum FgwSyncItem { curLevel, activeLevels, schedules, curEntryName }


extension ExtraFgwSyncItem on FgwSyncItem {
  Future<dynamic> syncData(
      {CollectionSource? source,
      WallpaperUpdateType? updateType,
      int widgetId = 0,
      PrivacyGuardLevelRow? curPrivacyGuardLevel}) async {
    return switch (this) {
      // t4y: must!!!,not simply use toString, explicit use toJson or to map of each item will be better,
      // or else it will work fine in debug , but only return the name of the class in release apk ,not any props.
      // some how like :
      // [PrivacyGuardLevelRow, PrivacyGuardLevelRow, PrivacyGuardLevelRow]
      // [WallpaperScheduleRow, WallpaperScheduleRow]
      // so annoyance.
      FgwSyncItem.curLevel => (await fgwScheduleHelper.getCurGuardLevel()).guardLevel.toString(),
      FgwSyncItem.activeLevels =>
        privacyGuardLevels.all.where((e) => e.isActive).map((e) => e.toJson()).toList()
      ,
      FgwSyncItem.schedules =>
        (await fgwScheduleHelper.getCurActiveSchedules(curPrivacyGuardLevel: curPrivacyGuardLevel))
            .map((e) => e.toJson()).toList(),
      FgwSyncItem.curEntryName => (await fgwScheduleHelper.getCurEntry(
              source!, updateType!, widgetId: widgetId, curPrivacyGuardLevel: curPrivacyGuardLevel))
          .filenameWithoutExtension
          .toString(),
    };
  }
}

class FgwSyncActions {
  static const changeGuardLevel = 'changeGuardLevel';
  static const newGuardLevel = 'nweGuardLevel';
  static const curGuardLevel = 'curGuardLevel';
  static const curEntryFileName = 'curEntryFileName';
  static const activeLevels = 'activeLevels';
  static const schedules = 'schedules';
}

enum FgwServiceOpenType { usedRecord, curFilters, shareByCopy }
