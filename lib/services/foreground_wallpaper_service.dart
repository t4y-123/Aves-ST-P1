import 'dart:async';
import 'dart:ui';

import 'package:aves/l10n/l10n.dart';
import 'package:aves/model/device.dart';
import 'package:aves/model/foreground_wallpaper/foreground_wallpaper_helper.dart';
import 'package:aves/model/foreground_wallpaper/privacyGuardLevel.dart';
import 'package:aves/model/settings/settings.dart';
import 'package:aves/model/source/analysis_controller.dart';
import 'package:aves/model/source/media_store_source.dart';
import 'package:aves/services/common/services.dart';
import 'package:aves/utils/android_file_utils.dart';
import 'package:aves/view/view.dart';
import 'package:aves_model/aves_model.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:vector_math/vector_math.dart';
import 'package:wallpaper_handler/wallpaper_handler.dart';

import '../model/entry/sort.dart';
import '../model/filters/filters.dart';
import '../model/foreground_wallpaper/filterSet.dart';
import '../model/foreground_wallpaper/wallpaperSchedule.dart';
import '../model/source/collection_lens.dart';

class ForegroundWallpaperService {
  static const _platform = MethodChannel('deckers.thibault/aves/foreground_wallpaper_handler');

  static Future<void> startService() async {
    await reportService.log('Start foreground wallpaper service ');
    try {
      await _platform.invokeMethod('startForegroundWallpaper');
    } on PlatformException catch (e, stack) {
      await reportService.recordError(e, stack);
    }
  }

  static Future<void> stopService() async {
    await reportService.log('Stop foreground wallpaper service ');
    try {
      await _platform.invokeMethod('stopForegroundWallpaper');
    } on PlatformException catch (e, stack) {
      await reportService.recordError(e, stack);
    }
  }

  static Future<bool> isServiceRunning() async {
    await reportService.log('Check foreground wallpaper is running');
    try {
      final bool isRunning = await _platform.invokeMethod('isForegroundWallpaperRunning');
      return isRunning;
    } on PlatformException catch (e, stack) {
      await reportService.recordError(e, stack);
      // simply return false
      return false;
    }
  }
}

const _channel = MethodChannel('deckers.thibault/aves/foreground_wallpaper_notification_service');

Future<void> fgwNotificationServiceAsync() async {
  WidgetsFlutterBinding.ensureInitialized();
  initPlatformServices();
  await androidFileUtils.init();
  await metadataDb.init();
  //await device.init();
  //await mobileServices.init();
  await settings.init(monitorPlatformSettings: false);
  await reportService.init();

  final fgwServiceHelper = FgwServiceHelper();
  _channel.setMethodCallHandler((call) {
    switch (call.method) {
      case 'start':
        fgwServiceHelper.start();
        return Future.value(true);
      case 'stop':
        return Future.value(true);
      case 'nextWallpaper':
        fgwServiceHelper.nextWallpaper();
        return Future.value(true);
      case 'updateNotificationProp':
        debugPrint('fgwServiceHelper.updateNotificationProp()');
        return fgwServiceHelper.updateNotificationProp();
      default:
        throw PlatformException(code: 'not-implemented', message: 'failed to handle method=${call.method}');
    }
  });
}

enum FgwServiceState { running, stopping, stopped }

class WallpaperFilterSet {
  final WallpaperUpdateType updateType;
  final int widgetId;
  final Set<CollectionFilter> filters;

  WallpaperFilterSet({
    required this.updateType,
    required this.widgetId,
    required this.filters,
  });

  @override
  String toString() {
    return 'WallpaperFilterSet(updateType: $updateType, widgetId: $widgetId, filters: $filters)';
  }
}

class FgwServiceHelper with WidgetsBindingObserver {
  late AppLocalizations _l10n;
  final ValueNotifier<FgwServiceState> _serviceStateNotifier = ValueNotifier<FgwServiceState>(FgwServiceState.stopped);
  Timer? _notificationUpdateTimer;
  final _source = MediaStoreSource();

  // New member properties
  late PrivacyGuardLevelRow _curGuardLevel;
  late Set<WallpaperScheduleRow> _activeSchedules;
  late Set<WallpaperFilterSet> _filters;

  FgwServiceState get serviceState => _serviceStateNotifier.value;

  bool get isRunning => serviceState == FgwServiceState.running;

  SourceState get sourceState => _source.state;

  static const notificationUpdateInterval = Duration(minutes: 3);

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

    // Listen to changes in privacyGuardLevels, wallpaperSchedules, and filterSet
    privacyGuardLevels.addListener(_onPrivacyGuardLevelsChanged);
    wallpaperSchedules.addListener(_onWallpaperSchedulesChanged);
    filterSet.addListener(_onFilterSetChanged);

    _updatePrivacyGuardLevel();
  }

  void dispose() {
    debugPrint('$runtimeType dispose');
    if (kFlutterMemoryAllocationsEnabled) {
      FlutterMemoryAllocations.instance.dispatchObjectDisposed(object: this);
    }
    _stopUpdateTimer();
    WidgetsBinding.instance.removeObserver(this);
    _serviceStateNotifier.removeListener(_onServiceStateChanged);
    _source.stateNotifier.removeListener(_onSourceStateChanged);

    // Remove listeners for privacyGuardLevels, wallpaperSchedules, and filterSet
    privacyGuardLevels.removeListener(_onPrivacyGuardLevelsChanged);
    wallpaperSchedules.removeListener(_onWallpaperSchedulesChanged);
    filterSet.removeListener(_onFilterSetChanged);

    _source.dispose();
  }

  @override
  void didHaveMemoryPressure() {
    super.didHaveMemoryPressure();
    reportService.log('FgwServiceHelper memory pressure');
  }

  Future<void> start() async {
    if(serviceState != FgwServiceState.running || !_source.isReady){
      await reportService.log('FgwServiceHelper in start');

      await androidFileUtils.init();
      final readyCompleter = Completer();
      _source.stateNotifier.addListener(() {
        if (_source.isReady && !readyCompleter.isCompleted) {
          readyCompleter.complete();
        }
      });
      await _source.init(canAnalyze: false);
      await readyCompleter.future;

      settings.systemLocalesFallback = await deviceService.getLocales();
      _l10n = await AppLocalizations.delegate.load(settings.appliedLocale);
      _serviceStateNotifier.value = FgwServiceState.running;
      await _source.init(canAnalyze: false);
      _notificationUpdateTimer = Timer.periodic(notificationUpdateInterval, (_) async {
        if (!isRunning) return;
      });
      await _updatePrivacyGuardLevel();
    }
  }

  Future<void> stop() async {
    await reportService.log('FgwServiceHelper stop');
    _serviceStateNotifier.value = FgwServiceState.stopped;
  }

  void _stopUpdateTimer() => _notificationUpdateTimer?.cancel();

  Future<void> _onServiceStateChanged() async {
    switch (serviceState) {
      case FgwServiceState.running:
        break;
      case FgwServiceState.stopping:
        //_serviceStateNotifier.value = FgwServiceState.stopped;
      case FgwServiceState.stopped:
        _stopUpdateTimer();
    }
  }

  void _onSourceStateChanged() {
    if (_source.isReady) {
      _serviceStateNotifier.value = FgwServiceState.stopping;
    }
  }

  Future<void> _onPrivacyGuardLevelsChanged() async {
    // Handle changes in privacyGuardLevels
    await _updatePrivacyGuardLevel();
  }

  Future<void> _onWallpaperSchedulesChanged() async {
    // Handle changes in wallpaperSchedules
    await _updateSchedules();
  }

  Future<void> _onFilterSetChanged() async {
    // Handle changes in filterSet
    await _updateFilterSets();
  }

  Future<void> _updatePrivacyGuardLevel() async {
    int curPrivacyGuardLevel = settings.curPrivacyGuardLevel;
    _curGuardLevel = privacyGuardLevels.all.firstWhere(
      (e) => e.guardLevel == curPrivacyGuardLevel && e.isActive,
      orElse: () => privacyGuardLevels.all.firstWhere((e) => e.guardLevel == 1),
    );

    if (_curGuardLevel == null) {
      curPrivacyGuardLevel = 1;
      _curGuardLevel = privacyGuardLevels.all.firstWhere((e) => e.guardLevel == 1);
    }

    debugPrint('Updated PrivacyGuardLevel: $_curGuardLevel');

    await _updateSchedules();
  }

  Future<void> _updateSchedules() async {
    final activeSchedules = wallpaperSchedules.all.where(
      (schedule) => schedule.privacyGuardLevelId == _curGuardLevel.privacyGuardLevelID,
    );

    _activeSchedules = activeSchedules.toSet();
    debugPrint('Updated Schedules: $_activeSchedules');
    await _updateFilterSets();
  }

  Future<void> _updateFilterSets() async {
    _filters = _activeSchedules.map((schedule) {
      Set<CollectionFilter> filters =
          filterSet.all.firstWhere((filter) => filter.filterSetId == schedule.filterSetId).filters ??
              <CollectionFilter>{};

      return WallpaperFilterSet(
        updateType: schedule.updateType,
        widgetId: schedule.widgetId,
        filters: filters,
      );
    }).toSet();

    debugPrint('Updated Filters: $_filters');
  }

  // Method to get filters for a specific WallpaperUpdateType and widgetId (defaulting to 0)
  Set<CollectionFilter> getFiltersForUpdateType(WallpaperUpdateType type, {int widgetId = 0}) {
    final filters = _filters
        .where((filterSet) => filterSet.updateType == type && filterSet.widgetId == widgetId)
        .expand((filterSet) => filterSet.filters)
        .toSet();
    debugPrint('Filters for $type with widgetId $widgetId: $filters');
    return filters;
  }

  Future<void> nextWallpaper() async {
    //await start();
    debugPrint('Updated Filters: $_filters');
    if (_filters.isNotEmpty) {
      final filters = getFiltersForUpdateType(WallpaperUpdateType.home);
      await androidFileUtils.init();

      final readyCompleter = Completer();
      _source.stateNotifier.addListener(() {
        if (_source.isReady) {
          readyCompleter.complete();
        }
      });
      await _source.init(canAnalyze: false);
      await readyCompleter.future;
      await reportService.log('nextWallpaper in _source $_source');
      final entries = CollectionLens(source: _source, filters: filters).sortedEntries;
      entries.shuffle();
      entries.sort(AvesEntrySort.compareByDate);
      debugPrint('nextWallpaper entries: $entries');
      final entry = entries.firstOrNull;
      if (entry != null) {
        debugPrint('nextWallpaper entry: $entry');
        bool result = await WallpaperHandler.instance.setWallpaperFromFile(entry.path!,  WallpaperLocation.homeScreen);
        debugPrint('nextWallpaper result: $result');
        if (!result) {
          debugPrint('nextWallpaper fail result: $result');
        }
      }
      await reportService.log('FgwServiceHelper stop');
      _serviceStateNotifier.value = FgwServiceState.stopped;
    }
  }

  Future<Map<String, dynamic>> updateNotificationProp() async {
    debugPrint('In _updateNotificationProp; start');

    // await metadataDb.init();
    // await androidFileUtils.init();
    debugPrint('  await metadataDb.init();');
    // final filters = settings.getWidgetCollectionFilters(widgetId);
    // final source = MediaStoreSource();
    // final readyCompleter = Completer();
    // source.stateNotifier.addListener(() {
    //   if (source.isReady) {
    //     readyCompleter.complete();
    //   }
    // });
    await _source.init(canAnalyze: false);
    // await readyCompleter.future;
    await _updatePrivacyGuardLevel();
    int curPrivacyGuardLevel = settings.curPrivacyGuardLevel;
    debugPrint('   privacyGuardLevels.all;${privacyGuardLevels.all}');
    _curGuardLevel = privacyGuardLevels.all.firstWhere(
      (e) => e.guardLevel == curPrivacyGuardLevel && e.isActive,
      orElse: () => privacyGuardLevels.all.firstWhere((e) => e.guardLevel == 1),
    );

    if (_curGuardLevel == null) {
      curPrivacyGuardLevel = 1;
      _curGuardLevel = privacyGuardLevels.all.firstWhere((e) => e.guardLevel == 1);
    }

    final guardLevel = _curGuardLevel.guardLevel.toString();
    final titleName = _curGuardLevel.aliasName;
    final updateColor = _curGuardLevel.color ?? privacyGuardLevels.getRandomColor();

    debugPrint(
        'Back to Kotlin _channel.invokeMethod updateNotification $guardLevel $titleName ${updateColor.value.toString()} ${updateColor.toString()}');

    return {
      'guardLevel': guardLevel,
      'titleName': titleName,
      'color': updateColor.toString(),
    };
  }
}
