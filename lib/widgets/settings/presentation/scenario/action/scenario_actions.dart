import 'package:aves/model/presentation/base_bridge_row.dart';
import 'package:aves/model/scenario/scenario.dart';
import 'package:aves/model/scenario/scenario_step.dart';
import 'package:aves/model/scenario/scenarios_helper.dart';
import 'package:aves/widgets/common/action_mixins/feedback.dart';
import 'package:aves/widgets/common/extensions/build_context.dart';
import 'package:aves/widgets/settings/presentation/common/config_actions.dart';
import 'package:aves/widgets/settings/presentation/scenario/sub_page/scenario_item_page.dart';
import 'package:flutter/material.dart';

class ScenarioActions extends BridgeConfigActions<ScenarioRow> {
  Set<ScenarioStepRow>? relateItems;

  ScenarioActions({
    required super.context,
    required super.setState,
  }) : super(
          presentationRows: scenarios,
        );

  @override
  void applyChanges(BuildContext context, List<ScenarioRow?> allItems, Set<ScenarioRow?> activeItems) {
    // First, remove relate schedules too.
    final currentItems = scenarios.bridgeAll;
    final itemsToRemove = currentItems.where((item) => !allItems.contains(item)).toSet();
    final removeLevelIds = itemsToRemove.map((e) => e.id).toSet();
    scenarios.removeRows(itemsToRemove, type: PresentationRowType.bridgeAll);
    //
    final removedSchedules = scenarioSteps.bridgeAll.where((e) => removeLevelIds.contains(e.scenarioId)).toSet();
    scenarioSteps.removeRows(removedSchedules, type: PresentationRowType.bridgeAll);
    // then call the super to apply changes to guard level
    super.applyChanges(context, allItems, activeItems);
  }

  @override
  void resetChanges(BuildContext context, List<ScenarioRow?> allItems, Set<ScenarioRow?> activeItems) {
    setState(() {
      // First, reset Rows
      scenarios.syncRowsToBridge();
      scenarioSteps.syncRowsToBridge();
      allItems.sort();
      showFeedback(context, FeedbackType.info, context.l10n.applyCompletedFeedback);
    });
  }

  @override
  ScenarioRow incrementRowWithActive(int incrementNum, ScenarioRow srcItem, bool active) {
    return srcItem.copyWith(orderNum: incrementNum, isActive: active);
  }

  @override
  Widget getItemPage(ScenarioRow item) {
    return ScenarioItemPage(item: item);
  }

  @override
  Future<void> opItem(BuildContext context, [ScenarioRow? item]) async {
    if (item != null) {
      relateItems = scenarioSteps.bridgeAll.where((e) => e.scenarioId == item.id).toSet();
    }
    await super.opItem(context, item);
  }

  @override
  Future<void> removeRelateRow(ScenarioRow item) async {
    if (relateItems != null) {
      await scenarioSteps.removeRows(relateItems!, type: PresentationRowType.bridgeAll);
    }
  }

  @override
  Future<void> resetRelateRow(ScenarioRow item) async {
    if (relateItems != null) {
      await scenarioSteps.setRows(relateItems!, type: PresentationRowType.bridgeAll);
    }
  }

  @override
  Future<ScenarioRow> makeNewRow() async {
    final newRow = await scenarios.newRow(1, type: PresentationRowType.bridgeAll);
    await scenarios.add({newRow}, type: PresentationRowType.bridgeAll);
    final bridgeSteps = scenariosHelper.newScenarioStep(1, newRow.id, 1, null, type: PresentationRowType.bridgeAll);
    await scenarioSteps.add({bridgeSteps}, type: PresentationRowType.bridgeAll);
    return newRow;
  }
}
