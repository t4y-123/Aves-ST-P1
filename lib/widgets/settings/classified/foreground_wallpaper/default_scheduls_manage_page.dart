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
            title: Text(l10n.settingsResetAllToDefault),
            trailing: ElevatedButton(
              onPressed: () => _showConfirmationDialog(
                context,
                l10n.settingsResetAllToDefault,
                l10n.confirmResetAllToDefault,
                () {
                  _resetAllToDefault(context);
                },
              ),
              child: Text(l10n.applyButtonLabel),
            ),
          ),
          const Divider(height: 32),
          ListTile(
            title: Text(l10n.settingsAddNewT3Group),
            trailing: ElevatedButton(
              onPressed: () => _showConfirmationDialog(
                context,
                l10n.settingsAddNewT3Group,
                l10n.confirmAddNewT3Group,
                () {
                  _addNewT3Group(context);
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

  Future<void> _resetAllToDefault(BuildContext context) async {
    await foregroundWallpaperHelper.clearWallpaperSchedules();
    await foregroundWallpaperHelper.initWallpaperSchedules();
    showFeedback(context, FeedbackType.info, 'Reset complete');
  }

  Future<void> _addNewT3Group(BuildContext context) async {
    await foregroundWallpaperHelper.addDynamicSets();
    showFeedback(context, FeedbackType.info, 'Add Complete');
  }
}
