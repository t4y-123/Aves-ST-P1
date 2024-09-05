import 'dart:async';

import 'package:aves/model/fgw/enum/fgw_schedule_item.dart';
import 'package:aves/model/fgw/filters_set.dart';
import 'package:aves/model/fgw/guard_level.dart';
import 'package:aves/model/fgw/wallpaper_schedule.dart';
import 'package:aves/model/presentation/base_bridge_row.dart';
import 'package:aves/theme/colors.dart';
import 'package:aves/widgets/common/action_mixins/feedback.dart';
import 'package:aves/widgets/common/basic/list_tiles/color.dart';
import 'package:aves/widgets/common/extensions/build_context.dart';
import 'package:aves/widgets/settings/common/item_tiles.dart';
import 'package:aves/widgets/settings/presentation/common/section.dart';
import 'package:aves/widgets/settings/presentation/foreground_wallpaper/sub_page/schedule_item_page.dart';
import 'package:aves/widgets/settings/settings_definition.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class GuardLevelColorPickerTile extends SettingsTile {
  @override
  String title(BuildContext context) => context.l10n.settingsItemSelectColor;
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
        initialValue: item.color ?? AColors.getRandomColor(),
      ),
      routeSettings: const RouteSettings(name: ColorPickerDialog.routeName),
    );
    if (color != null) {
      final newRow = fgwGuardLevels.bridgeAll.firstWhere((e) => e.id == item.id).copyWith(color: color);
      await fgwGuardLevels.setRows({newRow}, type: PresentationRowType.bridgeAll);
    }
  }
}

class GuardLevelCopySchedulesFromExistListTile extends ItemSettingsTile<FgwGuardLevelRow> with FeedbackMixin {
  @override
  String title(BuildContext context) => context.l10n.settingsCopySchedulesFromExist;

  GuardLevelCopySchedulesFromExistListTile({required super.item});

  @override
  Widget build(BuildContext context) => ItemSettingsSelectionListTile<GuardLevel, FgwGuardLevelRow>(
        values: fgwGuardLevels.bridgeAll.toList(),
        getName: (context, v) => v.labelName,
        selector: (context, s) => s.bridgeAll.firstWhereOrNull((e) => e.id == item.id) ?? item,
        onSelection: (v) async {
          debugPrint('$runtimeType GuardLevelSelectButtonListTile\n' 'row $item \n' 'to value $v\n');

          // get src cope item value of select.
          final fromItems = fgwSchedules.bridgeAll.where((e) => e.guardLevelId == v.id);

          if (fromItems.isNotEmpty) {
            debugPrint('$runtimeType \n copiedSchedules $fromItems \n'
                'all ${fgwSchedules.all}\n bridgeAll: ${fgwSchedules.bridgeAll}\n');

            // copy every srcRow value to curRow diff in key: updateType-widgetId,
            for (final fromRow in fromItems) {
              //get curRow
              final curRow = fgwSchedules.bridgeAll.firstWhereOrNull((e) =>
                  e.guardLevelId == item.id && e.updateType == fromRow.updateType && e.widgetId == fromRow.widgetId);
              FgwScheduleRow? newRow;
              if (curRow != null) {
                newRow = fromRow.copyWith(
                    id: curRow.id, guardLevelId: item.id, orderNum: curRow.orderNum, labelName: curRow.labelName);
              } else {
                final tmpRow = fgwSchedules.newRow(
                    existMaxOrderNumOffset: 1,
                    guardLevelId: item.id,
                    filtersSetId: filtersSets.bridgeAll.first.id,
                    updateType: WallpaperUpdateType.widget);
                newRow = fromRow.copyWith(
                    id: tmpRow.id, guardLevelId: item.id, orderNum: tmpRow.orderNum, labelName: tmpRow.labelName);
              }
              debugPrint('$runtimeType \n curRow ${curRow?.toMap()} \n'
                  'newScheduleRow $newRow\n fromRow: $fromRow\n');
              //await fgwSchedules.setRows({newRow}, type: PresentationRowType.bridgeAll);
              await fgwSchedules.setWithDealConflictUpdateType({newRow}, type: PresentationRowType.bridgeAll);
            }
            showFeedback(context, FeedbackType.info, context.l10n.applyCompletedFeedback);
          } else {
            showFeedback(context, FeedbackType.warn, context.l10n.genericFailureFeedback);
          }
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
  @override
  Widget build(BuildContext context) =>
      ItemSettingsMultiSelectionWithExcludeSetListTile<FgwSchedule, WallpaperUpdateType>(
        values: const [WallpaperUpdateType.home, WallpaperUpdateType.lock, WallpaperUpdateType.both],
        getName: (context, v) => v.getName(context),
        selector: (context, s) =>
            s.bridgeAll.where((e) => e.isActive && e.guardLevelId == item.id).map((e) => e.updateType).toList(),
        onSelection: (v) async {
          // Iterate through all WallpaperUpdateType values
          for (var updateType in [WallpaperUpdateType.home, WallpaperUpdateType.lock, WallpaperUpdateType.both]) {
            // Check if the updateType is selected
            bool isSelected = v.contains(updateType);
            final curSchedule =
                fgwSchedules.bridgeAll.firstWhereOrNull((e) => e.guardLevelId == item.id && e.updateType == updateType);

            if (curSchedule != null) {
              // Copy with updated isActive value based on selection
              final newSchedule = curSchedule.copyWith(isActive: isSelected);
              await fgwSchedules.setWithDealConflictUpdateType({newSchedule}, type: PresentationRowType.bridgeAll);
            }
          }

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

class ScheduleItemPageTile extends ItemSettingsTile<FgwScheduleRow> {
  ScheduleItemPageTile({required super.item});

  @override
  String title(BuildContext context) {
    final titlePost = item.updateType == WallpaperUpdateType.widget
        ? '${item.updateType.getName(context)}: ${item.labelName}'
        : item.updateType.getName(context);
    return '${context.l10n.settingsGuardLevelScheduleSubPagePrefix}: $titlePost';
  }

  @override
  Widget build(BuildContext context) => ItemSettingsSubPageTile<FgwSchedule>(
        title: title(context),
        subtitleSelector: (context, s) {
          final subItem = fgwSchedules.bridgeAll.firstWhereOrNull((e) => e.id == item.id);
          final titlePost = subItem != null ? PresentRow.formatItemMap(subItem.toMap()) : null;
          return titlePost.toString();
        },
        routeName: FgwScheduleItemPage.routeName,
        builder: (context) => FgwScheduleItemPage(
          item: item,
        ),
      );
}
