import 'package:aves/services/common/services.dart';
import 'package:flutter/services.dart';

class ForegroundWallpaperWidgetService {
  // used for init set widget settings or change settings.
  static const _configureChannel = MethodChannel('deckers.thibault/aves/foreground_wallpaper_widget_configure');
  // used for update widget content.
  static const _updateChannel = MethodChannel('deckers.thibault/aves/foreground_wallpaper_handler');

  static Future<bool> configure() async {
    try {
      await _configureChannel.invokeMethod('configure');
      return true;
    } on PlatformException catch (e, stack) {
      await reportService.recordError(e, stack);
    }
    return false;
  }

  static Future<bool> update(int widgetId) async {
    try {
      await _updateChannel.invokeMethod('update_widget', <String, dynamic>{
        'widgetId': widgetId,
      });
      return true;
    } on PlatformException catch (e, stack) {
      await reportService.recordError(e, stack);
    }
    return false;
  }
}
