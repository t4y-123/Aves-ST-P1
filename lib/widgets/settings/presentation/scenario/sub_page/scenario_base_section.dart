import 'package:aves/model/scenario/enum/scenario_item.dart';
import 'package:aves/model/scenario/scenario.dart';
import 'package:aves/model/scenario/scenario_step.dart';
import 'package:aves/model/scenario/scenarios_helper.dart';
import 'package:aves/widgets/common/action_mixins/feedback.dart';
import 'package:aves/widgets/common/basic/list_tiles/color.dart';
import 'package:aves/widgets/common/extensions/build_context.dart';
import 'package:aves/widgets/settings/common/item_tiles.dart';
import 'package:aves/widgets/settings/presentation/scenario/sub_page/scenario_step_sub_page.dart';
import 'package:aves/widgets/settings/settings_definition.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ScenarioPreInfoTitleTile extends SettingsTile {
  @override
  String title(BuildContext context) => '${context.l10n.scenarioNamePrefix}:${item.id}';

  final ScenarioRow item;

  ScenarioPreInfoTitleTile({
    required this.item,
  });

  @override
  Widget build(BuildContext context) => ItemInfoListTile<Scenario>(
        tileTitle: title(context),
        selector: (context, levels) {
          debugPrint('$runtimeType ScenarioLabelNameModifiedTile\n'
              'item: $item \n'
              'rows ${levels.all} \n'
              'bridges ${levels.bridgeAll}\n');
          return ('id:${item.id} date:${DateTime.fromMillisecondsSinceEpoch(item.dateMillis)}');
        },
      );
}

class ScenarioLabelNameModifiedTile extends SettingsTile {
  @override
  String title(BuildContext context) => context.l10n.renameLabelNameTileTitle;
  final ScenarioRow item;

  ScenarioLabelNameModifiedTile({
    required this.item,
  });

  @override
  Widget build(BuildContext context) => ItemSettingsLabelNameListTile<Scenario>(
        tileTitle: title(context),
        selector: (context, levels) {
          debugPrint('$runtimeType ScenarioLabelNameModifiedTile\n'
              'item: $item \n'
              'rows ${levels.all} \n'
              'bridges ${levels.bridgeAll}\n');
          final row = scenarios.bridgeAll.firstWhereOrNull((e) => e.id == item.id);
          if (row != null) {
            return row.labelName;
          } else {
            return 'Error';
          }
        },
        onChanged: (value) {
          debugPrint('$runtimeType ScenarioSectionBaseSection\n'
              'row.labelName ${item.labelName} \n'
              'to value $value\n');
          if (scenarios.bridgeAll.map((e) => e.id).contains(item.id)) {
            scenarios.setExistRows(
                rows: {item}, newValues: {ScenarioRow.propLabelName: value}, type: ScenarioRowsType.bridgeAll);
          }
          ;
        },
      );
}

class ScenarioColorPickerTile extends SettingsTile {
  @override
  String title(BuildContext context) => context.l10n.settingsScenarioColor;
  final ScenarioRow item;

  ScenarioColorPickerTile({
    required this.item,
  });

  @override
  Widget build(BuildContext context) => Selector<Scenario, Color>(
        selector: (context, s) => s.bridgeAll.firstWhereOrNull((e) => e.id == item.id)?.color ?? Colors.transparent,
        builder: (context, current, child) => ListTile(
          title: Text(title(context)),
          trailing: GestureDetector(
            onTap: () {
              _pickColor(context);
            },
            child: Container(
              width: 24,
              height: 24,
              color: current,
            ),
          ),
        ),
      );

  Future<void> _pickColor(BuildContext context) async {
    final color = await showDialog<Color>(
      context: context,
      builder: (context) => ColorPickerDialog(
        initialValue: item.color ?? scenarios.getRandomColor(),
      ),
      routeSettings: const RouteSettings(name: ColorPickerDialog.routeName),
    );
    if (color != null) {
      if (scenarios.bridgeAll.map((e) => e.id).contains(item.id)) {
        await scenarios
            .setExistRows(rows: {item}, newValues: {ScenarioRow.propColor: color}, type: ScenarioRowsType.bridgeAll);
      }
      ;
    }
  }
}

class ScenarioCopyStepsFromExistListTile extends SettingsTile with FeedbackMixin {
  @override
  String title(BuildContext context) => context.l10n.settingsCopyScenarioStepFromExist;
  final ScenarioRow item;

  ScenarioCopyStepsFromExistListTile({
    required this.item,
  });

  @override
  Widget build(BuildContext context) => ItemSettingsSelectionListTile<Scenario, ScenarioRow>(
        values: scenarios.bridgeAll.toList(),
        getName: (context, v) => v.labelName,
        selector: (context, s) => s.bridgeAll.firstWhereOrNull((e) => e.id == item.id) ?? item,
        onSelection: (v) async {
          debugPrint('$runtimeType ScenarioSelectButtonListTile\n'
              'row ${item} \n'
              'to value $v\n');
          final copiedItems =
              await scenariosHelper.getStepsOfScenario(curScenario: v, rowsType: ScenarioStepRowsType.bridgeAll);
          debugPrint('$runtimeType ScenarioSelectButtonListTile\n'
              'copiedItems $copiedItems \n'
              'all ${scenarioSteps.all}\n'
              'bridgeAll: ${scenarioSteps.bridgeAll}\n');
          // remove all steps first.
          final curLevelBridgeRow = scenarioSteps.bridgeAll.where((e) => e.scenarioId == item.id).toSet();
          await scenarioSteps.removeEntries(curLevelBridgeRow);
          for (final copiedRow in copiedItems) {
            final newRow = scenarioSteps.newRow(
              scenarioId: item.id,
              existMaxOrderNumOffset: copiedRow.stepNum,
              existMaxStepNumOffset: copiedRow.stepNum,
              labelName: copiedRow.labelName,
              loadType: copiedRow.loadType,
              filters: copiedRow.filters,
              dateMillis: DateTime.now().millisecondsSinceEpoch,
              isActive: copiedRow.isActive,
            );
            debugPrint('$runtimeType curLevelBridgeRow\n'
                'new row:\n  ${copiedRow} \n'
                'after set:\n  ${curLevelBridgeRow} \n');
          }
          showFeedback(context, FeedbackType.info, context.l10n.applyCompletedFeedback);
          // t4y:TODO：　after copy, reset all related items.
        },
        tileTitle: title(context),
        dialogTitle: context.l10n.settingsCopyScenarioStepFromExist,
        showSubTitle: false,
      );
}

class ScenarioLoadTypeSwitchTile extends SettingsTile with FeedbackMixin {
  @override
  String title(BuildContext context) => context.l10n.settingsScenarioLoadTypeSelectionTile;
  final ScenarioRow item;

  ScenarioLoadTypeSwitchTile({
    required this.item,
  });

  @override
  Widget build(BuildContext context) => ItemSettingsSelectionListTile<Scenario, ScenarioLoadType>(
        values: ScenarioLoadType.values,
        getName: (context, v) => v.getName(context),
        selector: (context, s) => s.bridgeAll.firstWhereOrNull((e) => e.id == item.id)?.loadType ?? item.loadType,
        onSelection: (v) async {
          debugPrint('$runtimeType ScenarioLoadTypeSwitchTile\n'
              'ScenarioLoadTypeSwitchTile onSelection v :$item \n');
          final curItems = scenarios.bridgeAll.firstWhereOrNull((e) => e.id == item.id) ?? item;
          await scenarios.setExistRows(
              rows: {curItems}, newValues: {ScenarioRow.propLoadType: v}, type: ScenarioRowsType.bridgeAll);
          // t4y:TODO：　after copy, reset all related items.
        },
        tileTitle: title(context),
        dialogTitle: context.l10n.settingsScenarioLoadTypeSelectionTile,
      );
}

class ScenarioActiveListTile extends SettingsTile {
  @override
  String title(BuildContext context) => context.l10n.settingsActiveTitle;

  final ScenarioRow item;

  ScenarioActiveListTile({
    required this.item,
  });

  @override
  Widget build(BuildContext context) => ItemSettingsSwitchListTile<Scenario>(
        selector: (context, s) => s.bridgeAll.firstWhereOrNull((e) => e.id == item.id)?.isActive ?? item.isActive,
        onChanged: (v) async {
          final curLevel = scenarios.bridgeAll.firstWhereOrNull((e) => e.id == item.id) ?? item;
          await scenarios.setExistRows(
            rows: {curLevel},
            newValues: {
              ScenarioRow.propIsActive: v,
            },
            type: ScenarioRowsType.bridgeAll,
          );
        },
        title: title(context),
      );
}

class ScenarioStepSubPageTile extends SettingsTile {
  @override
  String title(BuildContext context) {
    return '${context.l10n.settingsScenarioStepsSubPagePrefix} ${subItem.stepNum}: ';
  }

  final ScenarioRow item;
  final ScenarioStepRow subItem;

  ScenarioStepSubPageTile({
    required this.item,
    required this.subItem,
  });

  @override
  Widget build(BuildContext context) => ItemSettingsSubPageTile<ScenarioSteps>(
        title: title(context),
        subtitleSelector: (context, s) {
          final titlePost = scenarioSteps.bridgeAll.firstWhereOrNull((e) => e.id == subItem.id);
          return titlePost != null ? titlePost.toMap().toString() : 'null';
        },
        routeName: ScenarioStepSubPage.routeName,
        builder: (context) => ScenarioStepSubPage(
          item: item,
          scenarioStep: subItem,
        ),
      );
}
