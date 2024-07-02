import 'package:aves/model/foreground_wallpaper/fgw_used_entry_record.dart';
import 'package:aves/widgets/common/action_mixins/feedback.dart';
import 'package:aves/widgets/common/basic/scaffold.dart';
import 'package:aves/widgets/common/extensions/build_context.dart';
import 'package:flutter/material.dart';

import '../../../../model/foreground_wallpaper/foreground_wallpaper_helper.dart';

class ForegroundWallpaperDefaultSchedulesManagerPage extends StatelessWidget
    with FeedbackMixin {
  static const routeName = '/settings/classified/wallpaper_default_schedules';

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
          ListTile(
            title: Text(l10n.settingsResetAllToDefault3L5F),
            trailing: ElevatedButton(
              onPressed: () => _showConfirmationDialog(
                context,
                l10n.settingsResetAllToDefault3L5F,
                l10n.confirmResetAllToDefault3L5F,
                () {
                  _resetAllToDefault3L5T(context);
                },
              ),
              child: Text(l10n.applyButtonLabel),
            ),
          ),
          const Divider(height: 32),
          ListTile(
            title: Text(l10n.settingsAddNew3L5FGroup),
            trailing: ElevatedButton(
              onPressed: () => _showConfirmationDialog(
                context,
                l10n.settingsAddNew3L5FGroup,
                l10n.confirmAddNew3L5FGroup,
                () {
                  _addNew3L5FGroup(context);
                },
              ),
              child: Text(l10n.applyButtonLabel),
            ),
          ),
          ListTile(
            title: Text(l10n.settingsClearRecentUsedEntryRecord),
            trailing: ElevatedButton(
              onPressed: () => _showConfirmationDialog(
                context,
                l10n.settingsClearRecentUsedEntryRecord,
                l10n.confirmClearRecentUsedEntryRecord,
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
      builder: (BuildContext context) {
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

  Future<void> _resetAllToDefault3L5T(BuildContext context) async {
    await foregroundWallpaperHelper.clearWallpaperSchedules();
    await foregroundWallpaperHelper.initWallpaperSchedules();
    showFeedback(context, FeedbackType.info, context.l10n.resetCompletedFeedback);
  }

  Future<void> _addNew3L5FGroup(BuildContext context) async {
    await foregroundWallpaperHelper.addDynamicSets();
    showFeedback(context, FeedbackType.info, context.l10n.applyCompletedFeedback);
  }

  Future<void> _clearAllFgwUsedRecord(BuildContext context) async {
    await fgwUsedEntryRecord.clear();
    showFeedback(context, FeedbackType.info,context.l10n.clearCompletedFeedback );
  }
}
