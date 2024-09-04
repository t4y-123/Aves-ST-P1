import 'package:aves/model/presentation/base_bridge_row.dart';
import 'package:aves/model/scenario/scenario.dart';
import 'package:aves/model/scenario/scenario_step.dart';
import 'package:aves/widgets/settings/presentation/common/config_actions.dart';
import 'package:aves/widgets/settings/presentation/scenario/sub_page/scenario_step_item_page.dart';
import 'package:flutter/material.dart';

class AllScenarioStepsActions extends BridgeConfigActions<ScenarioStepRow> {
  AllScenarioStepsActions({
    required super.context,
    required super.setState,
  }) : super(
          presentationRows: scenarioSteps,
        );

  @override
  ScenarioStepRow incrementRowWithActive(int incrementNum, ScenarioStepRow srcItem, bool active) {
    return srcItem.copyWith(orderNum: incrementNum, isActive: active);
  }

  @override
  Widget getItemPage(ScenarioStepRow item) {
    return ScenarioStepItemPage(item: item);
  }

  @override
  Future<ScenarioStepRow> makeNewRow() {
    // TODO: implement makeNewRow
    throw UnimplementedError();
  }
}

class SingleScenarioStepsActions extends BridgeConfigActions<ScenarioStepRow> {
  final ScenarioRow item;

  SingleScenarioStepsActions({
    required super.context,
    required super.setState,
    required this.item,
  }) : super(
          presentationRows: scenarioSteps,
        );

  @override
  Widget getItemPage(ScenarioStepRow item) {
    return ScenarioStepItemPage(item: item);
  }

  @override
  ScenarioStepRow incrementRowWithActive(int incrementNum, ScenarioStepRow srcItem, bool active) {
    return srcItem.copyWith(stepNum: incrementNum, isActive: active);
  }

  @override
  Future<ScenarioStepRow> makeNewRow() async {
    final newRow = scenarioSteps.newRow(
        type: PresentationRowType.bridgeAll, existMaxOrderNumOffset: 1, scenarioId: item.id, existMaxStepNumOffset: 1);
    await scenarioSteps.add({newRow}, type: PresentationRowType.bridgeAll);
    return newRow;
  }
}
