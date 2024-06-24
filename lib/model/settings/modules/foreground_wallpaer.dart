import 'package:aves/model/device.dart';
import 'package:aves/model/settings/defaults.dart';
import 'package:aves/widgets/common/extensions/build_context.dart';
import 'package:aves_model/aves_model.dart';

mixin ForegroundWallpaperSettings on SettingsAccess {

  static const defaultNewUpdateIntervalKey = 'default_wallpaper_updateIntervalKey';
  int get defaultNewUpdateInterval => getInt(defaultNewUpdateIntervalKey) ?? SettingsDefaults.fgwNewUpdateInterval;
  set defaultNewUpdateInterval(int newValue) => set(defaultNewUpdateIntervalKey, newValue);

  static const curPrivacyGuardLevelKey = 'current_privcay_guard_level';
  int get curPrivacyGuardLevel => getInt(curPrivacyGuardLevelKey) ?? SettingsDefaults.defaultPrivacyGuardLevel;
  set curPrivacyGuardLevel(int newValue) => set(curPrivacyGuardLevelKey, newValue);

  static const maxForegroundWallpaperUsedEntryKey = 'max_foreground_wallpaper_used_entry_record';
  int get maxFgwUsedEntryRecord => getInt(maxForegroundWallpaperUsedEntryKey) ?? SettingsDefaults.maxFgwUsedEntryRecord;
  set maxFgwUsedEntryRecord(int newValue) => set(maxForegroundWallpaperUsedEntryKey, newValue);

  static const tmpPrivacyGuardLevelKey = 'tmp_privcay_guard_level';
  int get tmpPrivacyGuardLevel => getInt(tmpPrivacyGuardLevelKey) ?? SettingsDefaults.defaultPrivacyGuardLevel;
  set tmpPrivacyGuardLevel(int newValue) => set(tmpPrivacyGuardLevelKey, newValue);

  static const resetPrivacyGuardLevelDurationKey = 'reset_privcay_guard_level';
  int get resetPrivacyGuardLevelDuration => getInt(resetPrivacyGuardLevelDurationKey) ?? SettingsDefaults.resetPrivacyGuardLevelDuraiont;
  set resetPrivacyGuardLevelDuration(int newValue) => set(resetPrivacyGuardLevelDurationKey, newValue);


}
