import 'package:aves/model/fgw/filters_set.dart';
import 'package:aves/model/filters/mime.dart';
import 'package:aves/model/scenario/enum/scenario_item.dart';
import 'package:aves/model/scenario/scenario.dart';
import 'package:aves/model/scenario/scenario_step.dart';
import 'package:aves/widgets/common/action_mixins/feedback.dart';
import 'package:aves/widgets/common/extensions/build_context.dart';
import 'package:aves/widgets/common/identity/buttons/outlined_button.dart';
import 'package:aves/widgets/settings/common/collection_tile.dart';
import 'package:aves/widgets/settings/common/item_tiles.dart';
import 'package:aves/widgets/settings/settings_definition.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class ScenarioStepSubPage extends StatefulWidget {
  static const routeName = '/settings/presentation/scenario/step_sub_page';
  final ScenarioRow item;
  final ScenarioStepRow scenarioStep;

  const ScenarioStepSubPage({
    super.key,
    required this.item,
    required this.scenarioStep,
  });

  @override
  State<ScenarioStepSubPage> createState() => _ScenarioStepSubPageState();
}

class _ScenarioStepSubPageState extends State<ScenarioStepSubPage> with FeedbackMixin {
  @override
  void initState() {
    super.initState();
    debugPrint('_ScenarioStepSubPageState in context: $context');

    // If _currentUpdateTypes is empty, do nothing.
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
        appBar: AppBar(
          title: Text(l10n.settingsScenarioStepsTabTypes),
        ),
        body: MultiProvider(
          providers: [
            ChangeNotifierProvider<Scenario>.value(value: scenarios),
            ChangeNotifierProvider<ScenarioSteps>.value(value: scenarioSteps),
            ChangeNotifierProvider<FiltersSet>.value(value: filtersSets),
          ],
          child: SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(10.0),
              children: [
                Text('ID: ${widget.scenarioStep.id} '),
                Text('${context.l10n.settingsTileScenarioScenarioId}: ${widget.scenarioStep.scenarioId} '),
                Text('${context.l10n.settingsTileScenarioStepNum}: ${widget.scenarioStep.stepNum} '),
                Text('${context.l10n.settingsTileScenarioOrderNum}: ${widget.scenarioStep.orderNum} '),
                Text(
                    '${context.l10n.settingsTileScenarioDateMillis}: ${DateFormat('yyyy-MM-dd HH:mm:ss.SSS').format(DateTime.fromMillisecondsSinceEpoch(widget.scenarioStep.dateMillis))} '),
                const Divider(height: 10),
                ScheduleLabelNameModifiedTile(scenarioStep: widget.scenarioStep).build(context),
                const Divider(
                  height: 10,
                ),
                ScenarioStepLoadTypeSwitchTile(scenarioStep: widget.scenarioStep).build(context),
                const Divider(height: 10),
                buildFilterSetTile(),
                const Divider(
                  height: 10,
                ),
                ItemSettingsSwitchListTile<ScenarioSteps>(
                  selector: (context, s) =>
                      (s.bridgeAll.firstWhereOrNull((e) => e.id == widget.scenarioStep.id) ?? widget.scenarioStep)
                          .isActive,
                  onChanged: (v) async {
                    final curSchedule =
                        scenarioSteps.bridgeAll.firstWhereOrNull((e) => e.id == widget.scenarioStep.id) ??
                            widget.scenarioStep;
                    await scenarioSteps.setExistRows({curSchedule}, {ScenarioStepRow.propIsActive: v},
                        type: ScenarioStepRowsType.bridgeAll);
                  },
                  title: l10n.settingsScheduleIsActiveTitle,
                ),
                const Divider(
                  height: 10,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    AvesOutlinedButton(
                      onPressed: () {
                        _applyChanges(context, widget.scenarioStep);
                      },
                      label: context.l10n.settingsForegroundWallpaperConfigApplyChanges,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ));
  }

  Selector<ScenarioSteps, ScenarioStepRow?> buildFilterSetTile() {
    return Selector<ScenarioSteps, ScenarioStepRow?>(
      selector: (context, s) {
        final curStep = s.bridgeAll.firstWhereOrNull((e) => e.id == widget.scenarioStep.id);
        return curStep;
      },
      builder: (context, current, child) {
        return SettingsCollectionTile(
            filters: current?.filters ?? {MimeFilter.image},
            onSelection: (v) {
              setState(() async {
                final curStep = scenarioSteps.bridgeAll.firstWhere((e) => e.id == widget.scenarioStep.id);
                await scenarioSteps
                    .setExistRows({curStep}, {ScenarioStepRow.propFilters: v}, type: ScenarioStepRowsType.bridgeAll);
              });
            });
      },
    );
  }

  void _applyChanges(BuildContext context, ScenarioStepRow item) {
    final updateItem = scenarioSteps.bridgeAll.firstWhereOrNull((e) => e.id == item.id);
    Navigator.pop(context, updateItem);
  }
}

class ScheduleLabelNameModifiedTile extends SettingsTile {
  @override
  String title(BuildContext context) => context.l10n.renameLabelNameTileTitle;
  final ScenarioStepRow scenarioStep;

  ScheduleLabelNameModifiedTile({
    required this.scenarioStep,
  });

  @override
  Widget build(BuildContext context) => ItemSettingsLabelNameListTile<ScenarioSteps>(
        tileTitle: title(context),
        selector: (context, steps) {
          // debugPrint('$runtimeType ScenarioStepLabelNameModifiedTile\n'
          //     'item: $scenarioStep \n'
          //     'rows ${steps.all} \n'
          //     'bridges ${steps.bridgeAll}\n');
          final row = steps.bridgeAll.firstWhereOrNull((e) => e.id == scenarioStep.id);
          if (row != null) {
            return row.labelName;
          } else {
            return 'Error';
          }
        },
        onChanged: (value) {
          // if(scenarioSteps.bridgeAll.map((e)=> e.id).contains(scenarioStep.id)){
          scenarioSteps.setExistRows({scenarioStep}, {ScenarioStepRow.propLabelName: value},
              type: ScenarioStepRowsType.bridgeAll);
          // debugPrint('$runtimeType ScenarioStepSectionBaseSection\n'
          //     'row.labelName ${scenarioStep.labelName} \n'
          //     'to value $value\n');
          // };
        },
      );
}

class ScenarioStepLoadTypeSwitchTile extends SettingsTile with FeedbackMixin {
  @override
  String title(BuildContext context) => context.l10n.settingsTileScenarioLoadType;
  final ScenarioStepRow scenarioStep;

  ScenarioStepLoadTypeSwitchTile({
    required this.scenarioStep,
  });

  @override
  Widget build(BuildContext context) => ItemSettingsSelectionListTile<ScenarioSteps, ScenarioStepLoadType>(
        values: ScenarioStepLoadType.values,
        getName: (context, v) => v.getName(context),
        selector: (context, s) =>
            s.bridgeAll.firstWhereOrNull((e) => e.id == scenarioStep.id)?.loadType ?? scenarioStep.loadType,
        onSelection: (v) async {
          debugPrint('$runtimeType ScenarioStepLoadTypeSwitchTile\n'
              'ItemSettingsSelectionListTile onSelection v :$scenarioStep \n');
          final curSchedule = scenarioSteps.bridgeAll.firstWhereOrNull((e) => e.id == scenarioStep.id) ?? scenarioStep;
          await scenarioSteps
              .setExistRows({curSchedule}, {ScenarioStepRow.propLoadType: v}, type: ScenarioStepRowsType.bridgeAll);
          // t4y:TODO：　after copy, reset all related scenarioSteps.
        },
        tileTitle: title(context),
        dialogTitle: context.l10n.fgwDisplayType,
      );
}
