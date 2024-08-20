import 'package:aves/model/device.dart';
import 'package:aves/model/scenario/enum/scenario_item.dart';
import 'package:aves/widgets/common/action_mixins/feedback.dart';
import 'package:aves/widgets/common/action_mixins/scenario_aware.dart';
import 'package:aves/widgets/common/extensions/build_context.dart';
import 'package:aves/widgets/common/identity/aves_caption.dart';
import 'package:aves/widgets/dialogs/aves_dialog.dart';
import 'package:aves/widgets/dialogs/selection_dialogs/common.dart';
import 'package:aves/widgets/dialogs/selection_dialogs/single_selection.dart';
import 'package:flutter/material.dart';

class EditScenarioLockDialog extends StatefulWidget {
  static const routeName = '/dialog/edit_scenario_lock';

  final ScenarioLockType? initialType;

  const EditScenarioLockDialog({
    super.key,
    this.initialType,
  });

  @override
  State<EditScenarioLockDialog> createState() => _EditScenarioLockDialogState();
}

class _EditScenarioLockDialogState extends State<EditScenarioLockDialog> with FeedbackMixin, ScenarioAwareMixin {
  late ScenarioLockType _lockType;

  final List<ScenarioLockType> _lockTypeOptions = [
    if (device.canAuthenticateUser) ScenarioLockType.system,
    if (device.canUseCrypto) ...[
      ScenarioLockType.pattern,
      ScenarioLockType.pin,
      ScenarioLockType.password,
    ],
  ];

  ScenarioLockType? get initialType => widget.initialType;

  @override
  void initState() {
    super.initState();
    _lockType = initialType ?? ScenarioLockType.pin;
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AvesDialog(
      title: l10n.configureScenarioLockTitle,
      scrollableContent: [
        if (_lockTypeOptions.length > 1)
          ListTile(
            title: Text(l10n.vaultDialogLockTypeLabel),
            subtitle: AvesCaption(_lockType.getText(context)),
            onTap: () {
              _unFocus();
              showSelectionDialog<ScenarioLockType>(
                context: context,
                builder: (context) => AvesSingleSelectionDialog<ScenarioLockType>(
                  initialValue: _lockType,
                  options: Map.fromEntries(_lockTypeOptions.map((v) => MapEntry(v, v.getText(context)))),
                ),
                onSelection: (v) => setState(() => _lockType = v),
              );
            },
          ),
      ],
      actions: [
        const CancelButton(),
        TextButton(
          onPressed: () => _submit(context),
          child: Text(l10n.applyButtonLabel),
        ),
      ],
    );
  }

  // remove focus, if any, to prevent the keyboard from showing up
  // after the user is done with the dialog
  void _unFocus() => FocusManager.instance.primaryFocus?.unfocus();

  Future<void> _submit(BuildContext context) async {
    _unFocus();

    if (!await setScenarioLockPass(context, _lockType)) return;

    Navigator.maybeOf(context)?.pop();
  }
}
