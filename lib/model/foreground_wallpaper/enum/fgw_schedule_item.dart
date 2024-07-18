import 'package:aves/widgets/common/extensions/build_context.dart';
import 'package:flutter/cupertino.dart';

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
