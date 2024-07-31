import '../../source/collection_source.dart';
import '../fgw_schedule_helper.dart';
import '../privacy_guard_level.dart';
import 'fgw_schedule_item.dart';

enum FgwSyncItem { curLevel, activeLevels, schedules, curEntryName }

extension ExtraFgwSyncItem on FgwSyncItem {
  dynamic syncData (
      {CollectionSource? source,
        WallpaperUpdateType? updateType,
        int widgetId = 0,
        PrivacyGuardLevelRow? curPrivacyGuardLevel}) async {
    return switch (this) {
    // TODO: Handle this case.
      FgwSyncItem.curLevel => (await fgwScheduleHelper.getCurGuardLevel()).guardLevel.toString(),
      FgwSyncItem.activeLevels => privacyGuardLevels.all.where((e) => e.isActive).toList().toString(),
      FgwSyncItem.schedules => (await fgwScheduleHelper.getCurActiveSchedules(curPrivacyGuardLevel: curPrivacyGuardLevel)).toList().toString(),
    // TODO: Handle this case.
      FgwSyncItem.curEntryName => (await fgwScheduleHelper.getCurEntry(source!, updateType!,
          widgetId: widgetId, curPrivacyGuardLevel: curPrivacyGuardLevel)).filenameWithoutExtension.toString(),
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
