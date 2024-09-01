import 'dart:async';

import 'package:aves/services/common/services.dart';
import 'package:flutter/services.dart';

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

  static Future<Map<String, List<int>>> getAllWidgetIds() async {
    final Map<dynamic, dynamic> result = await _platform.invokeMethod('getAllWidgetIds');
    return Map<String, List<int>>.from(result.map((key, value) => MapEntry(key, List<int>.from(value))));
  }

  static Future<void> syncFgwScheduleChanges() async {
    await reportService.log('syncFgwScheduleChanges');
    try {
      await _platform.invokeMethod('syncFgwScheduleChanges');
    } on PlatformException catch (e, stack) {
      await reportService.recordError(e, stack);
    }
  }
}
