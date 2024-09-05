import 'package:aves/model/presentation/base_bridge_row.dart';
import 'package:aves/model/scenario/scenario.dart';
import 'package:aves/model/scenario/scenario_step.dart';
import 'package:aves/widgets/common/action_mixins/feedback.dart';
import 'package:aves/widgets/common/extensions/build_context.dart';
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
  void applyChanges(BuildContext context, List<ScenarioStepRow?> allItems, Set<ScenarioStepRow?> activeItems) {
    setState(() {
      // First, remove items not existing.
      final currentItems = presentationRows.bridgeAll.where((e) => e.scenarioId == item.id);
      final itemsToRemove = currentItems.where((e) => !allItems.contains(e)).toSet();
      presentationRows.removeRows(itemsToRemove, type: PresentationRowType.bridgeAll);

      // Process reordered active items
      int incrementNum = 1;
      allItems.where((e) => activeItems.contains(e)).forEach((e) {
        final newRow = incrementRowWithActive(incrementNum++, e!, true);
        presentationRows.set(newRow, type: PresentationRowType.bridgeAll);
      });

      // Process reordered inactive items
      allItems.where((e) => !activeItems.contains(e)).forEach((e) {
        final newRow = incrementRowWithActive(incrementNum++, e!, false);
        presentationRows.set(newRow, type: PresentationRowType.bridgeAll);
      });
      // in parent to sync.
      // presentationRows.syncBridgeToRows();
      allItems.sort();
      showFeedback(context, FeedbackType.info, context.l10n.applyCompletedFeedback);
    });
  }

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
