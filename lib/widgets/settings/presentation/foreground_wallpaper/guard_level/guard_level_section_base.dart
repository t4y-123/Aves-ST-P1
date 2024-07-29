import 'dart:async';

import 'package:aves/model/foreground_wallpaper/privacy_guard_level.dart';
import 'package:aves/model/foreground_wallpaper/wallpaper_schedule.dart';
import 'package:aves/widgets/common/action_mixins/feedback.dart';
import 'package:aves/widgets/common/extensions/build_context.dart';
import 'package:aves/widgets/settings/common/item_tiles.dart';

import 'package:aves/widgets/settings/settings_definition.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../../model/foreground_wallpaper/enum/fgw_schedule_item.dart';
import '../../../../../model/foreground_wallpaper/fgw_schedule_helper.dart';
import '../../../../common/basic/list_tiles/color.dart';
import '../schedule/generic_selection_page.dart';
import 'guard_level_schedules_sub_page.dart';

class GuardLevelTitleTile extends SettingsTile {
  @override
  String title(BuildContext context) => '${context.l10n.guardLevelNamePrefix}:${item.guardLevel}';

  final PrivacyGuardLevelRow item;

  GuardLevelTitleTile({
    required this.item,
  });

  @override
  Widget build(BuildContext context) => ItemInfoListTile<PrivacyGuardLevel>(
        tileTitle: title(context),
        selector: (context, levels) {
          debugPrint('$runtimeType GuardLevelLabelNameModifiedTile\n'
              'item: $item \n'
              'rows ${levels.all} \n'
              'bridges ${levels.bridgeAll}\n');
          return ('id:${item.privacyGuardLevelID}');
        },
      );
}

class GuardLevelLabelNameModifiedTile extends SettingsTile {
  @override
  String title(BuildContext context) => context.l10n.renameLabelNameTileTitle;
  final PrivacyGuardLevelRow item;

  GuardLevelLabelNameModifiedTile({
    required this.item,
  });

  @override
  Widget build(BuildContext context) => ItemSettingsLabelNameListTile<PrivacyGuardLevel>(
        tileTitle: title(context),
        selector: (context, levels) {
          debugPrint('$runtimeType GuardLevelLabelNameModifiedTile\n'
              'item: $item \n'
              'rows ${levels.all} \n'
              'bridges ${levels.bridgeAll}\n');
          final row = levels.bridgeAll.firstWhereOrNull((e) => e.privacyGuardLevelID == item.privacyGuardLevelID);
          if (row != null) {
            return row.labelName;
          } else {
            return 'Error';
          }
        },
        onChanged: (value) {
          debugPrint('$runtimeType GuardLevelSectionBaseSection\n'
              'row.labelName ${item.labelName} \n'
              'to value $value\n');
          if (privacyGuardLevels.bridgeAll.map((e) => e.privacyGuardLevelID).contains(item.privacyGuardLevelID)) {
            privacyGuardLevels.setExistRows(
                rows: {item}, newValues: {PrivacyGuardLevelRow.propLabelName: value}, type: LevelRowType.bridgeAll);
          }
          ;
        },
      );
}

class GuardLevelColorPickerTile extends SettingsTile {
  @override
  String title(BuildContext context) => context.l10n.settingsGuardLevelColor;
  final PrivacyGuardLevelRow item;

  GuardLevelColorPickerTile({
    required this.item,
  });

  @override
  Widget build(BuildContext context) => Selector<PrivacyGuardLevel, Color>(
        selector: (context, s) =>
            s.bridgeAll.firstWhereOrNull((e) => e.privacyGuardLevelID == item.privacyGuardLevelID)?.color ??
            Colors.transparent,
        builder: (context, current, child) => ListTile(
          title: Text(title(context)),
          trailing: GestureDetector(
            onTap: () {
              _pickColor(context);
            },
            child: Container(
              width: 24,
              height: 24,
              color: current,
            ),
          ),
        ),
      );

  Future<void> _pickColor(BuildContext context) async {
    final color = await showDialog<Color>(
      context: context,
      builder: (context) => ColorPickerDialog(
        initialValue: item.color ?? privacyGuardLevels.getRandomColor(),
      ),
      routeSettings: const RouteSettings(name: ColorPickerDialog.routeName),
    );
    if (color != null) {
      if (privacyGuardLevels.bridgeAll.map((e) => e.privacyGuardLevelID).contains(item.privacyGuardLevelID)) {
        await privacyGuardLevels.setExistRows(
            rows: {item}, newValues: {PrivacyGuardLevelRow.propColor: color}, type: LevelRowType.bridgeAll);
      }
      ;
    }
  }
}

class GuardLevelSelectButtonListTile2 extends SettingsTile {
  @override
  String title(BuildContext context) => context.l10n.settingsCopySchedulesFromExist;
  final PrivacyGuardLevelRow item;

  GuardLevelSelectButtonListTile2({
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(title(context)),
      onTap: () async {
        final Set<PrivacyGuardLevelRow> result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => GenericForegroundWallpaperItemsSelectionPage<PrivacyGuardLevelRow>(
              selectedItems: {privacyGuardLevels.bridgeAll.first},
              maxSelection: 1,
              allItems: privacyGuardLevels.bridgeAll.where((e) => e.isActive).toList(),
              displayString: (item) => '${context.l10n.guardLevelNamePrefix} ${item.guardLevel}: ${item.labelName}',
              itemId: (item) => item.guardLevel,
            ),
          ),
        );
        debugPrint('$runtimeType copied ${result.first}');
      },
    );
  }
}

class GuardLevelCopySchedulesFromExistListTile extends SettingsTile with FeedbackMixin {
  @override
  String title(BuildContext context) => context.l10n.settingsCopySchedulesFromExist;
  final PrivacyGuardLevelRow item;

  GuardLevelCopySchedulesFromExistListTile({
    required this.item,
  });

  @override
  Widget build(BuildContext context) => ItemSettingsSelectionListTile<PrivacyGuardLevel, PrivacyGuardLevelRow>(
        values: privacyGuardLevels.bridgeAll.toList(),
        getName: (context, v) => v.labelName,
        selector: (context, s) =>
            s.bridgeAll.firstWhereOrNull((e) => e.privacyGuardLevelID == item.privacyGuardLevelID) ?? item,
        onSelection: (v) async {
          debugPrint('$runtimeType GuardLevelSelectButtonListTile\n'
              'row ${item} \n'
              'to value $v\n');
          final copiedSchedules =
              await fgwScheduleHelper.getCurSchedules(curPrivacyGuardLevel: v, rowsType: ScheduleRowType.bridgeAll);
          debugPrint('$runtimeType GuardLevelSelectButtonListTile\n'
              'copiedSchedules $copiedSchedules \n'
              'all ${wallpaperSchedules.all}\n'
              'bridgeAll: ${wallpaperSchedules.bridgeAll}\n');
          for (final newRow in copiedSchedules) {
            final curLevelBridgeRow = wallpaperSchedules.bridgeAll.firstWhereOrNull((e) =>
                e.privacyGuardLevelId == item.privacyGuardLevelID &&
                newRow.updateType == e.updateType &&
                newRow.widgetId == e.widgetId);
            if (curLevelBridgeRow != null) {
              await wallpaperSchedules.setExistRows(
                {curLevelBridgeRow},
                {
                  WallpaperScheduleRow.propLabelName: newRow.labelName,
                  WallpaperScheduleRow.propFiltersSetId: newRow.filtersSetId,
                  WallpaperScheduleRow.propDisplayType: newRow.displayType,
                  WallpaperScheduleRow.propInterval: newRow.interval,
                  WallpaperScheduleRow.propIsActive: newRow.isActive,
                },
                type: ScheduleRowType.bridgeAll,
              );
            }
            debugPrint('$runtimeType curLevelBridgeRow\n'
                'new row:\n  ${newRow} \n'
                'after set:\n  ${curLevelBridgeRow} \n');
          }
          showFeedback(context, FeedbackType.info, context.l10n.applyCompletedFeedback);
          // t4y:TODO：　after copy, reset all related schedules.
        },
        tileTitle: title(context),
        dialogTitle: context.l10n.settingsCopySchedulesFromExist,
        showSubTitle: false,
      );
}

// t4y: to make it can deal with some group multi selection that should auto cancel the values not in the same group.
// like, in wallpaper schedule update, {home,lock} and {both} will cancel each other if any.
class GuardLevelScheduleUpdateTypeListTile extends SettingsTile {
  @override
  String title(BuildContext context) => context.l10n.settingsGuardLevelScheduleUpdateTypeMultiSelectionTitle;
  final PrivacyGuardLevelRow item;

  GuardLevelScheduleUpdateTypeListTile({
    required this.item,
  });

  @override
  Widget build(BuildContext context) =>
      ItemSettingsMultiSelectionWithExcludeSetListTile<WallpaperSchedules, WallpaperUpdateType>(
        values: const [WallpaperUpdateType.home, WallpaperUpdateType.lock, WallpaperUpdateType.both],
        getName: (context, v) => v.getName(context),
        selector: (context, s) => s.bridgeAll
            .where((e) => e.isActive && e.privacyGuardLevelId == item.privacyGuardLevelID)
            .map((e) => e.updateType)
            .toList(),
        onSelection: (v) async {
          v.forEach((updateType) async {
            final curSchedule = wallpaperSchedules.bridgeAll.firstWhereOrNull(
                (e) => e.privacyGuardLevelId == item.privacyGuardLevelID && e.updateType == updateType);
            if (curSchedule != null) {
              await wallpaperSchedules.setExistRows({curSchedule}, {WallpaperScheduleRow.propIsActive: true},
                  type: ScheduleRowType.bridgeAll);
            }
          });
          debugPrint(
              '$runtimeType GuardLevelSelectButtonListTile\nwallpaperSchedules.bridgeAll \n ${wallpaperSchedules.bridgeAll} \n');
        },
        tileTitle: title(context),
        noneSubtitle: context.l10n.settingsCollectionScheduleUpdateTypeMultiSelectionNone,
        optionSubtitleBuilder: (value) => value.name,
        conflictGroups: const [
          {WallpaperUpdateType.home, WallpaperUpdateType.lock},
          {WallpaperUpdateType.both}
        ],
      );
}

class ScheduleSubPageTile extends SettingsTile {
  @override
  String title(BuildContext context) {
    final titlePost = schedule.updateType == WallpaperUpdateType.widget
        ? '${schedule.updateType.getName(context)}:${schedule.widgetId}'
        : schedule.updateType.getName(context);
    return '${context.l10n.settingsGuardLevelScheduleSubPagePrefix}: $titlePost';
  }

  final PrivacyGuardLevelRow item;
  final WallpaperScheduleRow schedule;

  ScheduleSubPageTile({
    required this.item,
    required this.schedule,
  });

  @override
  Widget build(BuildContext context) => ItemSettingsSubPageTile<WallpaperSchedules>(
        title: title(context),
        subtitleSelector: (context, s) {
          final titlePost = wallpaperSchedules.bridgeAll.firstWhereOrNull((e) => e.id == schedule.id);
          return titlePost.toString();
        },
        routeName: GuardLevelScheduleSubPage.routeName,
        builder: (context) => GuardLevelScheduleSubPage(
          item: item,
          schedule: schedule,
        ),
      );
}

class GuardLevelActiveListTile extends SettingsTile {
  @override
  String title(BuildContext context) => context.l10n.settingsGuardLevelIsActiveTitle;

  final PrivacyGuardLevelRow item;

  GuardLevelActiveListTile({
    required this.item,
  });

  @override
  Widget build(BuildContext context) => ItemSettingsSwitchListTile<PrivacyGuardLevel>(
        selector: (context, s) =>
            s.bridgeAll.firstWhereOrNull((e) => e.privacyGuardLevelID == item.privacyGuardLevelID)?.isActive ??
            item.isActive,
        onChanged: (v) async {
          final curLevel =
              privacyGuardLevels.bridgeAll.firstWhereOrNull((e) => e.privacyGuardLevelID == item.privacyGuardLevelID) ??
                  item;
          await privacyGuardLevels.setExistRows(
            rows: {curLevel},
            newValues: {
              PrivacyGuardLevelRow.propIsActive: v,
            },
            type: LevelRowType.bridgeAll,
          );
        },
        title: title(context),
      );
}
