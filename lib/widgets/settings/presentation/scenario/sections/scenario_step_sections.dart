import 'package:aves/model/presentation/base_bridge_row.dart';
import 'package:aves/model/scenario/enum/scenario_item.dart';
import 'package:aves/model/scenario/scenario_step.dart';
import 'package:aves/widgets/common/action_mixins/feedback.dart';
import 'package:aves/widgets/common/extensions/build_context.dart';
import 'package:aves/widgets/settings/common/item_tiles.dart';
import 'package:aves/widgets/settings/presentation/common/section.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';

class ScenarioStepLoadTypeSwitchTile extends ItemSettingsTile<ScenarioStepRow> with FeedbackMixin {
  @override
  String title(BuildContext context) => context.l10n.settingsScenarioLoadTypeMultiSelectionTitle;

  ScenarioStepLoadTypeSwitchTile({required super.item});

  @override
  Widget build(BuildContext context) => ItemSettingsSelectionListTile<ScenarioSteps, ScenarioStepLoadType>(
        values: ScenarioStepLoadType.values,
        getName: (context, v) => v.getName(context),
        selector: (context, s) => s.bridgeAll.firstWhereOrNull((e) => e.id == item.id)?.loadType ?? item.loadType,
        onSelection: (v) async {
          debugPrint('$runtimeType ScenarioStepLoadTypeSwitchTile\n'
              'ItemSettingsSelectionListTile onSelection v :$item \n');

          final curStep = scenarioSteps.bridgeAll.firstWhereOrNull((e) => e.id == item.id) ?? item;
          final setStep = curStep.copyWith(loadType: v);
          await scenarioSteps.setRows({setStep}, type: PresentationRowType.bridgeAll);
        },
        tileTitle: title(context),
        dialogTitle: context.l10n.settingsTileScenarioLoadType,
      );
}
