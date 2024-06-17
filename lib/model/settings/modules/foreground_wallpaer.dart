import 'package:aves/model/device.dart';
import 'package:aves/model/settings/defaults.dart';
import 'package:aves_model/aves_model.dart';

mixin ForegroundWallpaperSettings on SettingsAccess {
  static const defaultNewUpdateIntervalKey = 'default_wallpaper_updateIntervalKey';
  
  int get defaultNewUpdateInterval => getInt(defaultNewUpdateIntervalKey) ?? SettingsDefaults.defaultNewUpdateInterval;

  set defaultNewUpdateInterval(int newValue) => set(defaultNewUpdateIntervalKey, newValue);

  
}
