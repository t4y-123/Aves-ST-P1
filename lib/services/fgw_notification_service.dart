import 'dart:async';
import 'package:aves/model/foreground_wallpaper/privacy_guard_level.dart';
import 'package:aves/model/settings/settings.dart';
import 'package:aves/model/source/media_store_source.dart';
import 'package:aves/services/common/services.dart';
import 'package:aves/utils/android_file_utils.dart';
import 'package:aves/utils/collection_utils.dart';
import 'package:aves_model/aves_model.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:wallpaper_handler/wallpaper_handler.dart';
import '../model/device.dart';
import '../model/entry/entry.dart';
import '../model/entry/sort.dart';
import '../model/foreground_wallpaper/fgw_schedule_helper.dart';
import '../model/foreground_wallpaper/fgw_used_entry_record.dart';
import '../model/foreground_wallpaper/foreground_wallpaper_helper.dart';
import '../model/foreground_wallpaper/wallpaper_schedule.dart';

const _channel = MethodChannel('deckers.thibault/aves/foreground_wallpaper_notification_service');

enum FgwServiceWallpaperType {next, pre}
Future<void> fgwNotificationServiceAsync() async {
  WidgetsFlutterBinding.ensureInitialized();
  initPlatformServices();
  await androidFileUtils.init();
  await metadataDb.init();
  await device.init();
  await mobileServices.init();
  await settings.init(monitorPlatformSettings: true);
  await reportService.init();

  final fgwServiceHelper = FgwServiceHelper();
  _channel.setMethodCallHandler((call) {
    debugPrint('fgwServiceHelper $call ');
    switch (call.method) {
      case 'start':
        fgwServiceHelper.start();
        return Future.value(true);
      case 'stop':
        fgwServiceHelper.stop();
        return Future.value(true);
      case 'nextWallpaper':
        return fgwServiceHelper.handleWallpaper(call.arguments, FgwServiceWallpaperType.next);
      case 'preWallpaper':
        return fgwServiceHelper.handleWallpaper(call.arguments, FgwServiceWallpaperType.pre);
      case 'syncNecessaryData':
        return fgwServiceHelper.syncNecessaryData(call.arguments);
      case 'updateCurGuardLevel':
        return fgwServiceHelper.updateCurGuardLevel(call.arguments);
      default:
        throw PlatformException(code: 'not-implemented', message: 'failed to handle method=${call.method}');
    }

  });
}

enum FgwServiceState { starting, running, stopped }

class FgwServiceHelper with WidgetsBindingObserver {
  final ValueNotifier<FgwServiceState> _serviceStateNotifier = ValueNotifier<FgwServiceState>(FgwServiceState.stopped);
  Timer? _notificationUpdateTimer;
  final _source = MediaStoreSource();

  FgwServiceState get serviceState => _serviceStateNotifier.value;

  bool get isRunning => (serviceState == FgwServiceState.running || (serviceState == FgwServiceState.starting));

  SourceState get sourceState => _source.state;
  static const notificationUpdateInterval = Duration(seconds: 1);

  FgwServiceHelper() {
    debugPrint('$runtimeType create');
    if (kFlutterMemoryAllocationsEnabled) {
      FlutterMemoryAllocations.instance.dispatchObjectCreated(
        library: 'aves',
        className: '$FgwServiceHelper',
        object: this,
      );
    }
    _serviceStateNotifier.addListener(_onServiceStateChanged);
    _source.stateNotifier.addListener(_onSourceStateChanged);
    WidgetsBinding.instance.addObserver(this);
  }

  void dispose() {
    debugPrint('$runtimeType dispose FgwServiceState: $serviceState');
    if (kFlutterMemoryAllocationsEnabled) {
      FlutterMemoryAllocations.instance.dispatchObjectDisposed(object: this);
    }
    _stopUpdateTimer();
    WidgetsBinding.instance.removeObserver(this);
    _serviceStateNotifier.removeListener(_onServiceStateChanged);
    _source.stateNotifier.removeListener(_onSourceStateChanged);
    _source.dispose();
  }

  @override
  void didHaveMemoryPressure() {
    super.didHaveMemoryPressure();
    reportService.log('FgwServiceHelper memory pressure');
  }

  Future<void> _initDependencies() async {
    await androidFileUtils.init();
    debugPrint('FgwServiceHelper androidFileUtils.init();, $serviceState');
    final readyCompleter = Completer();
    _source.stateNotifier.addListener(() {
      if (_source.isReady && !readyCompleter.isCompleted) {
        readyCompleter.complete();
      }
    });
    debugPrint(' await _source.init(canAnalyze: false);, $serviceState');
    await _source.init(canAnalyze: false);
    debugPrint(' await readyCompleter.future;, $serviceState');
    await readyCompleter.future;
    debugPrint('FgwServiceHelper readyCompleter.future, $serviceState');

    settings.systemLocalesFallback = await deviceService.getLocales();
  }

  Future<void> start() async {
    debugPrint('FgwServiceHelper start() , $serviceState');
    if (serviceState == FgwServiceState.running && _source.isReady) return;
    _serviceStateNotifier.value = FgwServiceState.starting;
    await reportService.log('FgwServiceHelper in start');
    await _initDependencies();
    _notificationUpdateTimer = Timer.periodic(notificationUpdateInterval, (_) async {
      if (!isRunning) {
        debugPrint('_notificationUpdateTimer isRunning :[$isRunning] , return');
        return;
      }
    });
    debugPrint('FgwServiceHelper start() end $serviceState  isRunning :[$isRunning] , return');
  }

  Future<void> stop() async {
    await reportService.log('FgwServiceHelper stop');
    _serviceStateNotifier.value = FgwServiceState.stopped;
  }

  void _stopUpdateTimer() {
    debugPrint('$runtimeType _stopUpdateTimer $serviceState');
    _notificationUpdateTimer?.cancel();
  }

  Future<void> _onServiceStateChanged() async {
    debugPrint('_onServiceStateChanged $serviceState.');
    switch (serviceState) {
      case FgwServiceState.starting:
        break;
      case FgwServiceState.running:
        break;
      case FgwServiceState.stopped:
        _stopUpdateTimer();
    }
  }

  Future<void> _waitForRunningState() async {
    debugPrint('_waitForRunningState serviceState $serviceState');
    if (serviceState == FgwServiceState.running) {
      debugPrint('$serviceState == FgwServiceState.running, can run the method');
      await androidFileUtils.init();
      debugPrint('$serviceState ==  await androidFileUtils.init();.running, can run the method');
      await metadataDb.init();
      await foregroundWallpaperHelper.initWallpaperSchedules();
      // Your logic for updating notification properties here
    } else if (serviceState == FgwServiceState.starting) {
      while (serviceState != FgwServiceState.running) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
    } else {
      debugPrint('_waitForRunningState serviceState $serviceState');
      await start();
      while (serviceState != FgwServiceState.running) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
    }
  }

  void _onSourceStateChanged() {
    debugPrint('_onSourceStateChanged ${_source.state}');
    if (_source.isReady) {
      _serviceStateNotifier.value = FgwServiceState.running;
    } else {
      if (_serviceStateNotifier.value != FgwServiceState.starting) {
        _serviceStateNotifier.value = FgwServiceState.starting;
      }
    }
  }

  Future<void> setFgWallpaper(AvesEntry entry,
      {WallpaperUpdateType updateType = WallpaperUpdateType.home, int widgetId = 0}) async {
    debugPrint(' setFgWallpaper');
    WallpaperLocation location = WallpaperLocation.homeScreen;
    switch (updateType) {
      case WallpaperUpdateType.home:
        location = WallpaperLocation.homeScreen;
        debugPrint(' location = WallpaperLocation.homeScreen;');
      case WallpaperUpdateType.lock:
        location = WallpaperLocation.lockScreen;
        debugPrint(' location = WallpaperLocation.lockScreen;');
      case WallpaperUpdateType.widget:
        debugPrint('setFgWallpaper WallpaperUpdateType.widget wait for implementation');
        return;
      default:
        throw const FormatException('Invalid setWallpaper');
    }
    bool result = await WallpaperHandler.instance.setWallpaperFromFile(entry.path!, location);
    debugPrint('setFgWallpaper result: $result');
    if (!result) {
      debugPrint('setFgWallpaper fail result: $result');
    }
  }

  Future<void> syncDataToKotlin(WallpaperUpdateType updateType,int widgetId,{AvesEntry? curEntry}) async {
    debugPrint('$runtimeType syncDataToKotlin start');
    // First, get all active items in privacyGuardLevels.all,Sort activeGuardLevels by guardLevel
    final activeGuardLevels = privacyGuardLevels.all
        .where((level) => level.isActive)
        .map((level) => (level.guardLevel, level.aliasName, level.color.toString()))
        .toList()
      ..sort((a, b) => a.$1.compareTo(b.$1));
    debugPrint('$runtimeType syncNecessaryData activeGuardLevels $activeGuardLevels');

    final result = await _channel.invokeMethod('syncDataToKotlin', {
      'updateType': updateType.toString(),  // Replace with your actual data
      'widgetId': widgetId,
      'curGuardLevel': settings.curPrivacyGuardLevel,
      'activeLevels': activeGuardLevels.toString(),
      'entryFileName': curEntry?.filenameWithoutExtension ?? '',
    });

    debugPrint('$runtimeType syncDataToKotlin result: $result');
  }

  Future<bool> handleWallpaper(dynamic args, FgwServiceWallpaperType fgwWallpaperType) async {
    debugPrint('handleWallpaper $args $fgwWallpaperType');
    await _waitForRunningState();
    final updateType = WallpaperUpdateType.values.safeByName(args['updateType'] as String, WallpaperUpdateType.home);
    final widgetId = args['widgetId'] as int;

    final entries = await fgwScheduleHelper.getScheduleEntries(_source, updateType);
    final recentUsedEntryRecord = await fgwScheduleHelper.getRecentEntryRecord(updateType);
    entries.sort(AvesEntrySort.compareByDate);

    AvesEntry? targetEntry;
    switch(fgwWallpaperType){
      case FgwServiceWallpaperType.next:
        targetEntry = entries.firstWhere(
              (entry) => !recentUsedEntryRecord.any((usedEntry) => usedEntry.entryId == entry.id),
        );
      case FgwServiceWallpaperType.pre:
        targetEntry = await fgwScheduleHelper.getPreviousEntry(_source,updateType,entries: entries,recentUsedEntryRecord:recentUsedEntryRecord);
    }

    await setFgWallpaper(targetEntry!, updateType: updateType, widgetId: widgetId);

    fgwScheduleHelper.updateCurEntrySettings(updateType, widgetId, targetEntry);

    if (fgwWallpaperType == FgwServiceWallpaperType.next) await fgwUsedEntryRecord.addAvesEntry(targetEntry, updateType);
    //await syncDataToKotlin(updateType,widgetId);
    unawaited(syncDataToKotlin(updateType, widgetId,curEntry: targetEntry));
    return Future.value(true);
  }

  Future<Map<String, dynamic>> syncNecessaryData(dynamic args) async {
    await _waitForRunningState();
    final updateType = WallpaperUpdateType.values.safeByName(args['updateType'] as String, WallpaperUpdateType.home);
    final widgetId = args['widgetId'] as int;
    debugPrint('syncNecessaryData $updateType $widgetId');

    // First, get all active items in privacyGuardLevels.all,Sort activeGuardLevels by guardLevel
    final activeGuardLevels = privacyGuardLevels.all
        .where((level) => level.isActive)
        .map((level) => (level.guardLevel, level.aliasName, level.color.toString()))
        .toList()
        ..sort((a, b) => a.$1.compareTo(b.$1));
    debugPrint('$runtimeType syncNecessaryData activeGuardLevels $activeGuardLevels');

    // Second, get curEntry.
    final entries = await fgwScheduleHelper.getScheduleEntries(_source,updateType);

    AvesEntry? curEntry = entries.firstWhere((entry) => entry.id == settings.getFgwCurEntryId(updateType,widgetId));
    String entryFilenameWithoutExtension = curEntry.filenameWithoutExtension ?? ':null in $updateType $widgetId';
    // Return the map
    return {
      'curGuardLevel': settings.curPrivacyGuardLevel,
      'activeLevels': activeGuardLevels.toString(),
      'entryFileName': entryFilenameWithoutExtension,
    };
  }

  Future<bool> updateCurGuardLevel(dynamic args) async {
    await _waitForRunningState();
    final newGuardLevel = args['newGuardLevel'] as int;
    debugPrint('$runtimeType syncNecessaryData $newGuardLevel $newGuardLevel');
    final activeGuardLevels = privacyGuardLevels.all
        .where((level) => level.isActive)
        .toList();
    if(activeGuardLevels.any((item) => item.guardLevel == newGuardLevel)){
      settings.curPrivacyGuardLevel = newGuardLevel;
      return Future.value(true);
    }else{
      throw  Exception('Invalid guard level [$newGuardLevel] for \n$activeGuardLevels');
    }
  }
}
