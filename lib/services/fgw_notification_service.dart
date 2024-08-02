import 'dart:async';
import 'package:aves/model/foreground_wallpaper/wallpaper_schedule.dart';
import 'package:aves/model/settings/settings.dart';
import 'package:aves/model/source/media_store_source.dart';
import 'package:aves/services/common/services.dart';
import 'package:aves/utils/android_file_utils.dart';
import 'package:aves/utils/collection_utils.dart';
import 'package:collection/collection.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import '../l10n/l10n.dart';
import '../model/entry/entry.dart';
import '../model/entry/sort.dart';
import '../model/foreground_wallpaper/enum/fgw_schedule_item.dart';
import '../model/foreground_wallpaper/enum/fgw_service_item.dart';
import '../model/foreground_wallpaper/fgw_schedule_helper.dart';
import '../model/foreground_wallpaper/fgw_used_entry_record.dart';
import '../widgets/common/action_mixins/feedback.dart';

const _opChannel = MethodChannel('deckers.thibault/aves/fgw_service_notification_op');
const _syncDataChannel = MethodChannel('deckers.thibault/aves/fgw_service_notification_sync');

enum FgwServiceWallpaperType {next, pre}

Future<void> fgwNotificationServiceAsync() async {
  // WidgetsFlutterBinding.ensureInitialized();
  // initPlatformServices();
  // await androidFileUtils.init();
  // await metadataDb.init();
  // await device.init();
  // await mobileServices.init();
  // await settings.init(monitorPlatformSettings: true);
  // await reportService.init();
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
      default:
        throw PlatformException(code: 'not-implemented', message: 'failed to handle method=${call.method}');
    }

  });
}

final FgwServiceHelper fgwServiceHelper = FgwServiceHelper._private();

class FgwServiceHelper with FeedbackMixin{
  late AppLocalizations _l10n;
  final _source = MediaStoreSource();

  static const notificationUpdateInterval = Duration(seconds: 1);

  FgwServiceHelper._private();

  Future<void> _initDependencies() async {
    await androidFileUtils.init();
    await metadataDb.init();
    final readyCompleter = Completer();
    _source.stateNotifier.addListener(() {
      if (_source.isReady && !readyCompleter.isCompleted) {
        readyCompleter.complete();
      }
    });
    debugPrint(' await _source.init(canAnalyze: false);');
    await _source.init(canAnalyze: false);

    debugPrint(' await readyCompleter.future;,');

    await readyCompleter.future;
    debugPrint('FgwServiceHelper readyCompleter.future ');

    settings.systemLocalesFallback = await deviceService.getLocales();
    _l10n = await AppLocalizations.delegate.load(settings.appliedLocale);
  }

  Future<void> start() async {
    await reportService.log('FgwServiceHelper in start');
    await _initDependencies();
    await syncDataToNative({FgwSyncItem.curLevel,FgwSyncItem.activeLevels,FgwSyncItem.schedules});
    unawaited(handleWallpaper(<String,dynamic>{ 'updateType' : WallpaperUpdateType.home.toString(), 'widgetId': 0},
        FgwServiceWallpaperType.next));
  }

  Future<void> syncDataToNative(Set<FgwSyncItem> syncItems,
      { WallpaperUpdateType updateType = WallpaperUpdateType.home, int widgetId = 0}) async {
    await reportService.log('syncDataToNative in start');
    await _initDependencies();
    debugPrint('$runtimeType syncDataToKotlin start');
    final curLevel = await fgwScheduleHelper.getCurGuardLevel();

    final syncDataMap = Map.fromEntries((await Future.wait(syncItems.map((v) async {
      final data = await v.syncData(
        source: _source,
        updateType: updateType,
        widgetId: widgetId,
        curPrivacyGuardLevel: curLevel,
      );
      debugPrint('$runtimeType syncDataToKotlin data: $data');
      return data != null ? MapEntry(v.name, data) : null;
    }))).where((entry) => entry != null).cast<MapEntry<String, dynamic>>());

    final syncData = syncDataMap.map((key, value) => MapEntry(key, (value)));

    try {
      await _syncDataChannel.invokeMethod('syncDataToKotlin', syncData);
      debugPrint('$runtimeType syncDataToKotlin result: $syncData');
    } catch (e) {
      debugPrint('$runtimeType syncDataToKotlin error: $e');
    }
  }

  Future<bool> handleWallpaper(dynamic args, FgwServiceWallpaperType fgwWallpaperType) async {
    debugPrint('handleWallpaper $args $fgwWallpaperType');
    await _initDependencies();
    final updateType = WallpaperUpdateType.values.safeByName(args['updateType'] as String, WallpaperUpdateType.home);
    final widgetId = args['widgetId'] as int;
    final curLevel = await fgwScheduleHelper.getCurGuardLevel();
    final entries = await fgwScheduleHelper.getScheduleEntries(_source, updateType,curPrivacyGuardLevel: curLevel);
    if(entries.isEmpty){
      final guardLevel = await fgwScheduleHelper.getCurGuardLevel();
      final emptyMessage = _l10n.fgwScheduleEntryEmptyMessage('Level[${guardLevel.guardLevel}][$updateType]');
      await showToast(emptyMessage);
      return Future.value(false);
    }
    final recentUsedEntryRecord = await fgwScheduleHelper.getRecentEntryRecord(updateType);

    final curDisplayType = wallpaperSchedules.all.firstWhereOrNull((e)=>e.privacyGuardLevelId ==curLevel.privacyGuardLevelID)?.displayType;
    if(curDisplayType!= null){
      switch(curDisplayType){
        case FgwDisplayedType.random:
          entries.shuffle();
        case FgwDisplayedType.mostRecent:
          entries.sort(AvesEntrySort.compareByDate);
      }
    }
    debugPrint('$runtimeType entries [$entries]');

    AvesEntry? targetEntry;
    switch(fgwWallpaperType){
      case FgwServiceWallpaperType.next:
        targetEntry = entries.firstWhereOrNull(
              (entry) => !recentUsedEntryRecord.any((usedEntry) => usedEntry.entryId == entry.id),
        );
        targetEntry ??= entries.first;
      case FgwServiceWallpaperType.pre:
        targetEntry = await fgwScheduleHelper.getPreviousEntry(_source,updateType,entries: entries,recentUsedEntryRecord:recentUsedEntryRecord);
    }
    debugPrint('$runtimeType targetEntry: $targetEntry');
    await fgwScheduleHelper.setFgWallpaper(targetEntry!, updateType: updateType, widgetId: widgetId);

    fgwScheduleHelper.updateCurEntrySettings(updateType, widgetId, targetEntry);

    if (fgwWallpaperType == FgwServiceWallpaperType.next) await fgwUsedEntryRecord.addAvesEntry(targetEntry, updateType);
    //await syncDataToKotlin(updateType,widgetId);
    unawaited(syncDataToNative({FgwSyncItem.curEntryName},updateType: updateType,widgetId:  widgetId));
    //unawaited(syncDataToNative(FgwSyncItem.values.toSet(),updateType: updateType,widgetId:  widgetId));
    return Future.value(true);
  }

  Future<bool> changeGuardLevel(dynamic args) async {
    debugPrint('$runtimeType changeGuardLevel args: $args');
    if (args.containsKey('newGuardLevel')) {
      debugPrint('$runtimeType newGuardLevel is present: ${args['newGuardLevel']}');
    } else {
      debugPrint('$runtimeType newGuardLevel is missing!');
      return false;
    }
    final newGuardLevel = args['newGuardLevel'] as int;
    await _initDependencies();
    debugPrint('$runtimeType changeGuardLevel newGuardLevel $newGuardLevel');
    final activeLevels = await fgwScheduleHelper.getActiveLevels();

    if(activeLevels.any((item) => item.guardLevel == newGuardLevel)){
      settings.curPrivacyGuardLevel = newGuardLevel;
      await syncDataToNative({FgwSyncItem.curLevel,FgwSyncItem.activeLevels,FgwSyncItem.schedules});
      unawaited(handleWallpaper(<String,dynamic>{ 'updateType' : WallpaperUpdateType.home.toString(), 'widgetId': 0},
          FgwServiceWallpaperType.next));
      return Future.value(true);
    }else{
      throw  Exception('Invalid guard level [$newGuardLevel] for \n$activeLevels');
    }
  }

  Future<bool> syncFgwScheduleChanges() async {
    debugPrint('$runtimeType flutter syncFgwScheduleChanges start');
    await fgwScheduleHelper.refreshSchedules();
    await _initDependencies();
    await syncDataToNative({FgwSyncItem.curLevel,FgwSyncItem.activeLevels,FgwSyncItem.schedules});
    unawaited(handleWallpaper(<String,dynamic>{ 'updateType' : WallpaperUpdateType.home.toString(), 'widgetId': 0},
        FgwServiceWallpaperType.next));
    return Future.value(true);
  }

  Future<Map<String, dynamic>> syncDataByNativeCall(dynamic args) async {
    await _initDependencies();
    final updateType = WallpaperUpdateType.values.safeByName(args['updateType'] as String, WallpaperUpdateType.home);
    final widgetId = args['widgetId'] as int;
    debugPrint('syncDataByNativeCall $updateType $widgetId');

    // Use ExtraFgwSyncItem to get active guard levels
    final activeGuardLevels = await FgwSyncItem.activeLevels.syncData();
    debugPrint('$runtimeType syncDataByNativeCall activeGuardLevels $activeGuardLevels');

    // Get the current entry
    AvesEntry? curEntry = await FgwSyncItem.curEntryName.syncData(source: _source,updateType: updateType,widgetId: widgetId);
    String entryFilenameWithoutExtension = curEntry?.filenameWithoutExtension ?? ':null in $updateType $widgetId';

    // Return the map
    return {
      'curGuardLevel': settings.curPrivacyGuardLevel,
      'activeLevels': activeGuardLevels,
      'entryFileName': entryFilenameWithoutExtension,
    };
  }

  Future<void> showToast(String message) async {
    try {
      await _syncDataChannel.invokeMethod('showToast', {'message': message});
    } catch (e) {
      debugPrint('Failed to show toast: $e');
    }
  }

}
