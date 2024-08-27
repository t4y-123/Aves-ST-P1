import 'package:aves/model/assign/assign_entries.dart';
import 'package:aves/model/assign/assign_record.dart';
import 'package:aves/model/assign/enum/assign_item.dart';
import 'package:aves/model/settings/settings.dart';
import 'package:aves/widgets/common/action_mixins/feedback.dart';
import 'package:aves/widgets/common/basic/scaffold.dart';
import 'package:aves/widgets/common/extensions/build_context.dart';
import 'package:aves/widgets/settings/common/tiles.dart';
import 'package:flutter/material.dart';

class AssignOperationPage extends StatelessWidget with FeedbackMixin {
  static const routeName = '/settings/presentation/scenarios_operation_page';

  const AssignOperationPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AvesScaffold(
      appBar: AppBar(
        title: Text(l10n.settingsAssignOperationTitle),
      ),
      body: SafeArea(
        child: ListView(children: [
          ListTile(
            title: Text(l10n.settingsAssignResetDefaultText),
            trailing: ElevatedButton(
              onPressed: () => _showConfirmationDialog(
                context,
                l10n.settingsAssignResetDefaultText,
                l10n.settingsAssignResetDefaultAlert,
                () {
                  _resetAllToDefault(context);
                },
              ),
              child: Text(l10n.applyButtonLabel),
            ),
          ),
          SettingsSelectionListTile<AssignTemporaryFollowAction>(
            values: AssignTemporaryFollowAction.values,
            getName: (context, v) => v.getName(context),
            selector: (context, s) => s.assignTemporaryFollowAction,
            onSelection: (v) => settings.assignTemporaryFollowAction = v,
            tileTitle: l10n.settingsAssignTemporaryFollowActionTile,
          ),
          SettingsDurationListTile(
            selector: (context, s) => s.assignTemporaryExpiredInterval,
            onChanged: (v) => settings.assignTemporaryExpiredInterval = v,
            title: l10n.settingsSlideshowIntervalTile,
          ),
          SettingsSwitchListTile(
            selector: (context, s) => s.canAutoRemoveExpiredTempAssign,
            onChanged: (v) => settings.canAutoRemoveExpiredTempAssign = v,
            title: l10n.settingsAutoRemoveExpiredTempAssign,
          ),
          SettingsSwitchListTile(
            selector: (context, s) => s.autoRemoveCorrespondScenarioAsTempAssignRemove,
            onChanged: (v) => settings.autoRemoveCorrespondScenarioAsTempAssignRemove = v,
            title: l10n.settingsAutoRemoveCorrespondScenarioAsTempAssignRemoveTile,
          ),
          SettingsSwitchListTile(
            selector: (context, s) => s.autoRemoveTempAssignAsCorrespondScenarioRemove,
            onChanged: (v) => settings.autoRemoveTempAssignAsCorrespondScenarioRemove = v,
            title: l10n.settingsAutoRemoveTempAssignAsCorrespondScenarioRemoveTile,
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

  Future<void> _resetAllToDefault(BuildContext context) async {
    await assignRecords.clear();
    await assignEntries.clear();
    showFeedback(context, FeedbackType.info, context.l10n.resetCompletedFeedback);
  }
}
