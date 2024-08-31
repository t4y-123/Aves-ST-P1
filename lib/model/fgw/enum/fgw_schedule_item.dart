import 'package:aves/model/fgw/filters_set.dart';
import 'package:aves/model/fgw/guard_level.dart';
import 'package:aves/model/fgw/wallpaper_schedule.dart';
import 'package:aves/widgets/common/extensions/build_context.dart';
import 'package:flutter/cupertino.dart';

// export and import
enum FgwExportItem { privacyGuardLevel, filtersSet, schedule }

extension ExtraFgwExportItem on FgwExportItem {
  dynamic export() {
    return switch (this) {
      FgwExportItem.privacyGuardLevel => fgwGuardLevels.export(),
      FgwExportItem.filtersSet => filtersSets.export(),
      FgwExportItem.schedule => fgwSchedules.export(),
    };
  }

  Future<void> import(dynamic jsonMap) async {
    switch (this) {
      case FgwExportItem.privacyGuardLevel:
        await fgwGuardLevels.import(jsonMap);
      case FgwExportItem.filtersSet:
        await filtersSets.import(jsonMap);
      case FgwExportItem.schedule:
        await fgwSchedules.import(jsonMap);
    }
  }
}

// for display the entries in a random order or most recent not used., as there may have a recent used record.
enum FgwDisplayedType { random, mostRecent }

extension ExtraFgwDisplayedTypeView on FgwDisplayedType {
  String getName(BuildContext context) {
    final l10n = context.l10n;
    return switch (this) {
      FgwDisplayedType.random => l10n.fgwDisplayRandom,
      FgwDisplayedType.mostRecent => l10n.fgwDisplayMostRecentNotUsed,
    };
  }
}

// for default schedule type : 3/4/6 for home and lock, o r3/3/3 for only home.Format: levelsCount/filtersCount/scheduleCount
enum FgwScheduleSetType { type346, type333 }

extension ExtraFgwScheduleSetType on FgwScheduleSetType {
  String getName(BuildContext context) {
    final l10n = context.l10n;
    return switch (this) {
      FgwScheduleSetType.type333 => l10n.fgwScheduleGroupSetType333,
      FgwScheduleSetType.type346 => l10n.fgwScheduleGroupSetType346,
    };
  }
}

enum WallpaperUpdateType { home, lock, both, widget }

extension ExtraWallpaperUpdateType on WallpaperUpdateType {
  String getName(BuildContext context) {
    final l10n = context.l10n;
    return switch (this) {
      WallpaperUpdateType.home => l10n.wallpaperUpdateTypeHome,
      WallpaperUpdateType.lock => l10n.wallpaperUpdateTypeLock,
      WallpaperUpdateType.both => l10n.wallpaperUpdateTypeBoth,
      WallpaperUpdateType.widget => l10n.wallpaperUpdateTypeWidget,
    };
  }
}
