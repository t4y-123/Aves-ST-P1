import 'package:aves/model/foreground_wallpaper/enum/fgw_schedule_item.dart';
import 'package:aves/model/foreground_wallpaper/fgw_used_entry_record.dart';
import 'package:aves/widgets/common/action_mixins/feedback.dart';
import 'package:aves/widgets/common/basic/scaffold.dart';
import 'package:aves/widgets/common/extensions/build_context.dart';
import 'package:flutter/material.dart';

import '../../../../model/foreground_wallpaper/fgw_schedule_group_helper.dart';
import '../../../../model/foreground_wallpaper/wallpaper_schedule.dart';
import '../../../../model/settings/settings.dart';
import '../../../../services/fgw_service_handler.dart';
import '../../common/tiles.dart';


class ForegroundWallpaperDefaultSchedulesManagerPage extends StatelessWidget
    with FeedbackMixin {
  static const routeName = '/settings/presentation/wallpaper_default_schedules';

  const ForegroundWallpaperDefaultSchedulesManagerPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AvesScaffold(
      appBar: AppBar(
        title: Text(l10n.settingsWallpaperSchedulesManagerTitle),
      ),
      body: SafeArea(
        child: ListView(children: [
          SettingsSelectionListTile<FgwScheduleSetType>(
            values: FgwScheduleSetType.values,
            getName: (context, v) => v.getName(context),
            selector: (context, s) => s.fgwScheduleSet,
            onSelection: (v) {
              settings.fgwScheduleSet = v;
              _showConfirmationDialog(
                context,
                l10n.settingsFgwScheduleResetToDefault,
                l10n.confirmResetAllScheduleToDefault,
                    () {
                    _resetAllToDefault(context,v);
                },
              );
            },
            tileTitle: context.l10n.settingsFgwScheduleResetToDefault,
            dialogTitle:context.l10n.settingsFgwScheduleResetToDefault,
          ),
          SettingsSelectionListTile<FgwScheduleSetType>(
            values: FgwScheduleSetType.values,
            getName: (context, v) => v.getName(context),
            selector: (context, s) => s.fgwScheduleSet,
            onSelection: (v) {
              settings.fgwScheduleSet = v;
              _showConfirmationDialog(
                context,
                l10n.settingsAddNewScheduleGroup,
                l10n.confirmAddNewScheduleGroup,
                    () {
                  _addNewScheduleGroup(context,v);
                },
              );
            },
            tileTitle: context.l10n.settingsAddNewScheduleGroup,
            dialogTitle:context.l10n.settingsAddNewScheduleGroup,
          ),
          SettingsSelectionListTile<FgwDisplayedType>(
            values: FgwDisplayedType.values,
            getName: (context, v) => v.getName(context),
            selector: (context, s) => s.fgwDisplayType,
            onSelection: (v) {
              settings.fgwDisplayType = v;
              _showConfirmationDialog(
                context,
                l10n.settingsSetAllFgwScheduleDisplayType,
                l10n.confirmSetAllFgwScheduleDisplayType,
                    () {
                      _setAllScheduleDisplayType(context,v);
                },
              );
            },
            tileTitle: context.l10n.settingsSetAllFgwScheduleDisplayType,
            dialogTitle:context.l10n.settingsSetAllFgwScheduleDisplayType,
          ),
          ListTile(
            title: Text('${l10n.settingsFgwScheduleSyncButtonText} '),
            trailing: ElevatedButton(
              onPressed: () async {
                await ForegroundWallpaperService.syncFgwScheduleChanges();
                await showDialog(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      title: Text(context.l10n.settingsFgwScheduleSyncButtonText),
                      content: Text(context.l10n.settingsFgwScheduleSyncButtonAlert),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: Text(context.l10n.applyTooltip),
                        ),
                      ],
                    );
                  },
                );
              },
              child: Text(l10n.applyButtonLabel),
            ),
          ),
          ListTile(
            title: Text(l10n.settingsClearRecentUsedEntryRecord),
            trailing: ElevatedButton(
              onPressed: () => _showConfirmationDialog(
                context,
                l10n.settingsClearRecentUsedEntryRecord,
                l10n.confirmClearRecentUsedEntryRecord(fgwUsedEntryRecord.all.length),
                    () {
                  _clearAllFgwUsedRecord(context);
                },
              ),
              child: Text(l10n.applyButtonLabel),
            ),
          ),
        ]),
      ),
    );
  }

  void _showConfirmationDialog(BuildContext context, String title,
      String content, VoidCallback onConfirm) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                onConfirm();
              },
              child: Text(MaterialLocalizations.of(context).okButtonLabel),
            ),
          ],
        );
      },
    );
  }

  Future<void> _resetAllToDefault(BuildContext context,FgwScheduleSetType scheduleSetType) async {
    await foregroundWallpaperHelper.clearWallpaperSchedules();
    await foregroundWallpaperHelper.initWallpaperSchedules(fgwScheduleSetType:scheduleSetType);
    showFeedback(context, FeedbackType.info, context.l10n.resetCompletedFeedback);
  }

  Future<void> _addNewScheduleGroup(BuildContext context,FgwScheduleSetType scheduleSetType) async {
    await foregroundWallpaperHelper.addDefaultScheduleSet(fgwScheduleSetType:scheduleSetType);
    showFeedback(context, FeedbackType.info, context.l10n.applyCompletedFeedback);
  }

  void _setAllScheduleDisplayType(BuildContext context, FgwDisplayedType newDisplayType) {
    final allRows = wallpaperSchedules.all;
    final newValues = {WallpaperScheduleRow.propDisplayType: newDisplayType};
    wallpaperSchedules.setExistRows(allRows, newValues);
    showFeedback(context, FeedbackType.info, context.l10n.applyCompletedFeedback);
  }

  Future<void> _clearAllFgwUsedRecord(BuildContext context) async {
    await fgwUsedEntryRecord.clear();
    showFeedback(context, FeedbackType.info,context.l10n.clearCompletedFeedback );
  }
}

