import 'dart:async';
import 'dart:ui';

import 'package:aves/l10n/l10n.dart';
import 'package:aves/model/device.dart';
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

class ForegroundWallpaperService {
  static const _platform = MethodChannel('deckers.thibault/aves/foreground_wallpaper_handler');

  static Future<void> startService( ) async {
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
      final bool isRunning = await _platform.invokeMethod(
          'isForegroundWallpaperRunning');
      return isRunning;
    } on PlatformException catch (e, stack) {
      await reportService.recordError(e, stack);
      // simply return false
      return false;
    }
  }
}

const _channel = MethodChannel('deckers.thibault/aves/foreground_wallpaper_notification');

@pragma('vm:entry-point')
Future<void> foregroundWallpaper() async {
  WidgetsFlutterBinding.ensureInitialized();
  initPlatformServices();
  await androidFileUtils.init();
  await metadataDb.init();
  await device.init();
  await mobileServices.init();
  await settings.init(monitorPlatformSettings: true);
  await reportService.init();

  final analyzer = ForegroundWallpaper();
  _channel.setMethodCallHandler((call) {
    switch (call.method) {
      case 'start':

        return Future.value(true);
      case 'stop':
        analyzer.stop();
        return Future.value(true);
      default:
        throw PlatformException(code: 'not-implemented', message: 'failed to handle method=${call.method}');
    }
  });
  try {
    await _channel.invokeMethod('initialized');
  } on PlatformException catch (e, stack) {
    await reportService.recordError(e, stack);
  }
}

enum ForegroundWallpaperState { running, stopping, stopped }

class ForegroundWallpaper with WidgetsBindingObserver {
  late AppLocalizations _l10n;
  final ValueNotifier<ForegroundWallpaperState> _serviceStateNotifier = ValueNotifier<ForegroundWallpaperState>(ForegroundWallpaperState.stopped);
  AnalysisController? _controller;
  Timer? _notificationUpdateTimer;
  final _source = MediaStoreSource();

  ForegroundWallpaperState get serviceState => _serviceStateNotifier.value;

  bool get isRunning => serviceState == ForegroundWallpaperState.running;

  SourceState get sourceState => _source.state;

  static const notificationUpdateInterval = Duration(seconds: 1);

  ForegroundWallpaper() {
    debugPrint('$runtimeType create');
    if (kFlutterMemoryAllocationsEnabled) {
      FlutterMemoryAllocations.instance.dispatchObjectCreated(
        library: 'aves',
        className: '$ForegroundWallpaper',
        object: this,
      );
    }
    _serviceStateNotifier.addListener(_onServiceStateChanged);
    _source.stateNotifier.addListener(_onSourceStateChanged);
    WidgetsBinding.instance.addObserver(this);
  }

  void dispose() {
    debugPrint('$runtimeType dispose');
    if (kFlutterMemoryAllocationsEnabled) {
      FlutterMemoryAllocations.instance.dispatchObjectDisposed(object: this);
    }
    _stopUpdateTimer();
    _controller?.dispose();
    WidgetsBinding.instance.removeObserver(this);
    _serviceStateNotifier.removeListener(_onServiceStateChanged);
    _source.stateNotifier.removeListener(_onSourceStateChanged);
    _source.dispose();
  }

  @override
  void didHaveMemoryPressure() {
    super.didHaveMemoryPressure();
    reportService.log('ForegroundWallpaper memory pressure');
  }

  Future<void> start(dynamic args) async {
    List<int>? entryIds;
    var force = false;
    var progressTotal = 0, progressOffset = 0;
    if (args is Map) {
      entryIds = (args['entryIds'] as List?)?.cast<int>();
      force = args['force'] ?? false;
      progressTotal = args['progressTotal'];
      progressOffset = args['progressOffset'];
    }
    await reportService.log('ForegroundWallpaper start for ${entryIds?.length ?? 'all'} entries, at $progressOffset/$progressTotal');
    _controller?.dispose();
    _controller = AnalysisController(
      canStartService: false,
      entryIds: entryIds,
      force: force,
      progressTotal: progressTotal,
      progressOffset: progressOffset,
    );

    settings.systemLocalesFallback = await deviceService.getLocales();
    _l10n = await AppLocalizations.delegate.load(settings.appliedLocale);
    _serviceStateNotifier.value = ForegroundWallpaperState.running;
    await _source.init(analysisController: _controller);

    _notificationUpdateTimer = Timer.periodic(notificationUpdateInterval, (_) async {
      if (!isRunning) return;
      await _updateNotification();
    });
  }

  Future<void> stop() async {
    await reportService.log('ForegroundWallpaper stop');
    _serviceStateNotifier.value = ForegroundWallpaperState.stopped;
  }

  void _stopUpdateTimer() => _notificationUpdateTimer?.cancel();

  Future<void> _onServiceStateChanged() async {
    switch (serviceState) {
      case ForegroundWallpaperState.running:
        break;
      case ForegroundWallpaperState.stopping:
        await _stopPlatformService();
        _serviceStateNotifier.value = ForegroundWallpaperState.stopped;
      case ForegroundWallpaperState.stopped:
        _controller?.enableStopSignal();
        _stopUpdateTimer();
    }
  }

  void _onSourceStateChanged() {
    if (_source.isReady) {
      _serviceStateNotifier.value = ForegroundWallpaperState.stopping;
    }
  }

  Future<void> _updateNotification() async {
    if (!isRunning) return;

    final title = sourceState.getName(_l10n);
    if (title == null) return;

    final progress = _source.progressNotifier.value;
    final progressive = progress.total != 0 && sourceState != SourceState.locatingCountries;

    try {
      await _channel.invokeMethod('updateNotification', <String, dynamic>{
        'title': title,
        'message': progressive ? '${progress.done}/${progress.total}' : null,
      });
    } on PlatformException catch (e, stack) {
      await reportService.recordError(e, stack);
    }
  }

  Future<void> _stopPlatformService() async {
    try {
      await _channel.invokeMethod('stop');
    } on PlatformException catch (e, stack) {
      await reportService.recordError(e, stack);
    }
  }
}
