import 'package:aves/model/scenario/scenarios_helper.dart';
import 'package:aves/model/settings/settings.dart';
import 'package:aves/theme/durations.dart';
import 'package:aves/widgets/common/action_mixins/feedback.dart';
import 'package:aves/widgets/common/action_mixins/scenario_aware.dart';
import 'package:aves/widgets/common/basic/scaffold.dart';
import 'package:aves/widgets/common/extensions/build_context.dart';
import 'package:aves/widgets/filter_grids/common/scenario/scenario_lock_setting_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

class ScenariosOperationPage extends StatelessWidget with FeedbackMixin, ScenarioAwareMixin {
  static const routeName = '/settings/presentation/scenarios_operation_page';

  const ScenariosOperationPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AvesScaffold(
      appBar: AppBar(
        title: Text(l10n.settingsScenariosOperationTitle),
      ),
      body: SafeArea(
        child: ListView(children: [
          ListTile(
            title: Text(l10n.settingsScenarioResetDefaultText),
            trailing: ElevatedButton(
              onPressed: () => _showConfirmationDialog(
                context,
                l10n.settingsScenarioResetDefaultText,
                l10n.settingsScenarioResetDefaultAlert,
                () {
                  _resetAllToDefault(context);
                },
              ),
              child: Text(l10n.applyButtonLabel),
            ),
          ),
          ListTile(
            title: Text(l10n.settingsScenarioSetScenarioPassDefaultText),
            trailing: ElevatedButton(
              onPressed: () async {
                if (settings.scenarioLock) {
                  if (!await unlockScenarios(context)) return;
                }
                final details = await showDialog<EditScenarioLockDialog>(
                  context: context,
                  builder: (context) => const EditScenarioLockDialog(),
                  routeSettings: const RouteSettings(name: EditScenarioLockDialog.routeName),
                );
                if (details == null) return;
                // wait for the dialog to hide as applying the change may block the UI
                await Future.delayed(ADurations.dialogTransitionAnimation * timeDilation);
              },
              child: Text(l10n.applyButtonLabel),
            ),
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
    await scenariosHelper.clearScenarios();
    await scenariosHelper.initScenarios();
    showFeedback(context, FeedbackType.info, context.l10n.resetCompletedFeedback);
  }
}
