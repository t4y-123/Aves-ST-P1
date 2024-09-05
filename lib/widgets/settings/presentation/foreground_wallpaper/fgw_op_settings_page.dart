import 'package:aves/model/fgw/enum/fgw_schedule_item.dart';
import 'package:aves/model/fgw/fgw_rows_helper.dart';
import 'package:aves/model/fgw/fgw_used_entry_record.dart';
import 'package:aves/model/fgw/guard_level.dart';
import 'package:aves/model/fgw/wallpaper_schedule.dart';
import 'package:aves/model/settings/settings.dart';
import 'package:aves/services/fgw_service_handler.dart';
import 'package:aves/theme/durations.dart';
import 'package:aves/widgets/common/action_mixins/feedback.dart';
import 'package:aves/widgets/common/action_mixins/fgw_aware.dart';
import 'package:aves/widgets/common/basic/scaffold.dart';
import 'package:aves/widgets/common/extensions/build_context.dart';
import 'package:aves/widgets/filter_grids/common/scenario/scenario_lock_setting_dialog.dart';
import 'package:aves/widgets/settings/common/tiles.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

class FgwOpSettingsPage extends StatelessWidget with FeedbackMixin, FgwAwareMixin {
  static const routeName = '/settings/presentation/fgw_op_settings_page';

  const FgwOpSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    settings.reload();
    return AvesScaffold(
      appBar: AppBar(
        title: Text(l10n.settingsFgwOpSettingsTitle),
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
                  _resetAllToDefault(context, v);
                },
              );
            },
            tileTitle: context.l10n.settingsFgwScheduleResetToDefault,
            dialogTitle: context.l10n.settingsFgwScheduleResetToDefault,
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
                  _addNewScheduleGroup(context, v);
                },
              );
            },
            tileTitle: context.l10n.settingsAddNewScheduleGroup,
            dialogTitle: context.l10n.settingsAddNewScheduleGroup,
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
                  _setAllScheduleDisplayType(context, v);
                },
              );
            },
            tileTitle: context.l10n.settingsSetAllFgwScheduleDisplayType,
            dialogTitle: context.l10n.settingsSetAllFgwScheduleDisplayType,
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
          SettingsSwitchListTile(
            selector: (context, s) => s.showFgwChipButton,
            onChanged: (v) => settings.showFgwChipButton = v,
            title: context.l10n.settingsShowChipFgwButton,
          ),
          SettingsSwitchListTile(
            selector: (context, s) => s.widgetUpdateWhenOpen,
            onChanged: (v) => settings.widgetUpdateWhenOpen = v,
            title: context.l10n.settingsWidgetUpdateWhenOpenPage,
          ),
          // Value Edit Tile for maxFgwUsedEntryRecord
          SettingsNumberEditTile(
            selector: (context, s) => s.maxFgwUsedEntryRecord,
            onChanged: (v) => settings.maxFgwUsedEntryRecord = v,
            title: l10n.settingsMaxFgwUsedEntryRecord,
            minValue: 0,
          ),
          // Item Selection Tile for curFgwGuardLevelNum
          SettingsSelectionListTile<int>(
            values: fgwGuardLevels.all.where((item) => item.isActive).toList().map((item) => item.guardLevel).toList(),
            getName: (context, v) {
              final selectedRow = fgwGuardLevels.all.firstWhere((item) => item.guardLevel == v);
              return '${selectedRow.guardLevel} ${selectedRow.labelName}';
            },
            selector: (context, s) => s.curFgwGuardLevelNum,
            onSelection: (v) async {
              if (settings.guardLevelLock) {
                if (!await unlockFgw(context)) {
                  showFeedback(context, FeedbackType.info, l10n.genericFailureFeedback);
                  return;
                }
              }
              settings.curFgwGuardLevelNum = v;
              showFeedback(context, FeedbackType.info, l10n.applyCompletedFeedback);
            },
            tileTitle: l10n.curFgwGuardLevelTitle,
            dialogTitle: l10n.curFgwGuardLevelTitle,
          ),
          ListTile(
            title: Text(l10n.settingsSetPassDefaultText),
            trailing: ElevatedButton(
              onPressed: () async {
                if (settings.guardLevelLock) {
                  if (!await unlockFgw(context)) return;
                }
                final details = await showDialog<EditLockTypeDialog>(
                  context: context,
                  builder: (context) => EditLockTypeDialog(
                    initialType: settings.guardLevelLockType,
                    onSubmitLockPass: setFgwLockPass,
                  ),
                  routeSettings: const RouteSettings(name: EditLockTypeDialog.routeName),
                );
                if (details == null) return;
                // wait for the dialog to hide as applying the change may block the UI
                await Future.delayed(ADurations.dialogTransitionAnimation * timeDilation);
              },
              child: Text(l10n.applyButtonLabel),
            ),
          ),
          SettingsSwitchListTile(
            selector: (context, s) => s.guardLevelLock,
            onChanged: (v) async {
              if (!v) {
                if (!await unlockFgw(context)) {
                  settings.guardLevelLock = true;
                } else {
                  settings.guardLevelLock = false;
                }
              } else {
                settings.guardLevelLock = v;
              }
              await ForegroundWallpaperService.setFgwGuardLevelLockState(settings.guardLevelLock);
            },
            title: context.l10n.settingsLockFgwNotification,
          ),
        ]),
      ),
    );
  }

  void _showConfirmationDialog(BuildContext context, String title, String content, VoidCallback onConfirm) {
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

  Future<void> _resetAllToDefault(BuildContext context, FgwScheduleSetType scheduleSetType) async {
    await fgwRowsHelper.clearWallpaperSchedules();
    await fgwRowsHelper.initWallpaperSchedules(fgwScheduleSetType: scheduleSetType);
    showFeedback(context, FeedbackType.info, context.l10n.resetCompletedFeedback);
  }

  Future<void> _addNewScheduleGroup(BuildContext context, FgwScheduleSetType scheduleSetType) async {
    await fgwRowsHelper.addDefaultScheduleSet(fgwScheduleSetType: scheduleSetType);
    showFeedback(context, FeedbackType.info, context.l10n.applyCompletedFeedback);
  }

  void _setAllScheduleDisplayType(BuildContext context, FgwDisplayedType newDisplayType) {
    final allRows = fgwSchedules.all.map((e) => e.copyWith(displayType: newDisplayType)).toSet();
    fgwSchedules.setRows(allRows);
    showFeedback(context, FeedbackType.info, context.l10n.applyCompletedFeedback);
  }

  Future<void> _clearAllFgwUsedRecord(BuildContext context) async {
    await fgwUsedEntryRecord.clear();
    showFeedback(context, FeedbackType.info, context.l10n.clearCompletedFeedback);
  }
}
