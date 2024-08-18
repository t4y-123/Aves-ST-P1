import 'dart:async';

import 'package:aves/theme/colors.dart';
import 'package:aves/theme/icons.dart';
import 'package:aves/widgets/common/extensions/build_context.dart';
import 'package:aves/widgets/settings/common/tile_leading.dart';
import 'package:aves/widgets/settings/common/tiles.dart';
import 'package:aves/widgets/settings/navigation/drawer.dart';
import 'package:aves/widgets/settings/presentation/scenario/scenario_config_page.dart';
import 'package:aves/widgets/settings/presentation/scenario/scenario_operation_page.dart';
import 'package:aves/widgets/settings/presentation/share_by_copy.dart';
import 'package:aves/widgets/settings/settings_definition.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'foreground_wallpaper/default_schedules_manage_page.dart';
import 'foreground_wallpaper/foreground_wallpaper_config_page.dart';

class PresentationSection extends SettingsSection {
  @override
  String get key => 'presentation';

  @override
  Widget icon(BuildContext context) => SettingsTileLeading(
        icon: AIcons.presentation,
        color: context.select<AvesColorsData, Color>((v) => v.presentation),
      );

  @override
  String title(BuildContext context) => context.l10n.settingsPresentationSectionTitle;

  @override
  FutureOr<List<SettingsTile>> tiles(BuildContext context) => [
        SettingsTileForegroundWallpaperDrawer(),
        SettingsTileAddDefaultGroupsSchedules(),
        SettingsTileShareByCopy(),
        SettingsTileScenariosConfigPage(),
        SettingsScenariosOperationPage(),
      ];
}

class SettingsTileForegroundWallpaperDrawer extends SettingsTile {
  @override
  String title(BuildContext context) => context.l10n.settingsPresentationForegroundWallpaperConfigTile;

  @override
  Widget build(BuildContext context) => SettingsSubPageTile(
        title: title(context),
        routeName: NavigationDrawerEditorPage.routeName,
        builder: (context) => const ForegroundWallpaperConfigPage(),
      );
}

class SettingsTileAddDefaultGroupsSchedules extends SettingsTile {
  @override
  String title(BuildContext context) => context.l10n.settingsPresentationWallpaperAddDefaultScheduleTile;

  @override
  Widget build(BuildContext context) => SettingsSubPageTile(
        title: title(context),
        routeName: NavigationDrawerEditorPage.routeName,
        builder: (context) => const ForegroundWallpaperDefaultSchedulesManagerPage(),
      );
}

class SettingsTileShareByCopy extends SettingsTile {
  @override
  String title(BuildContext context) => context.l10n.settingsShareByCopyTile;

  @override
  Widget build(BuildContext context) => SettingsSubPageTile(
        title: title(context),
        routeName: ShareByCopyPage.routeName,
        builder: (context) => const ShareByCopyPage(),
      );
}

class SettingsTileScenariosConfigPage extends SettingsTile {
  @override
  String title(BuildContext context) => context.l10n.settingsScenariosConfigPageTile;

  @override
  Widget build(BuildContext context) => SettingsSubPageTile(
        title: title(context),
        routeName: ScenarioConfigPage.routeName,
        builder: (context) => const ScenarioConfigPage(),
      );
}

class SettingsScenariosOperationPage extends SettingsTile {
  @override
  String title(BuildContext context) => context.l10n.settingsScenariosOperationTile;

  @override
  Widget build(BuildContext context) => SettingsSubPageTile(
        title: title(context),
        routeName: ScenariosOperationPage.routeName,
        builder: (context) => const ScenariosOperationPage(),
      );
}
