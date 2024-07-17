import '../filtersSet.dart';
import '../privacy_guard_level.dart';
import '../wallpaper_schedule.dart';


enum FgwExportItem { privacyGuardLevel, filtersSet, schedule }

extension ExtraAppExportItem on FgwExportItem {

  dynamic export() {
    return switch (this) {
      FgwExportItem.privacyGuardLevel => privacyGuardLevels.export(),
      FgwExportItem.filtersSet => filtersSets.export(),
      FgwExportItem.schedule => wallpaperSchedules.export(),
    };
  }

  Future<void> import(dynamic jsonMap) async {
    switch (this) {
      case FgwExportItem.privacyGuardLevel:
        await privacyGuardLevels.import(jsonMap);
      case FgwExportItem.filtersSet:
        await filtersSets.import(jsonMap);
      case FgwExportItem.schedule:
        await wallpaperSchedules.import(jsonMap);
    }
  }
}