import 'dart:async';

import 'package:aves/l10n/l10n.dart';
import 'package:aves/model/entry/entry.dart';
import 'package:aves/model/entry/sort.dart';
import 'package:aves/model/fgw/enum/fgw_schedule_item.dart';
import 'package:aves/model/fgw/enum/fgw_service_item.dart';
import 'package:aves/model/fgw/fgw_schedule_helper.dart';
import 'package:aves/model/fgw/fgw_used_entry_record.dart';
import 'package:aves/model/fgw/filters_set.dart';
import 'package:aves/model/fgw/guard_level.dart';
import 'package:aves/model/fgw/wallpaper_schedule.dart';
import 'package:aves/model/settings/settings.dart';
import 'package:aves/model/source/collection_lens.dart';
import 'package:aves/model/source/media_store_source.dart';
import 'package:aves/services/common/services.dart';
import 'package:aves/utils/android_file_utils.dart';
import 'package:aves/utils/collection_utils.dart';
import 'package:aves/widgets/common/action_mixins/feedback.dart';
import 'package:collection/collection.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

const _opChannel = MethodChannel('deckers.thibault/aves/fgw_service_notification_op');
const _syncDataChannel = MethodChannel('deckers.thibault/aves/fgw_service_notification_sync');

enum FgwServiceWallpaperType { next, pre }

Future<void> fgwNotificationServiceAsync() async {
  WidgetsFlutterBinding.ensureInitialized();
  initPlatformServices();
  await settings.init(monitorPlatformSettings: false);
  await reportService.init();

  _opChannel.setMethodCallHandler((call) async {
    // widget settings may be modified in a different process after channel setup
    await settings.reload();

    debugPrint('fgwServiceHelper $call ');
    switch (call.method) {
      case 'start':
        await fgwServiceHelper.start();
        return Future.value(true);
      case 'nextWallpaper':
        return await fgwServiceHelper.handleWallpaper(call.arguments, FgwServiceWallpaperType.next);
      case 'preWallpaper':
        return await fgwServiceHelper.handleWallpaper(call.arguments, FgwServiceWallpaperType.pre);
      case 'changeGuardLevel':
        return await fgwServiceHelper.changeGuardLevel(call.arguments);
      case 'syncFgwScheduleChanges':
        // after sync new schedules, right away make next wallpaper
        return await fgwServiceHelper.syncFgwScheduleChanges();
      case 'fgwLock':
        settings.guardLevelLock = true;
        return Future.value(true);
      default:
        throw PlatformException(code: 'not-implemented', message: 'failed to handle method=${call.method}');
    }
  });
}

final FgwServiceHelper fgwServiceHelper = FgwServiceHelper._private();

class FgwServiceHelper with FeedbackMixin {
  late AppLocalizations _l10n;
  final _source = MediaStoreSource();
// Add this to FgwServiceHelper class

  static const notificationUpdateInterval = Duration(seconds: 1);

  FgwServiceHelper._private();

  Future<void> _initDependencies() async {
    await androidFileUtils.init();
    await localMediaDb.init();
    final readyCompleter = Completer();
    _source.stateNotifier.addListener(() {
      if (_source.isReady && !readyCompleter.isCompleted) {
        readyCompleter.complete();
      }
    });
    await _source.init(canAnalyze: false);

    await readyCompleter.future;
    // debugPrint('FgwServiceHelper readyCompleter.future ');

    settings.systemLocalesFallback = await deviceService.getLocales();
    _l10n = await AppLocalizations.delegate.load(settings.appliedLocale);
  }

  Future<void> start() async {
    await reportService.log('FgwServiceHelper in start');
    await _initDependencies();
    await syncDataToNative(
        {FgwSyncItem.curLevel, FgwSyncItem.activeLevels, FgwSyncItem.schedules, FgwSyncItem.guardLevelLock});
  }

  Future<void> syncDataToNative(Set<FgwSyncItem> syncItems,
      {WallpaperUpdateType updateType = WallpaperUpdateType.home, int widgetId = 0}) async {
    await reportService.log('syncDataToNative in start');
    await _initDependencies();
    final curLevel = await fgwScheduleHelper.getCurGuardLevel();

    final syncDataMap = Map.fromEntries((await Future.wait(syncItems.map((v) async {
      final data = await v.syncData(
        source: _source,
        updateType: updateType,
        widgetId: widgetId,
        curFgwGuardLevel: curLevel,
        guardLevelLock: settings.guardLevelLock,
      );

      final returnData = MapEntry(v.name, data);
      debugPrint('$runtimeType syncDataToKotlin data: $data');
      return returnData;
    })))
        .cast<MapEntry<String, dynamic>>());

    final syncData = syncDataMap.map((key, value) => MapEntry(key, (value)));

    try {
      await _syncDataChannel.invokeMethod('syncDataToKotlin', syncData);
      debugPrint('$runtimeType syncDataToKotlin result: $syncData');
    } catch (e) {
      debugPrint('$runtimeType syncDataToKotlin error: $e');
    }
  }

  Future<bool> handleWallpaper(dynamic args, FgwServiceWallpaperType fgwWallpaperType) async {
    await reportService.log('handleWallpaper $args $fgwWallpaperType');
    await _initDependencies();
    final updateType = WallpaperUpdateType.values.safeByName(args['updateType'] as String, WallpaperUpdateType.home);
    final widgetId = args['widgetId'] as int;
    try {
      final curLevel =
          fgwGuardLevels.all.firstWhereOrNull((e) => e.guardLevel == settings.curFgwGuardLevelNum && e.isActive);
      // debugPrint('$widgetId handleWallpaper curLevel [$curLevel]');
      // Ensure map is initialized
      final emptyMessage = _l10n.fgwScheduleEntryEmptyMessage(
          'Level[${settings.curFgwGuardLevelNum}-$updateType-$widgetId] in ${curLevel?.toMap()}');

      if (curLevel == null) {
        await showToast(emptyMessage);
        throw 'Failed to get for widgetId $widgetId }';
      }
      final curSchedule = fgwSchedules.all.firstWhereOrNull((e) => e.guardLevelId == curLevel.id && e.isActive);
      if (curSchedule == null) {
        await showToast(emptyMessage);
        throw 'Failed to get for widgetId $widgetId with curLevel ${curLevel.toMap()}';
      }
      final curFilters = filtersSets.all.firstWhereOrNull((e) => e.id == curSchedule.filtersSetId);
      if (curFilters == null) {
        await showToast(emptyMessage);
        throw 'Failed to get for widgetId $widgetId with \n'
            'curLevel ${curLevel.toMap()} with \n'
            'curSchedule:${curSchedule.toMap()}';
      }
      final fgwEntries =
          CollectionLens(source: _source, filters: curFilters.filters, useScenario: settings.canScenarioAffectFgw)
              .sortedEntries;
      //debugPrint('$widgetId handleWallpaper fgwEntries ${fgwEntries.length}: [$fgwEntries]');
      if (fgwEntries.isEmpty) {
        await showToast(emptyMessage);
        throw 'Failed to get for widgetId $widgetId with \n'
            'curLevel ${curLevel.toMap()} with \n'
            'curSchedule:${curSchedule.toMap()} with\n'
            'ccuFilters:{${curFilters.toMap()}}';
      }
      if (fgwEntries.isNotEmpty) {
        switch (curSchedule.displayType) {
          case FgwDisplayedType.random:
            fgwEntries.shuffle();
            break;
          case FgwDisplayedType.mostRecent:
            fgwEntries.sort(AvesEntrySort.compareByDate);
            break;
        }
        final recentUsedEntryRecord = fgwUsedEntryRecord.all
            .where((e) => e.widgetId == widgetId && e.guardLevelId == curLevel.id && e.updateType == updateType)
            .toList();
        AvesEntry? fgwEntry;
        // debugPrint(
        //     '$widgetId handleWallpaper recentUsedEntryRecord entries length [${recentUsedEntryRecord.length}]');
        switch (fgwWallpaperType) {
          case FgwServiceWallpaperType.next:
            fgwEntry = fgwEntries.firstWhereOrNull(
              (entry) => !recentUsedEntryRecord.any((usedEntry) => usedEntry.entryId == entry.id),
            );
            fgwEntry ??= fgwEntries.first;
          case FgwServiceWallpaperType.pre:
            fgwEntry = await fgwScheduleHelper.getPreviousEntry(_source, updateType,
                entries: fgwEntries, recentUsedEntryRecord: recentUsedEntryRecord);
        }
        if (fgwEntry == null) {
          throw 'Failed to get for widgetId $widgetId with \n'
              'curLevel ${curLevel.toMap()} with \n'
              'curSchedule:${curSchedule.toMap()} with\n'
              'ccuFilters:{${curFilters.toMap()}} \n'
              'fgwWallpaperType:$fgwWallpaperType\n'
              'fgwEntries.length:${fgwEntries.length}';
        }
        await fgwScheduleHelper.setFgWallpaper(fgwEntry, updateType: updateType, widgetId: widgetId);

        if (fgwWallpaperType == FgwServiceWallpaperType.next) {
          //debugPrint('$widgetId calling addAvesEntry fgwEntry: $fgwEntry');
          await fgwUsedEntryRecord.addAvesEntry(fgwEntry, updateType, widgetId: widgetId, curLevel: curLevel);
        }
        fgwScheduleHelper.updateCurEntrySettings(updateType, widgetId, fgwEntry);

        //await syncDataToKotlin(updateType,widgetId);
        unawaited(syncDataToNative({FgwSyncItem.curEntryName}, updateType: updateType, widgetId: widgetId));
        //unawaited(syncDataToNative(FgwSyncItem.values.toSet(),updateType: updateType,widgetId:  widgetId));
        return Future.value(true);
      }
    } catch (e) {
      debugPrint('Error in handleWallpaper _getWidgetEntry for widgetId $widgetId: $e');
      return Future.value(false);
    }
    return Future.value(false);
  }

  Future<bool> changeGuardLevel(dynamic args) async {
    await reportService.log('$runtimeType changeGuardLevel args: $args');
    if (args.containsKey('newGuardLevel')) {
      //debugPrint('$runtimeType newGuardLevel is present: ${args['newGuardLevel']}');
    } else {
      debugPrint('$runtimeType newGuardLevel is missing!');
      return false;
    }
    final newGuardLevel = args['newGuardLevel'] as int;
    await _initDependencies();
    await settings.reload();
    //debugPrint('$runtimeType changeGuardLevel newGuardLevel $newGuardLevel');
    // final activeLevels = await fgwScheduleHelper.getActiveLevels();
    final activeLevel = fgwGuardLevels.all.where((e) => e.isActive);
    if (activeLevel.any((item) => item.guardLevel == newGuardLevel)) {
      // let the kotlin side to call sync schedules.
      // var curLevel = _activeLevels.firstWhereOrNull((e) => e.guardLevel == settings.curFgwGuardLevelNum);
      // curLevel ??= _activeLevels.first;
      settings.curFgwGuardLevelNum = newGuardLevel;
      await syncDataToNative({FgwSyncItem.curLevel, FgwSyncItem.activeLevels, FgwSyncItem.schedules});
      // for (final updateType in [WallpaperUpdateType.home, WallpaperUpdateType.lock, WallpaperUpdateType.both]) {
      //   final key = '${settings.curFgwGuardLevelNum}-${updateType.name}-0'; // Assuming widgetId = 0
      //   debugPrint('check key: $key in $_schedules');
      //   // if (_schedules.containsKey(key)) {
      //   //   await (handleWallpaper(<String, dynamic>{'updateType': key, 'widgetId': 0}, FgwServiceWallpaperType.next));
      //   // }
      // }
      return Future.value(true);
    } else {
      throw Exception('Invalid guard level [$newGuardLevel] for \n${activeLevel.map((e) => e.toMap())}');
    }
  }

  Future<bool> syncFgwScheduleChanges() async {
    debugPrint('$runtimeType flutter syncFgwScheduleChanges start');
    await settings.reload();
    await fgwScheduleHelper.refreshSchedules();
    await _initDependencies();
    await syncDataToNative({FgwSyncItem.curLevel, FgwSyncItem.activeLevels, FgwSyncItem.schedules});
    // for (final updateType in [WallpaperUpdateType.home, WallpaperUpdateType.lock, WallpaperUpdateType.both]) {
    //   final key = '${settings.curFgwGuardLevelNum}-${updateType.name}-0'; // Assuming widgetId = 0
    //   debugPrint('check key: $key in $_schedules');
    //   if (_schedules.containsKey(key)) {
    //     await (handleWallpaper(<String, dynamic>{'updateType': key, 'widgetId': 0}, FgwServiceWallpaperType.next));
    //   }
    // }
    // unawaited(handleWallpaper(<String, dynamic>{'updateType': WallpaperUpdateType.home.toString(), 'widgetId': 0},
    //     FgwServiceWallpaperType.next));
    return Future.value(true);
  }

  Future<void> showToast(String message) async {
    try {
      await _syncDataChannel.invokeMethod('showToast', {'message': message});
    } catch (e) {
      debugPrint('Failed to show toast: $e');
    }
  }
}
