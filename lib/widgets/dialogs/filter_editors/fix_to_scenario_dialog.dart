import 'package:aves/model/filters/filters.dart';
import 'package:aves/model/scenario/enum/scenario_item.dart';
import 'package:aves/model/scenario/scenario.dart';
import 'package:aves/model/scenario/scenario_by_fix_details.dart';
import 'package:aves/model/scenario/scenario_step.dart';
import 'package:aves/widgets/common/action_mixins/feedback.dart';
import 'package:aves/widgets/common/action_mixins/vault_aware.dart';
import 'package:aves/widgets/common/extensions/build_context.dart';
import 'package:aves/widgets/common/identity/aves_caption.dart';
import 'package:aves/widgets/dialogs/aves_dialog.dart';
import 'package:aves/widgets/dialogs/selection_dialogs/common.dart';
import 'package:aves/widgets/dialogs/selection_dialogs/single_selection.dart';
import 'package:flutter/material.dart';

class Fix2ScenarioDialog extends StatefulWidget {
  static const routeName = '/dialog/fix_to_scenario';

  final ScenarioByFixDetails? initialDetails;
  final Set<CollectionFilter>? filters;

  const Fix2ScenarioDialog({
    super.key,
    this.initialDetails,
    this.filters,
  });

  @override
  State<Fix2ScenarioDialog> createState() => _Fix2ScenarioDialogState();
}

class _Fix2ScenarioDialogState extends State<Fix2ScenarioDialog> with FeedbackMixin, VaultAwareMixin {
  final TextEditingController _nameController = TextEditingController();
  late bool _autoTypeSuffix;
  late ScenarioLoadType _loadType;

  final ValueNotifier<bool> _isValidNotifier = ValueNotifier(false);

  final List<ScenarioLoadType> _loadTypeOptions = ScenarioLoadType.values;

  ScenarioByFixDetails? get initialDetails => widget.initialDetails;

  String get newName => _nameController.text;

  Set<CollectionFilter>? get _filters => widget.filters;

  @override
  void initState() {
    super.initState();
    final details = initialDetails ??
        ScenarioByFixDetails(
          name: '',
          autoTypeSuffix: true,
          loadType: _loadTypeOptions.first,
        );
    _nameController.text = details.name;
    _autoTypeSuffix = details.autoTypeSuffix;
    _loadType = details.loadType;
    _validate();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _isValidNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AvesDialog(
      title: l10n.fix2ScenarioDialogTitle,
      scrollableContent: [
        Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: l10n.fix2ScenarioName,
              ),
              onChanged: (_) => _validate(),
              onSubmitted: (_) => _submit(context),
            )),
        if (_loadTypeOptions.length > 1)
          ListTile(
            title: Text(l10n.settingsTileScenarioLoadType),
            subtitle: AvesCaption(_loadType.getName(context)),
            onTap: () {
              _unfocus();
              showSelectionDialog<ScenarioLoadType>(
                context: context,
                builder: (context) => AvesSingleSelectionDialog<ScenarioLoadType>(
                  initialValue: _loadType,
                  options: Map.fromEntries(_loadTypeOptions.map((v) => MapEntry(v, v.getName(context)))),
                ),
                onSelection: (v) => setState(() => _loadType = v),
              );
            },
          ),
        SwitchListTile(
          value: _autoTypeSuffix,
          onChanged: (v) => setState(() => _autoTypeSuffix = v),
          title: Text(l10n.autoScenarioTypeSuffix),
        ),
      ],
      actions: [
        const CancelButton(),
        ValueListenableBuilder<bool>(
          valueListenable: _isValidNotifier,
          builder: (context, isValid, child) {
            return TextButton(
              onPressed: isValid ? () => _submit(context) : null,
              child: Text(l10n.applyButtonLabel),
            );
          },
        ),
      ],
    );
  }

  // remove focus, if any, to prevent the keyboard from showing up
  // after the user is done with the dialog
  void _unfocus() => FocusManager.instance.primaryFocus?.unfocus();

  Future<void> _validate() async {
    final notEmpty = newName.isNotEmpty;
    _isValidNotifier.value = notEmpty;
  }

  Future<void> _submit(BuildContext context) async {
    if (!_isValidNotifier.value) return;

    _unfocus();

    final details = ScenarioByFixDetails(
      name: newName,
      autoTypeSuffix: _autoTypeSuffix,
      loadType: _loadType,
    );

    var scenarioName = details.name;
    if (details.autoTypeSuffix) {
      switch (details.loadType) {
        case ScenarioLoadType.excludeUnique:
          scenarioName = details.name + context.l10n.fix2ScenarioLoadTypeSuffixExclude;
        case ScenarioLoadType.unionOr:
          scenarioName = details.name + context.l10n.fix2ScenarioLoadTypeSuffixUnion;
        case ScenarioLoadType.intersectAnd:
          scenarioName = details.name + context.l10n.fix2ScenarioLoadTypeSuffixIntersect;
      }
    }
    final newScenario = await scenarios.newRow(1, labelName: scenarioName, loadType: details.loadType);
    final newScenarioStep = scenarioSteps.newRow(
      existMaxOrderNumOffset: 1,
      scenarioId: newScenario.id,
      existMaxStepNumOffset: 1,
      filters: _filters,
      loadType: ScenarioStepLoadType.intersectAnd,
      isActive: true,
    );
    // first
    await scenarios.add({newScenario});
    await scenarioSteps.add({newScenarioStep});

    showFeedback(context, FeedbackType.info, context.l10n.genericSuccessFeedback);
    Navigator.maybeOf(context)?.pop(details);
  }
}
