import 'dart:async';

import 'package:aves/model/settings/settings.dart';
import 'package:aves/theme/colors.dart';
import 'package:aves/theme/icons.dart';
import 'package:aves/widgets/common/extensions/build_context.dart';
import 'package:aves/widgets/settings/common/tile_leading.dart';
import 'package:aves/widgets/settings/common/tiles.dart';
import 'package:aves/widgets/settings/navigation/drawer.dart';
import 'package:aves/widgets/settings/presentation/assign/assign_edit_config_page.dart';
import 'package:aves/widgets/settings/presentation/assign/assign_operation_page.dart';
import 'package:aves/widgets/settings/presentation/foreground_wallpaper/default_schedules_manage_page.dart';
import 'package:aves/widgets/settings/presentation/foreground_wallpaper/fgw_edit_setting_page.dart';
import 'package:aves/widgets/settings/presentation/scenario/scenario_config_page.dart';
import 'package:aves/widgets/settings/presentation/scenario/scenario_operation_page.dart';
import 'package:aves/widgets/settings/presentation/share_by_copy.dart';
import 'package:aves/widgets/settings/settings_definition.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:aves/widgets/settings/presentation/widget/wdiget_edit_setting_page.dart';

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
        if (!settings.scenarioLock) SettingsTileScenariosConfigPage(),
        if (!settings.scenarioLock) SettingsScenariosOperationPage(),
        SettingsAssignEditConfigPage(),
        SettingsAssignOperationPage(),
        SettingsTileShareByCopy(),
        SettingsWidgetEditConfigPage(),
      ];
}

class SettingsTileForegroundWallpaperDrawer extends SettingsTile {
  @override
  String title(BuildContext context) => context.l10n.settingsPresentationForegroundWallpaperConfigTile;

  @override
  Widget build(BuildContext context) => SettingsSubPageTile(
        title: title(context),
        routeName: NavigationDrawerEditorPage.routeName,
        builder: (context) => const FgwEditSettingPage(),
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

class SettingsAssignEditConfigPage extends SettingsTile {
  @override
  String title(BuildContext context) => context.l10n.settingsAssignConfigPageTitle;

  @override
  Widget build(BuildContext context) => SettingsSubPageTile(
        title: title(context),
        routeName: AssignEditConfigPage.routeName,
        builder: (context) => const AssignEditConfigPage(),
      );
}

class SettingsAssignOperationPage extends SettingsTile {
  @override
  String title(BuildContext context) => context.l10n.settingsAssignOperationTitle;

  @override
  Widget build(BuildContext context) => SettingsSubPageTile(
        title: title(context),
        routeName: AssignOperationPage.routeName,
        builder: (context) => const AssignOperationPage(),
      );
}

class SettingsWidgetEditConfigPage extends SettingsTile {
  @override
  String title(BuildContext context) => context.l10n.widgetSettingPageTile;

  @override
  Widget build(BuildContext context) => SettingsSubPageTile(
        title: title(context),
        routeName: WidgetEditSettingPage.routeName,
        builder: (context) => const WidgetEditSettingPage(),
      );
}
