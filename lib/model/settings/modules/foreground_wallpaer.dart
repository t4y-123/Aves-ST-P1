import 'package:aves/model/device.dart';
import 'package:aves/model/entry/entry.dart';
import 'package:aves/model/foreground_wallpaper/wallpaperSchedule.dart';
import 'package:aves/model/settings/defaults.dart';
import 'package:aves/widgets/common/extensions/build_context.dart';
import 'package:aves_model/aves_model.dart';

mixin ForegroundWallpaperSettings on SettingsAccess {
  static const defaultNewUpdateIntervalKey = 'default_wallpaper_updateIntervalKey';

  int get defaultNewUpdateInterval => getInt(defaultNewUpdateIntervalKey) ?? SettingsDefaults.fgwNewUpdateInterval;

  set defaultNewUpdateInterval(int newValue) => set(defaultNewUpdateIntervalKey, newValue);

  static const curPrivacyGuardLevelKey = 'current_privacy_guard_level';

  int get curPrivacyGuardLevel => getInt(curPrivacyGuardLevelKey) ?? SettingsDefaults.defaultPrivacyGuardLevel;

  set curPrivacyGuardLevel(int newValue) => set(curPrivacyGuardLevelKey, newValue);

  static const maxForegroundWallpaperUsedEntryKey = 'max_foreground_wallpaper_used_entry_record';

  int get maxFgwUsedEntryRecord => getInt(maxForegroundWallpaperUsedEntryKey) ?? SettingsDefaults.maxFgwUsedEntryRecord;

  set maxFgwUsedEntryRecord(int newValue) => set(maxForegroundWallpaperUsedEntryKey, newValue);

  static const tmpPrivacyGuardLevelKey = 'tmp_privacy_guard_level';

  int get tmpPrivacyGuardLevel => getInt(tmpPrivacyGuardLevelKey) ?? SettingsDefaults.defaultPrivacyGuardLevel;

  set tmpPrivacyGuardLevel(int newValue) => set(tmpPrivacyGuardLevelKey, newValue);

  static const resetPrivacyGuardLevelDurationKey = 'reset_privacy_guard_level';

  int get resetPrivacyGuardLevelDuration =>
      getInt(resetPrivacyGuardLevelDurationKey) ?? SettingsDefaults.resetPrivacyGuardLevelDuraiont;

  set resetPrivacyGuardLevelDuration(int newValue) => set(resetPrivacyGuardLevelDurationKey, newValue);

  static const fgwCurEntryIdKey = 'fgw_current_entry_id';

  int getFgwCurEntryId(WallpaperUpdateType updateType, int widgetId) =>
      getInt('${fgwCurEntryIdKey}_${updateType}_$widgetId') ?? -1; // use -1 as not found
  void setFgwCurEntryId(WallpaperUpdateType updateType, int widgetId, int newValue) =>
      set('${fgwCurEntryIdKey}_${updateType}_$widgetId', newValue);
}
