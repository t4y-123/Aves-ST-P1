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

class ForegroundWallpaperService {
  static const _platform =
      MethodChannel('deckers.thibault/aves/foreground_wallpaper_handler');

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
      final bool isRunning =
          await _platform.invokeMethod('isForegroundWallpaperRunning');
      return isRunning;
    } on PlatformException catch (e, stack) {
      await reportService.recordError(e, stack);
      // simply return false
      return false;
    }
  }
}

const _channel = MethodChannel(
    'deckers.thibault/aves/foreground_wallpaper_notification_service');

Future<void> fgwNotificationServiceAsync() async {
 WidgetsFlutterBinding.ensureInitialized();
 initPlatformServices();
 await settings.init(monitorPlatformSettings: false);
  await reportService.init();

  _channel.setMethodCallHandler((call) {
    switch (call.method) {
      case 'start':
        _start();
        return Future.value(true);
      case 'stop':
        return Future.value(true);
      case 'updateNotificationProp':
        debugPrint('dart:_updateNotificationProp');
        return _updateNotificationProp();
      default:
        throw PlatformException(
            code: 'not-implemented',
            message: 'failed to handle method=${call.method}');
    }
  });
}

Future<void> _start() async {
  List<int>? entryIds;
  await _updateNotificationProp();
}

Future<void> stop() async {
  await reportService.log('ForegroundWallpaper stop');
}

Future<Map<String, dynamic>> _updateNotificationProp() async {
  debugPrint('In _updateNotificationProp; start');

  await metadataDb.init();
  await androidFileUtils.init();
  debugPrint('  await metadataDb.init();');
  // final filters = settings.getWidgetCollectionFilters(widgetId);
  final source = MediaStoreSource();
  final readyCompleter = Completer();
  source.stateNotifier.addListener(() {
    if (source.isReady) {
      readyCompleter.complete();
    }
  });
  await source.init(canAnalyze: false);
  await readyCompleter.future;

  int curPrivacyGuardLevel = settings.curPrivacyGuardLevel;
  debugPrint('   privacyGuardLevels.all;${privacyGuardLevels.all}');
  PrivacyGuardLevelRow? curGuardLevel = privacyGuardLevels.all
      .firstWhere((e) => e.guardLevel == curPrivacyGuardLevel && e.isActive,
      orElse: () => privacyGuardLevels.all.firstWhere((e) => e.guardLevel == 1));

  if (curGuardLevel == null) {
    curPrivacyGuardLevel = 1;
    curGuardLevel = privacyGuardLevels.all.firstWhere((e) => e.guardLevel == 1);
  }

  final guardLevel = curGuardLevel.guardLevel.toString();
  final titleName = curGuardLevel.aliasName;
  final updateColor = curGuardLevel.color ?? privacyGuardLevels.getRandomColor();

  debugPrint('Back to Kotlin _channel.invokeMethod updateNotification $guardLevel $titleName ${updateColor.value.toString()} ${updateColor.toString()}');

  return {
    'guardLevel': guardLevel,
    'titleName': titleName,
    'color': updateColor.toString(),
  };
}
