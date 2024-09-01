import 'dart:async';

import 'package:aves/model/fgw/enum/fgw_schedule_item.dart';
import 'package:aves/model/fgw/fgw_schedule_helper.dart';
import 'package:aves/model/fgw/guard_level.dart';
import 'package:aves/model/fgw/wallpaper_schedule.dart';
import 'package:aves/model/presentation/base_bridge_row.dart';
import 'package:aves/widgets/common/action_mixins/feedback.dart';
import 'package:aves/widgets/common/basic/list_tiles/color.dart';
import 'package:aves/widgets/common/extensions/build_context.dart';
import 'package:aves/widgets/settings/common/item_tiles.dart';
import 'package:aves/widgets/settings/settings_definition.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'guard_level_schedules_sub_page.dart';

class GuardLevelTitleTile extends SettingsTile {
  @override
  String title(BuildContext context) => '${context.l10n.guardLevelNamePrefix}:${item.guardLevel}';

  final FgwGuardLevelRow item;

  GuardLevelTitleTile({
    required this.item,
  });

  @override
  Widget build(BuildContext context) => ItemInfoListTile<GuardLevel>(
        tileTitle: title(context),
        selector: (context, levels) {
          debugPrint('$runtimeType GuardLevelLabelNameModifiedTile\n'
              'item: $item \n'
              'rows ${levels.all} \n'
              'bridges ${levels.bridgeAll}\n');
          return ('id:${item.id}');
        },
      );
}

class GuardLevelLabelNameModifiedTile extends SettingsTile {
  @override
  String title(BuildContext context) => context.l10n.renameLabelNameTileTitle;
  final FgwGuardLevelRow item;

  GuardLevelLabelNameModifiedTile({
    required this.item,
  });

  @override
  Widget build(BuildContext context) => ItemSettingsLabelNameListTile<GuardLevel>(
        tileTitle: title(context),
        selector: (context, levels) {
          debugPrint('$runtimeType GuardLevelLabelNameModifiedTile\n'
              'item: $item \n'
              'rows ${levels.all} \n'
              'bridges ${levels.bridgeAll}\n');
          final row = levels.bridgeAll.firstWhereOrNull((e) => e.id == item.id);
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
          if (fgwGuardLevels.bridgeAll.map((e) => e.id).contains(item.id)) {
            fgwGuardLevels.setExistRows(
                rows: {item}, newValues: {PresentRow.propLabelName: value}, type: PresentationRowType.bridgeAll);
          }
          ;
        },
      );
}

class GuardLevelColorPickerTile extends SettingsTile {
  @override
  String title(BuildContext context) => context.l10n.settingsGuardLevelColor;
  final FgwGuardLevelRow item;

  GuardLevelColorPickerTile({
    required this.item,
  });

  @override
  Widget build(BuildContext context) => Selector<GuardLevel, Color>(
        selector: (context, s) => s.bridgeAll.firstWhereOrNull((e) => e.id == item.id)?.color ?? Colors.transparent,
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
        initialValue: item.color ?? fgwGuardLevels.getRandomColor(),
      ),
      routeSettings: const RouteSettings(name: ColorPickerDialog.routeName),
    );
    if (color != null) {
      if (fgwGuardLevels.bridgeAll.map((e) => e.id).contains(item.id)) {
        await fgwGuardLevels.setExistRows(
            rows: {item}, newValues: {FgwGuardLevelRow.propColor: color}, type: PresentationRowType.bridgeAll);
      }
      ;
    }
  }
}

class GuardLevelCopySchedulesFromExistListTile extends SettingsTile with FeedbackMixin {
  @override
  String title(BuildContext context) => context.l10n.settingsCopySchedulesFromExist;
  final FgwGuardLevelRow item;

  GuardLevelCopySchedulesFromExistListTile({
    required this.item,
  });

  @override
  Widget build(BuildContext context) => ItemSettingsSelectionListTile<GuardLevel, FgwGuardLevelRow>(
        values: fgwGuardLevels.bridgeAll.toList(),
        getName: (context, v) => v.labelName,
        selector: (context, s) => s.bridgeAll.firstWhereOrNull((e) => e.id == item.id) ?? item,
        onSelection: (v) async {
          debugPrint('$runtimeType GuardLevelSelectButtonListTile\n'
              'row ${item} \n'
              'to value $v\n');
          final copiedSchedules = await fgwScheduleHelper.getGuardLevelSchedules(
              curPrivacyGuardLevel: v, rowsType: PresentationRowType.bridgeAll);
          debugPrint('$runtimeType GuardLevelSelectButtonListTile\n'
              'copiedSchedules $copiedSchedules \n'
              'all ${fgwSchedules.all}\n'
              'bridgeAll: ${fgwSchedules.bridgeAll}\n');
          for (final newRow in copiedSchedules) {
            final curLevelBridgeRow = fgwSchedules.bridgeAll.firstWhereOrNull(
                (e) => e.guardLevelId == item.id && newRow.updateType == e.updateType && newRow.widgetId == e.widgetId);
            if (curLevelBridgeRow != null) {
              await fgwSchedules.setExistRows(
                {curLevelBridgeRow},
                {
                  FgwScheduleRow.propLabelName: newRow.labelName,
                  FgwScheduleRow.propFiltersSetId: newRow.filtersSetId,
                  FgwScheduleRow.propDisplayType: newRow.displayType,
                  FgwScheduleRow.propInterval: newRow.interval,
                  FgwScheduleRow.propIsActive: newRow.isActive,
                },
                type: PresentationRowType.bridgeAll,
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
  final FgwGuardLevelRow item;

  GuardLevelScheduleUpdateTypeListTile({
    required this.item,
  });

  @override
  Widget build(BuildContext context) =>
      ItemSettingsMultiSelectionWithExcludeSetListTile<FgwSchedule, WallpaperUpdateType>(
        values: const [WallpaperUpdateType.home, WallpaperUpdateType.lock, WallpaperUpdateType.both],
        getName: (context, v) => v.getName(context),
        selector: (context, s) =>
            s.bridgeAll.where((e) => e.isActive && e.guardLevelId == item.id).map((e) => e.updateType).toList(),
        onSelection: (v) async {
          v.forEach((updateType) async {
            final curSchedule =
                fgwSchedules.bridgeAll.firstWhereOrNull((e) => e.guardLevelId == item.id && e.updateType == updateType);
            if (curSchedule != null) {
              await fgwSchedules.setExistRows({curSchedule}, {FgwScheduleRow.propIsActive: true},
                  type: PresentationRowType.bridgeAll);
            }
          });
          debugPrint(
              '$runtimeType GuardLevelSelectButtonListTile\nwallpaperSchedules.bridgeAll \n ${fgwSchedules.bridgeAll} \n');
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

  final FgwGuardLevelRow item;
  final FgwScheduleRow schedule;

  ScheduleSubPageTile({
    required this.item,
    required this.schedule,
  });

  @override
  Widget build(BuildContext context) => ItemSettingsSubPageTile<FgwSchedule>(
        title: title(context),
        subtitleSelector: (context, s) {
          final titlePost = fgwSchedules.bridgeAll.firstWhereOrNull((e) => e.id == schedule.id)?.toMap().toString();
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
  String title(BuildContext context) => context.l10n.settingsActiveTitle;

  final FgwGuardLevelRow item;

  GuardLevelActiveListTile({
    required this.item,
  });

  @override
  Widget build(BuildContext context) => ItemSettingsSwitchListTile<GuardLevel>(
        selector: (context, s) => s.bridgeAll.firstWhereOrNull((e) => e.id == item.id)?.isActive ?? item.isActive,
        onChanged: (v) async {
          final curLevel = fgwGuardLevels.bridgeAll.firstWhereOrNull((e) => e.id == item.id) ?? item;
          await fgwGuardLevels.setExistRows(
            rows: {curLevel},
            newValues: {
              PresentRow.propIsActive: v,
            },
            type: PresentationRowType.bridgeAll,
          );
        },
        title: title(context),
      );
}
