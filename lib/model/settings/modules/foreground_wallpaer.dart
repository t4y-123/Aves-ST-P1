import 'package:aves/model/fgw/enum/fgw_schedule_item.dart';
import 'package:aves/model/scenario/enum/scenario_item.dart';
import 'package:aves/model/settings/defaults.dart';
import 'package:aves/model/settings/enums/presentation.dart';
import 'package:aves_model/aves_model.dart';

mixin ForegroundWallpaperSettings on SettingsAccess {
  static const defaultNewUpdateIntervalKey = 'default_wallpaper_updateIntervalKey';

  int get defaultNewUpdateInterval => getInt(defaultNewUpdateIntervalKey) ?? SettingsDefaults.fgwNewUpdateInterval;

  set defaultNewUpdateInterval(int newValue) => set(defaultNewUpdateIntervalKey, newValue);

  static const curFgwGuardLevelKey = 'current_privacy_guard_level';

  int get curFgwGuardLevelNum => getInt(curFgwGuardLevelKey) ?? SettingsDefaults.fgwGuardLevel;

  set curFgwGuardLevelNum(int newValue) => set(curFgwGuardLevelKey, newValue);

  static const maxForegroundWallpaperUsedEntryKey = 'max_foreground_wallpaper_used_entry_record';

  int get maxFgwUsedEntryRecord => getInt(maxForegroundWallpaperUsedEntryKey) ?? SettingsDefaults.maxFgwUsedEntryRecord;

  set maxFgwUsedEntryRecord(int newValue) => set(maxForegroundWallpaperUsedEntryKey, newValue);

  static const tmpFgwGuardLevelKey = 'tmp_privacy_guard_level';

  int get tmpFgwGuardLevel => getInt(tmpFgwGuardLevelKey) ?? SettingsDefaults.fgwGuardLevel;

  set tmpFgwGuardLevel(int newValue) => set(tmpFgwGuardLevelKey, newValue);

  static const resetFgwGuardLevelDurationKey = 'reset_privacy_guard_level';

  int get resetFgwGuardLevelDuration =>
      getInt(resetFgwGuardLevelDurationKey) ?? SettingsDefaults.resetFgwGuardLevelDuration;

  set resetFgwGuardLevelDuration(int newValue) => set(resetFgwGuardLevelDurationKey, newValue);

  static const fgwCurEntryIdKey = 'fgw_current_entry_id';

  int getFgwCurEntryId(WallpaperUpdateType updateType, int widgetId) =>
      getInt('${fgwCurEntryIdKey}_${updateType}_$widgetId') ?? -1; // use -1 as not found
  void setFgwCurEntryId(WallpaperUpdateType updateType, int widgetId, int newValue) =>
      set('${fgwCurEntryIdKey}_${updateType}_$widgetId', newValue);

  static const fgwCurEntryUriKey = 'fgw_current_entry_uri';

  String getFgwCurEntryUri(WallpaperUpdateType updateType, int widgetId) =>
      getString('${fgwCurEntryUriKey}_${updateType}_$widgetId') ?? '';
  void setFgwCurEntryUri(WallpaperUpdateType updateType, int widgetId, String newValue) =>
      set('${fgwCurEntryUriKey}_${updateType}_$widgetId', newValue);

  static const fgwCurEntryMimeKey = 'fgw_current_entry_mime';

  String getFgwCurEntryMime(WallpaperUpdateType updateType, int widgetId) =>
      getString('${fgwCurEntryMimeKey}_${updateType}_$widgetId') ?? '';
  void setFgwCurEntryMime(WallpaperUpdateType updateType, int widgetId, String newValue) =>
      set('${fgwCurEntryMimeKey}_${updateType}_$widgetId', newValue);

  static const confirmSetDateToNowKey = 'confirm_set_date_to_now';
  set confirmSetDateToNow(bool newValue) => set(confirmSetDateToNowKey, newValue);
  bool get confirmSetDateToNow => getBool(confirmSetDateToNowKey) ?? SettingsDefaults.confirmSetDateToNow;

  static const confirmShareByCopyKey = 'confirm_share_by_copy';
  set confirmShareByCopy(bool newValue) => set(confirmShareByCopyKey, newValue);
  bool get confirmShareByCopy => getBool(confirmShareByCopyKey) ?? SettingsDefaults.confirmShareByCopy;

  static const shareByCopyExpiredAutoRemoveKey = 'share_by_copy_auto_remove';
  bool get shareByCopyExpiredAutoRemove =>
      getBool(shareByCopyExpiredAutoRemoveKey) ?? SettingsDefaults.shareByCopyExpiredAutoRemove;
  set shareByCopyExpiredAutoRemove(bool newValue) => set(shareByCopyExpiredAutoRemoveKey, newValue);

  static const shareByCopyExpiredRemoveUseBinKey = 'share_by_copy_auto_remove_use_bin';
  bool get shareByCopyExpiredRemoveUseBin =>
      getBool(shareByCopyExpiredRemoveUseBinKey) ?? SettingsDefaults.shareByCopyExpiredRemoveUseBin;
  set shareByCopyExpiredRemoveUseBin(bool newValue) => set(shareByCopyExpiredRemoveUseBinKey, newValue);

  static const shareByCopyCollectionPageAutoRemoveKey = 'share_by_copy_collection_page_auto_remove';
  bool get shareByCopyCollectionPageAutoRemove =>
      getBool(shareByCopyCollectionPageAutoRemoveKey) ?? SettingsDefaults.shareByCopyCollectionPageAutoRemove;
  set shareByCopyCollectionPageAutoRemove(bool newValue) => set(shareByCopyCollectionPageAutoRemoveKey, newValue);

  static const shareByCopyViewerPageAutoRemoveKey = 'share_by_copy_viewer_page_auto_remove';
  bool get shareByCopyViewerPageAutoRemove =>
      getBool(shareByCopyViewerPageAutoRemoveKey) ?? SettingsDefaults.shareByCopyViewerPageAutoRemove;
  set shareByCopyViewerPageAutoRemove(bool newValue) => set(shareByCopyViewerPageAutoRemoveKey, newValue);

  static const shareByCopyAppModeViewAutoRemoveKey = 'share_by_copy_app_mode_view_auto_remove';
  bool get shareByCopyAppModeViewAutoRemove =>
      getBool(shareByCopyAppModeViewAutoRemoveKey) ?? SettingsDefaults.shareByCopyAppModeViewAutoRemove;
  set shareByCopyAppModeViewAutoRemove(bool newValue) => set(shareByCopyAppModeViewAutoRemoveKey, newValue);

  static const shareByCopyRemoveIntervalKey = 'share_by_copy_remove_interval';
  int get shareByCopyRemoveInterval =>
      getInt(shareByCopyRemoveIntervalKey) ?? SettingsDefaults.shareByCopyRemoveInterval;
  set shareByCopyRemoveInterval(int newValue) => set(shareByCopyRemoveIntervalKey, newValue);

  static const shareByCopyObsoleteRecordRemoveIntervalKey = 'share_by_copy_obsolete_record_remove_interval';
  int get shareByCopyObsoleteRecordRemoveInterval =>
      getInt(shareByCopyObsoleteRecordRemoveIntervalKey) ?? SettingsDefaults.shareByCopyObsoleteRecordRemoveInterval;
  set shareByCopyObsoleteRecordRemoveInterval(int newValue) =>
      set(shareByCopyObsoleteRecordRemoveIntervalKey, newValue);

  static const shareByCopySetDateTypeKey = 'share_by_copy_set_date_type';
  ShareByCopySetDateType get shareByCopySetDateType => getEnumOrDefault(
      shareByCopySetDateTypeKey, SettingsDefaults.shareByCopySetDateType, ShareByCopySetDateType.values);
  set shareByCopySetDateType(ShareByCopySetDateType newValue) => set(shareByCopySetDateTypeKey, newValue.toString());

  static const fgwDisplayTypeKey = 'fgw_display_type';
  FgwDisplayedType get fgwDisplayType =>
      getEnumOrDefault(fgwDisplayTypeKey, SettingsDefaults.fgwDisplayedItem, FgwDisplayedType.values);
  set fgwDisplayType(FgwDisplayedType newValue) => set(fgwDisplayTypeKey, newValue.toString());

  static const fgwScheduleSetKey = 'fgw_schedule_group_set';
  FgwScheduleSetType get fgwScheduleSet =>
      getEnumOrDefault(fgwScheduleSetKey, SettingsDefaults.fgwScheduleSet, FgwScheduleSetType.values);
  set fgwScheduleSet(FgwScheduleSetType newValue) => set(fgwScheduleSetKey, newValue.toString());

  static const confirmEditAsCopiedFirstKey = 'confirm_edit_as_copied_first';
  set confirmEditAsCopiedFirst(bool newValue) => set(confirmEditAsCopiedFirstKey, newValue);
  bool get confirmEditAsCopiedFirst =>
      getBool(confirmEditAsCopiedFirstKey) ?? SettingsDefaults.confirmEditAsCopiedFirst;

  static const showFgwChipButtonKey = 'show_chip_fgw_button';
  set showFgwChipButton(bool newValue) => set(showFgwChipButtonKey, newValue);
  bool get showFgwChipButton => getBool(showFgwChipButtonKey) ?? SettingsDefaults.showFgwChipButton;

  static const guardLevelLockPassKey = 'guard_level_lock_password';
  static const guardLevelLockTypeKey = 'guard_level_lock_type';

  CommonLockType get guardLevelLockType =>
      getEnumOrDefault(guardLevelLockTypeKey, SettingsDefaults.guardLevelLockType, CommonLockType.values);

  set guardLevelLockType(CommonLockType newValue) => set(guardLevelLockTypeKey, newValue.toString());

  static const guardLevelLockKey = 'guard_level_lock';
  bool get guardLevelLock => getBool(guardLevelLockKey) ?? SettingsDefaults.guardLevelLock;
  set guardLevelLock(bool newValue) => set(guardLevelLockKey, newValue);

  static const widgetUpdateWhenOpenKey = 'widget_update_when_open';
  bool get widgetUpdateWhenOpen => getBool(widgetUpdateWhenOpenKey) ?? SettingsDefaults.guardLevelLock;
  set widgetUpdateWhenOpen(bool newValue) => set(widgetUpdateWhenOpenKey, newValue);
}
