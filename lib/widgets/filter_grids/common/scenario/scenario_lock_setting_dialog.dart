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

class EditLockTypeDialog extends StatefulWidget {
  static const routeName = '/dialog/edit_scenario_lock';

  final CommonLockType? initialType;
  final Future<bool> Function(BuildContext, CommonLockType) onSubmitLockPass;

  const EditLockTypeDialog({
    super.key,
    this.initialType,
    required this.onSubmitLockPass,
  });

  @override
  State<EditLockTypeDialog> createState() => _EditLockTypeDialogState();
}

class _EditLockTypeDialogState extends State<EditLockTypeDialog> with FeedbackMixin, ScenarioAwareMixin {
  late CommonLockType _lockType;

  final List<CommonLockType> _lockTypeOptions = [
    if (device.canAuthenticateUser) CommonLockType.system,
    if (device.canUseCrypto) ...[
      CommonLockType.pattern,
      CommonLockType.pin,
      CommonLockType.password,
    ],
  ];

  CommonLockType? get initialType => widget.initialType;

  @override
  void initState() {
    super.initState();
    _lockType = initialType ?? CommonLockType.pin;
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AvesDialog(
      title: l10n.configureLockTitle,
      scrollableContent: [
        if (_lockTypeOptions.length > 1)
          ListTile(
            title: Text(l10n.vaultDialogLockTypeLabel),
            subtitle: AvesCaption(_lockType.getText(context)),
            onTap: () {
              _unFocus();
              showSelectionDialog<CommonLockType>(
                context: context,
                builder: (context) => AvesSingleSelectionDialog<CommonLockType>(
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

    if (!await widget.onSubmitLockPass(context, _lockType)) return;

    Navigator.maybeOf(context)?.pop();
  }
}
