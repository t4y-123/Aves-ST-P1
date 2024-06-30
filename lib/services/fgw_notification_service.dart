import 'dart:async';

import 'package:aves/l10n/l10n.dart';
import 'package:aves/model/foreground_wallpaper/privacyGuardLevel.dart';
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
import '../model/filters/filters.dart';
import '../model/foreground_wallpaper/fgw_used_entry_record.dart';
import '../model/foreground_wallpaper/filterSet.dart';
import '../model/foreground_wallpaper/foreground_wallpaper_helper.dart';
import '../model/foreground_wallpaper/wallpaperSchedule.dart';
import '../model/source/collection_lens.dart';
import 'fgw_service_handler.dart';

const _channel = MethodChannel('deckers.thibault/aves/foreground_wallpaper_notification_service');

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
        debugPrint('fgwServiceHelper.fgwServiceHelper.start() start in Dart side');
        fgwServiceHelper.start();
        return Future.value(true);
      case 'stop':
        debugPrint('fgwServiceHelper.fgwServiceHelper.stop() start in Dart side');
        fgwServiceHelper.stop();
        return Future.value(true);
      case 'nextWallpaper':
        return fgwServiceHelper.nextWallpaper(call.arguments);
      case 'updateNotificationProp':
        debugPrint('fgwServiceHelper.updateNotificationProp()');
        return fgwServiceHelper.updateNotificationProp();
      default:
        throw PlatformException(code: 'not-implemented', message: 'failed to handle method=${call.method}');
    }
  });
}


enum FgwServiceState { starting,running, stopping, stopped }

class FgwServiceHelper with WidgetsBindingObserver {
  late AppLocalizations _l10n;
  final ValueNotifier<FgwServiceState> _serviceStateNotifier = ValueNotifier<FgwServiceState>(FgwServiceState.stopped);
  Timer? _notificationUpdateTimer;
  final _source = MediaStoreSource();
  PrivacyGuardLevelRow? _currentGuardLevel;
  AvesEntry? curEntry;

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
    _l10n = await AppLocalizations.delegate.load(settings.appliedLocale);

    await _updatePrivacyGuardLevel();
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
      case FgwServiceState.stopping:
        break;
      case FgwServiceState.stopped:
        await ForegroundWallpaperService.stopService();
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
      while (serviceState != FgwServiceState.running) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
    }
  }

  void _onSourceStateChanged() {
    debugPrint('_onSourceStateChanged ${_source.state}');
    if (_source.isReady) {
      _serviceStateNotifier.value = FgwServiceState.running;
      _updatePrivacyGuardLevel();
    } else {
      if (_serviceStateNotifier.value != FgwServiceState.starting) {
        _serviceStateNotifier.value = FgwServiceState.starting;
      }
    }
  }

  Future<void> _updatePrivacyGuardLevel() async {
    final activeItems = privacyGuardLevels.all.where((e) => e.isActive).toSet();
    if (activeItems.isEmpty) {
      debugPrint('No active PrivacyGuardLevels found.');
      return;
    }
    _currentGuardLevel = activeItems.firstWhere(
      (e) => e.guardLevel == settings.curPrivacyGuardLevel,
      orElse: () => activeItems.first,
    );
    debugPrint('Updated PrivacyGuardLevel: $_currentGuardLevel');
  }

  Future<bool> preWallpaper(dynamic args) async {
    await _waitForRunningState();
    final updateType = WallpaperUpdateType.values.safeByName(args['updateType'] as String, WallpaperUpdateType.home);
    final widgetId = args['widgetId'] as int;
    debugPrint('preWallpaper $updateType $widgetId');
    final filterSetId = wallpaperSchedules.all.firstWhere(
          (schedule) => schedule.updateType == updateType
          && schedule.widgetId == widgetId
          && schedule.privacyGuardLevelId == _currentGuardLevel?.privacyGuardLevelID,
    ).filterSetId;

    final filters = filterSet.all.firstWhere(
            (filterRow) => filterRow.filterSetId == filterSetId
    ).filters ?? <CollectionFilter>{};

    final entries = CollectionLens(source: _source, filters: filters).sortedEntries;
    entries.sort(AvesEntrySort.compareByDate);

    final recentUsedEntries = fgwUsedEntryRecord.all.where(
          (row) => row.updateType == updateType
          && row.widgetId == widgetId
          && row.privacyGuardLevelId == _currentGuardLevel?.privacyGuardLevelID,
    ).toList();

    AvesEntry? previousEntry;
    if (curEntry == null) {
      // If curEntry is null, find the most recent entry from recentUsedEntries
      final mostRecentUsedEntry = recentUsedEntries.isNotEmpty
          ? recentUsedEntries.reduce((a, b) => a.dateMillis > b.dateMillis ? a : b)
          : null;
      if(entries.isNotEmpty){
        previousEntry = entries.firstWhere(
                (entry) => entry.id == mostRecentUsedEntry?.entryId);
      }
    } else {
      // If curEntry is not null, find the most recent but older entry than curEntry from recentUsedEntries
      FgwUsedEntryRecordRow curUsedRecord = recentUsedEntries.firstWhere((usedEntry) => usedEntry.entryId == curEntry?.id);
      final olderEntries = recentUsedEntries.where((usedEntry) => usedEntry.dateMillis < curUsedRecord.dateMillis);
      final mostRecentOlderEntry = olderEntries.isNotEmpty
          ? olderEntries.reduce((a, b) => a.dateMillis > b.dateMillis ? a : b)
          : null;
      if(entries.isNotEmpty){
        previousEntry =entries.firstWhere(
              (entry) => entry.id == mostRecentOlderEntry?.entryId);
      }
    }

    if (previousEntry != null) {
      // Set the previousEntry as the wallpaper
      bool result = await WallpaperHandler.instance.setWallpaperFromFile(previousEntry.path!, WallpaperLocation.homeScreen);
      debugPrint('preWallpaper result: $result');
      if (!result) {
        debugPrint('preWallpaper fail result: $result');
      }

      // Update the curEntry in the corresponding FgwInfos item
      curEntry = previousEntry;
      return Future.value(true);
    } else {
      throw Exception('No suitable entry found to set as wallpaper');
    }
  }


  Future<void> setFgWallpaper(AvesEntry entry, {WallpaperUpdateType updateType = WallpaperUpdateType.home ,int widgetId = 0}) async {
    debugPrint(' setFgWallpaper');
    WallpaperLocation location = WallpaperLocation.homeScreen;
      switch (updateType) {
      case WallpaperUpdateType.home : // Logical-or pattern
          location = WallpaperLocation.homeScreen;
          debugPrint(' location = WallpaperLocation.homeScreen;');
      case WallpaperUpdateType.lock: // Logica pattern
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
  
  Future<bool> nextWallpaper(dynamic args) async {
    await _waitForRunningState();
    final updateType = WallpaperUpdateType.values.safeByName(args['updateType'] as String, WallpaperUpdateType.home);
    final widgetId = args['widgetId'] as int;
    debugPrint(' nextWallpaper $updateType $widgetId');

    final filterSetId = wallpaperSchedules.all.firstWhere(
      (schedule) => schedule.updateType == updateType
          && schedule.widgetId == widgetId
          && schedule.privacyGuardLevelId == _currentGuardLevel?.privacyGuardLevelID,
    ).filterSetId;

    final filters = filterSet.all.firstWhere(
      (filterRow) => filterRow.filterSetId == filterSetId
    ).filters ?? <CollectionFilter>{};
    debugPrint(' nextWallpaper filters $filters');
    final entries = CollectionLens(source: _source, filters: filters).sortedEntries;
    debugPrint(' nextWallpaper entries $entries');
    entries.sort(AvesEntrySort.compareByDate);

    final recentUsedEntries = fgwUsedEntryRecord.all.where(
      (row) => row.updateType == updateType
          && row.widgetId == widgetId
          && row.privacyGuardLevelId == _currentGuardLevel?.privacyGuardLevelID,
    ).toList();
    debugPrint(' nextWallpaper recentUsedEntries $recentUsedEntries');

    final nextEntry = entries.firstWhere(
      (entry) => !recentUsedEntries.any((usedEntry) => usedEntry.entryId == entry.id),
    );
    debugPrint(' nextWallpaper nextEntry $nextEntry');

    await setFgWallpaper(nextEntry, updateType: updateType, widgetId: widgetId);
    // await metadataDb.init();
    int newId = metadataDb.nextId;
    debugPrint(' nextWallpaper newId $newId');
    final FgwUsedEntryRecordRow newRow = FgwUsedEntryRecordRow(
      id: DateTime.now().millisecondsSinceEpoch,
      //      id: metadataDb.nextId,will be forever the same value.
      privacyGuardLevelId: _currentGuardLevel!.privacyGuardLevelID,
      updateType: updateType,
      widgetId: widgetId,
      entryId: nextEntry.id,
      dateMillis: DateTime.now().millisecondsSinceEpoch,
    );
    debugPrint(' nextWallpaper newRow $newRow');
    await fgwUsedEntryRecord.add({newRow});
    return Future.value(true);
  }

  Future<Map<String, dynamic>> updateNotificationProp() async {
    debugPrint('In _updateNotificationProp; start');
    await _waitForRunningState();
    int curPrivacyGuardLevel = settings.curPrivacyGuardLevel;
    debugPrint('curPrivacyGuardLevel $curPrivacyGuardLevel');
    debugPrint('privacyGuardLevels.all ${privacyGuardLevels.all}');
    _currentGuardLevel = privacyGuardLevels.all.firstWhere(
      (e) => e.guardLevel == curPrivacyGuardLevel && e.isActive,
      orElse: () => privacyGuardLevels.all.firstWhere((e) => e.guardLevel == 1),
    );
    debugPrint('_currentGuardLevel $_currentGuardLevel');
    if (_currentGuardLevel == null) {
      curPrivacyGuardLevel = 1;
      _currentGuardLevel = privacyGuardLevels.all.firstWhere((e) => e.guardLevel == curPrivacyGuardLevel);
    }

    final guardLevel = _currentGuardLevel?.guardLevel.toString();
    final titleName = _currentGuardLevel?.aliasName;
    final updateColor = _currentGuardLevel?.color ?? privacyGuardLevels.getRandomColor();

    debugPrint(
        'Back to Kotlin _channel.invokeMethod updateNotification $guardLevel $titleName ${updateColor.value.toString()} ${updateColor.toString()}');

    return {
      'guardLevel': guardLevel,
      'titleName': titleName,
      'color': updateColor.toString(),
    };
  }
}
