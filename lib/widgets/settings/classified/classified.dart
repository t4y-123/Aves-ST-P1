import 'dart:async';

import 'package:aves/model/filters/album.dart';
import 'package:aves/theme/colors.dart';
import 'package:aves/theme/icons.dart';
import 'package:aves/widgets/common/extensions/build_context.dart';
import 'package:aves/widgets/settings/common/tile_leading.dart';
import 'package:aves/widgets/settings/common/tiles.dart';
import 'package:aves/widgets/settings/navigation/drawer.dart';
import 'package:aves/widgets/settings/settings_definition.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../model/settings/settings.dart';
import '../../../utils/android_file_utils.dart';
import 'foreground_wallpaper/default_scheduls_manage_page.dart';
import 'foreground_wallpaper/foreground_wallpaper_config_page.dart';

class ClassifiedSection extends SettingsSection {
  @override
  String get key => 'classified';

  @override
  Widget icon(BuildContext context) => SettingsTileLeading(
        icon: AIcons.classified,
        color: context.select<AvesColorsData, Color>((v) => v.classified),
      );

  @override
  String title(BuildContext context) =>
      context.l10n.settingsClassifiedSectionTitle;

  @override
  FutureOr<List<SettingsTile>> tiles(BuildContext context) => [
        SettingsTileForegroundWallpaperDrawer(),
        SettingsTileAddDefaultGroupsSchedules(),
        SettingsTileShareShowCopiedItems(),
      ];
}

class SettingsTileForegroundWallpaperDrawer extends SettingsTile {
  @override
  String title(BuildContext context) =>
      context.l10n.settingsClassifiedForegroundWallpaperConfigTile;

  @override
  Widget build(BuildContext context) => SettingsSubPageTile(
        title: title(context),
        routeName: NavigationDrawerEditorPage.routeName,
        builder: (context) => const ForegroundWallpaperConfigPage(),
      );
}

class SettingsTileAddDefaultGroupsSchedules extends SettingsTile {
  @override
  String title(BuildContext context) =>
      context.l10n.settingsClassifiedWallpaperAddDefaultScheduleTile;

  @override
  Widget build(BuildContext context) => SettingsSubPageTile(
        title: title(context),
        routeName: NavigationDrawerEditorPage.routeName,
        builder: (context) => const ForegroundWallpaperDefaultSchedulesManagerPage(),
      );
}


class SettingsTileShareShowCopiedItems extends SettingsTile {
  @override
  String title(BuildContext context) => context.l10n.settingsVideoShowAvesShareCopiedItems;

  @override
  Widget build(BuildContext context) => SettingsSwitchListTile(
    selector: (context, s) => !s.hiddenFilters.contains(AlbumFilter(androidFileUtils.avesShareByCopyPath, null)),
    onChanged: (v) => settings.changeFilterVisibility({AlbumFilter(androidFileUtils.avesShareByCopyPath, null)}, v),
    title: title(context),
  );
}