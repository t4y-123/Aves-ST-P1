import 'package:aves/model/fgw/enum/fgw_schedule_item.dart';
import 'package:aves/model/fgw/fgw_schedule_helper.dart';
import 'package:aves/model/fgw/guard_level.dart';
import 'package:aves/model/source/collection_source.dart';

enum FgwSyncItem { curLevel, activeLevels, schedules, curEntryName, guardLevelLock }

extension ExtraFgwSyncItem on FgwSyncItem {
  Future<dynamic> syncData(
      {CollectionSource? source,
      WallpaperUpdateType? updateType,
      int widgetId = 0,
      FgwGuardLevelRow? curFgwGuardLevel,
      bool guardLevelLock = false}) async {
    return switch (this) {
      // t4y: must!!!,not simply use toString, explicit use toJson or to map of each item will be better,
      // or else it will work fine in debug , but only return the name of the class in release apk ,not any props.
      // some how like :
      // [FgwGuardLevelRow, FgwGuardLevelRow, FgwGuardLevelRow]
      // [WallpaperScheduleRow, WallpaperScheduleRow]
      // so annoyance.
      FgwSyncItem.curLevel => (await fgwScheduleHelper.getCurGuardLevel()).guardLevel.toString(),
      FgwSyncItem.activeLevels => fgwGuardLevels.all.where((e) => e.isActive).map((e) => e.toJson()).toList(),
      FgwSyncItem.schedules => (await fgwScheduleHelper.getCurActiveSchedules(curFgwGuardLevel: curFgwGuardLevel))
          .map((e) => e.toJson())
          .toList(),
      FgwSyncItem.curEntryName => (await fgwScheduleHelper.getCurEntry(source!, updateType!,
              widgetId: widgetId, curFgwGuardLevel: curFgwGuardLevel))
          .filenameWithoutExtension
          .toString(),
      FgwSyncItem.guardLevelLock => guardLevelLock,
    };
  }
}

class FgwSyncActions {
  static const changeGuardLevel = 'changeGuardLevel';
  static const newGuardLevel = 'nweGuardLevel';
  static const curGuardLevel = 'curGuardLevel';
  static const curEntryFileName = 'curEntryFileName';
  static const guardLevelLock = 'guardLevelLock';
  static const activeLevels = 'activeLevels';
  static const schedules = 'schedules';
}

enum FgwServiceOpenType { usedRecord, curFilters, shareByCopy }
