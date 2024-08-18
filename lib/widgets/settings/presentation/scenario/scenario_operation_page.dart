import 'package:aves/model/scenario/scenarios_helper.dart';
import 'package:aves/widgets/common/action_mixins/feedback.dart';
import 'package:aves/widgets/common/basic/scaffold.dart';
import 'package:aves/widgets/common/extensions/build_context.dart';
import 'package:flutter/material.dart';

class ScenariosOperationPage extends StatelessWidget with FeedbackMixin {
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
