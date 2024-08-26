import 'dart:async';
import 'dart:convert';

import 'package:aves/model/foreground_wallpaper/filtersSet.dart';
import 'package:aves/model/foreground_wallpaper/privacy_guard_level.dart';
import 'package:aves/model/foreground_wallpaper/wallpaper_schedule.dart';
import 'package:collection/collection.dart';
import 'package:flutter/cupertino.dart';

import '../../l10n/l10n.dart';
import '../settings/settings.dart';
import 'enum/fgw_schedule_item.dart';
import 'fgw_used_entry_record.dart';

final ForegroundWallpaperHelper foregroundWallpaperHelper = ForegroundWallpaperHelper._private();

class ForegroundWallpaperHelper {
  ForegroundWallpaperHelper._private();
  late AppLocalizations? _l10n;

  Future<void> initWallpaperSchedules({FgwScheduleSetType? fgwScheduleSetType}) async {
    _l10n = await AppLocalizations.delegate.load(settings.appliedLocale);
    fgwScheduleSetType ??= settings.fgwScheduleSet;
    await privacyGuardLevels.init();
    await filtersSets.init();
    await wallpaperSchedules.init();
    if (wallpaperSchedules.all.isEmpty && privacyGuardLevels.all.isEmpty && filtersSets.all.isEmpty) {
      await addDefaultScheduleSet(fgwScheduleSetType: fgwScheduleSetType);
    }
    await fgwUsedEntryRecord.init();
  }

  Future<void> clearWallpaperSchedules() async {
    await privacyGuardLevels.clear();
    await filtersSets.clear();
    await wallpaperSchedules.clear();
    await fgwUsedEntryRecord.clear();
  }

  Future<Set<PrivacyGuardLevelRow>> commonType3GuardLevels(AppLocalizations _l10n) async {
    return {
      await privacyGuardLevels.newRow(1,
          labelName: _l10n.initGuardLevelName01,
          newColor: privacyGuardLevels.all.isEmpty ? const Color(0xFF808080) : null),
      await privacyGuardLevels.newRow(2,
          labelName: _l10n.initGuardLevelName02,
          newColor: privacyGuardLevels.all.isEmpty ? const Color(0xFF8D4FF8) : null),
      await privacyGuardLevels.newRow(3,
          labelName: _l10n.initGuardLevelName03,
          newColor: privacyGuardLevels.all.isEmpty ? const Color(0xFF2986cc) : null),
    };
  }

  // 3level, 4filters set, 6 schedule. for default both home and lock screen wallpaper .
  Future<void> addDefaultScheduleSet({FgwScheduleSetType? fgwScheduleSetType}) async {
    _l10n = await AppLocalizations.delegate.load(settings.appliedLocale);
    final newLevels = await commonType3GuardLevels(_l10n!);
    fgwScheduleSetType ??= settings.fgwScheduleSet;
    Set<FiltersSetRow> initFiltersSets = switch (fgwScheduleSetType) {
      FgwScheduleSetType.type346 => {
          filtersSets.newRow(1, labelName: filtersSets.all.isEmpty ? _l10n?.initFiltersSet346Name01 : null),
          filtersSets.newRow(2, labelName: filtersSets.all.isEmpty ? _l10n?.initFiltersSet346Name02 : null),
          filtersSets.newRow(3, labelName: filtersSets.all.isEmpty ? _l10n?.initFiltersSet346Name03 : null),
          filtersSets.newRow(4, labelName: filtersSets.all.isEmpty ? _l10n?.initFiltersSet346Name04 : null),
        },
      FgwScheduleSetType.type333 => {
          filtersSets.newRow(1, labelName: filtersSets.all.isEmpty ? _l10n?.initFiltersSet333Name01 : null),
          filtersSets.newRow(2, labelName: filtersSets.all.isEmpty ? _l10n?.initFiltersSet333Name02 : null),
          filtersSets.newRow(3, labelName: filtersSets.all.isEmpty ? _l10n?.initFiltersSet333Name03 : null),
        },
    };

    // must add first, for wallpaperSchedules.newRow will try to get item form them.
    await privacyGuardLevels.add(newLevels);
    await filtersSets.add(initFiltersSets);

    final glIds = privacyGuardLevels.all.map((e) => e.privacyGuardLevelID).toList();
    final fsIds = initFiltersSets.map((e) => e.id).toList();
    int homeExposureSeconds = 15;
    int homeModerateSeconds = 3 * 60;
    int homeSafeSeconds = 30 * 60;
    List<WallpaperScheduleRow> type346Schedules = switch (fgwScheduleSetType) {
      FgwScheduleSetType.type346 => [
          // in type 346, only make the home lock screen wallpaper active.
          // home screen: 0-3 :lock screen.
          // home screen: 1-3 :lock screen.
          // home screen: 2-2 :lock screen.
          // use diff filters set in differ home screen, use a diff 4th filters set in lock screen.
          // 15 seconds for exposure.
          newSchedule(1, glIds[0], fsIds[0], WallpaperUpdateType.home, homeExposureSeconds),
          newSchedule(2, glIds[0], fsIds[3], WallpaperUpdateType.lock, 0),
          newSchedule(3, glIds[0], fsIds[0], WallpaperUpdateType.both, 0, false),
          // 3min for moderate
          newSchedule(4, glIds[1], fsIds[1], WallpaperUpdateType.home, homeModerateSeconds),
          newSchedule(5, glIds[1], fsIds[3], WallpaperUpdateType.lock, 0),
          newSchedule(6, glIds[1], fsIds[1], WallpaperUpdateType.both, 0, false),
          // 30 min for safe
          newSchedule(7, glIds[2], fsIds[2], WallpaperUpdateType.home, homeSafeSeconds),
          newSchedule(8, glIds[2], fsIds[2], WallpaperUpdateType.lock, 0),
          newSchedule(9, glIds[2], fsIds[2], WallpaperUpdateType.both, 0, false),
        ],
      FgwScheduleSetType.type333 => [
          // in type 333, only make the home screen wallpaper active.
          newSchedule(1, glIds[0], fsIds[0], WallpaperUpdateType.home, homeExposureSeconds),
          newSchedule(2, glIds[0], fsIds[0], WallpaperUpdateType.lock, 0, false),
          newSchedule(3, glIds[0], fsIds[0], WallpaperUpdateType.both, 0, false),

          newSchedule(4, glIds[1], fsIds[1], WallpaperUpdateType.home, homeModerateSeconds),
          newSchedule(5, glIds[1], fsIds[1], WallpaperUpdateType.lock, 0, false),
          newSchedule(6, glIds[1], fsIds[1], WallpaperUpdateType.both, 0, false),

          newSchedule(7, glIds[2], fsIds[2], WallpaperUpdateType.home, homeSafeSeconds),
          newSchedule(8, glIds[2], fsIds[2], WallpaperUpdateType.lock, 0, false),
          newSchedule(9, glIds[2], fsIds[2], WallpaperUpdateType.both, 0, false),
        ],
    };
    await wallpaperSchedules.add(type346Schedules.toSet());
  }

  Future<List<WallpaperScheduleRow>> newSchedulesGroup(PrivacyGuardLevelRow levelRow,
      {ScheduleRowType rowsType = ScheduleRowType.all, FiltersSetRow? filtersRow}) async {
    debugPrint('$runtimeType newSchedulesGroup start:\n$levelRow \n $rowsType \n $filtersRow ');
    filtersRow ??= filtersSets.all.first;
    if (filtersRow != null) {
      List<WallpaperScheduleRow> newSchedules = [
        newSchedule(1, levelRow.privacyGuardLevelID, filtersRow.id, WallpaperUpdateType.home, 30, false, rowsType),
        newSchedule(2, levelRow.privacyGuardLevelID, filtersRow.id, WallpaperUpdateType.lock, 0, false, rowsType),
        newSchedule(3, levelRow.privacyGuardLevelID, filtersRow.id, WallpaperUpdateType.both, 0, false, rowsType),
      ];
      debugPrint('newSchedulesGroup =\n $newSchedules');
      return newSchedules;
    }
    return [];
  }

  WallpaperScheduleRow newSchedule(int offset, int levelId, int filtersSetId, updateType,
      [int? interval, bool isActive = true, ScheduleRowType type = ScheduleRowType.all]) {
    return wallpaperSchedules.newRow(
      existMaxOrderNumOffset: offset,
      privacyGuardLevelId: levelId,
      filtersSetId: filtersSetId,
      updateType: updateType,
      interval: interval,
      isActive: isActive,
      type: type,
    );
  }

  // import/export
  Map<String, List<String>>? export() {
    final fgwMap = Map.fromEntries(FgwExportItem.values.map((v) {
      final jsonMap = [jsonEncode(v.export())];
      return jsonMap != null ? MapEntry(v.name, jsonMap) : null;
    }).whereNotNull());
    return fgwMap;
  }

  Future<void> import(dynamic jsonMap) async {
    debugPrint('foregroundWallpaperHelper import json Map $jsonMap');
    if (jsonMap is! Map) {
      debugPrint('failed to import privacy guard levels for jsonMap=$jsonMap');
      return;
    }
    await Future.forEach<FgwExportItem>(FgwExportItem.values, (item) async {
      debugPrint('\nFgwExportItem item $item ${jsonMap[item.name]}');
      return item.import(jsonDecode(jsonMap[item.name].toList().first));
    });
  }
}
