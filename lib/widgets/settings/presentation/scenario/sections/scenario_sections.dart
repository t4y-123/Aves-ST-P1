import 'package:aves/model/presentation/base_bridge_row.dart';
import 'package:aves/model/scenario/enum/scenario_item.dart';
import 'package:aves/model/scenario/scenario.dart';
import 'package:aves/model/scenario/scenario_step.dart';
import 'package:aves/widgets/common/action_mixins/feedback.dart';
import 'package:aves/widgets/common/extensions/build_context.dart';
import 'package:aves/widgets/settings/common/item_tiles.dart';
import 'package:aves/widgets/settings/presentation/common/section.dart';
import 'package:aves/widgets/settings/presentation/scenario/sub_page/scenario_step_edit_page.dart';
import 'package:aves/widgets/settings/presentation/scenario/sub_page/scenario_step_item_page.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';

class ScenarioCopyStepsFromExistListTile extends ItemSettingsTile<ScenarioRow> with FeedbackMixin {
  @override
  String title(BuildContext context) => context.l10n.settingsCopyScenarioStepFromExist;

  ScenarioCopyStepsFromExistListTile({required super.item});

  @override
  Widget build(BuildContext context) => ItemSettingsSelectionListTile<Scenario, ScenarioRow>(
        values: scenarios.bridgeAll.toList(),
        getName: (context, v) => v.labelName,
        selector: (context, s) => s.bridgeAll.firstWhereOrNull((e) => e.id == item.id) ?? item,
        onSelection: (v) async {
          debugPrint('$runtimeType GuardLevelSelectButtonListTile\n' 'row $item \n' 'to value $v\n');

          // get src cope item value of select.
          final fromItems = scenarioSteps.bridgeAll.where((e) => e.scenarioId == v.id);

          if (fromItems.isNotEmpty) {
            debugPrint('$runtimeType  le\n fromItems $fromItems \n'
                'all ${scenarioSteps.all}\n bridgeAll: ${scenarioSteps.bridgeAll}\n');

            // copy every srcRow value to curRow diff in key: updateType-widgetId,
            for (final fromRow in fromItems) {
              //get curRow
              final curRow = scenarioSteps.bridgeAll
                  .firstWhereOrNull((e) => e.scenarioId == item.id && e.stepNum == fromRow.stepNum);
              final ScenarioStepRow newRow;
              if (curRow != null) {
                newRow = fromRow.copyWith(
                    id: curRow.id,
                    scenarioId: item.id,
                    orderNum: curRow.orderNum,
                    stepNum: curRow.stepNum,
                    labelName: curRow.labelName);
              } else {
                final tmpRow = scenarioSteps.newRow(
                    existMaxOrderNumOffset: 1,
                    scenarioId: item.id,
                    existMaxStepNumOffset: 1,
                    type: PresentationRowType.bridgeAll);
                newRow = fromRow.copyWith(
                    id: tmpRow.id,
                    scenarioId: item.id,
                    orderNum: tmpRow.orderNum,
                    stepNum: tmpRow.stepNum,
                    labelName: tmpRow.labelName);
              }
              debugPrint('$runtimeType  ScenarioCopyStepsFromExistListTile\n curRow $curRow \n'
                  'newRow $newRow\n fromRow: $fromRow\n');
              await scenarioSteps.setRows({newRow}, type: PresentationRowType.bridgeAll);
            }
            showFeedback(context, FeedbackType.info, context.l10n.applyCompletedFeedback);
          } else {
            showFeedback(context, FeedbackType.warn, context.l10n.genericFailureFeedback);
          }
        },
        tileTitle: title(context),
        dialogTitle: context.l10n.settingsCopyScenarioStepFromExist,
        showSubTitle: false,
      );
}

class ScenarioStepItemPageTile extends ItemSettingsTile<ScenarioStepRow> {
  ScenarioStepItemPageTile({required super.item});

  @override
  String title(BuildContext context) {
    final curRow = scenarioSteps.bridgeAll.firstWhereOrNull((e) => e.id == item.id);
    return curRow != null ? '${context.l10n.settingsGuardLevelScheduleSubPagePrefix}: ${curRow.stepNum}' : 'null';
  }

  @override
  Widget build(BuildContext context) => ItemSettingsSubPageTile<ScenarioSteps>(
        title: title(context),
        subtitleSelector: (context, s) {
          final subItem = scenarioSteps.bridgeAll.firstWhereOrNull((e) => e.id == item.id);
          final titlePost = subItem != null ? PresentRow.formatItemMap(subItem.toMap()) : 'null';
          return titlePost.toString();
        },
        routeName: ScenarioStepItemPage.routeName,
        builder: (context) => ScenarioStepItemPage(
          item: item,
        ),
      );
}

class ScenarioLoadTypeSwitchTile extends ItemSettingsTile with FeedbackMixin {
  @override
  String title(BuildContext context) => context.l10n.settingsScenarioLoadTypeSelectionTile;

  ScenarioLoadTypeSwitchTile({required super.item});

  @override
  Widget build(BuildContext context) => ItemSettingsSelectionListTile<Scenario, ScenarioLoadType>(
        values: ScenarioLoadType.values,
        getName: (context, v) => v.getName(context),
        selector: (context, s) => s.bridgeAll.firstWhereOrNull((e) => e.id == item.id)?.loadType ?? item.loadType,
        onSelection: (v) async {
          debugPrint('$runtimeType ScenarioLoadTypeSwitchTile\n'
              'ScenarioLoadTypeSwitchTile onSelection v :$item \n');
          final curStep = scenarios.bridgeAll.firstWhereOrNull((e) => e.id == item.id) ?? item;
          final setStep = curStep.copyWith(loadType: v);
          await scenarios.setRows({setStep}, type: PresentationRowType.bridgeAll);
        },
        tileTitle: title(context),
        dialogTitle: context.l10n.settingsScenarioLoadTypeSelectionTile,
      );
}

class ScenarioEditStepTile<ScenarioRow> extends ItemSettingsTile {
  @override
  String title(BuildContext context) => context.l10n.applyTooltip;

  ScenarioEditStepTile({
    required super.item,
  });

  @override
  Widget build(BuildContext context) => ListTile(
        title: null,
        trailing: ElevatedButton(
          onPressed: () async {
            final tileItem = scenarios.bridgeAll.firstWhereOrNull((e) => e.id == item.id);
            if (tileItem != null) {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SingleScenarioStepsEditSettingPage(
                    item: tileItem,
                  ),
                ),
              );
            }
          },
          child: Text(context.l10n.settingsScenarioEditSteps),
        ),
      );
}
