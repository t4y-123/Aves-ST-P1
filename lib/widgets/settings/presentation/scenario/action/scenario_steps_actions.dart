import 'package:aves/model/scenario/scenario.dart';
import 'package:aves/model/scenario/scenario_step.dart';
import 'package:aves/widgets/common/extensions/build_context.dart';
import 'package:aves/widgets/settings/presentation/scenario/sub_page/scenario_step_sub_page.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';

import '../../../../common/action_mixins/feedback.dart';

class ScenarioStepsConfigActions with FeedbackMixin {
  final BuildContext context;
  final Function setState;

  ScenarioStepsConfigActions({
    required this.context,
    required this.setState,
  });

  // ScenarioStepsConfig
  void applyAllScenarioStepsReorder(
      BuildContext context, List<ScenarioStepRow?> allItems, Set<ScenarioStepRow?> activeItems) {
    setState(() {
      // First, remove items not exist.

      final currentItems = scenarioSteps.bridgeAll;
      final itemsToRemove = currentItems.where((item) => !allItems.contains(item)).toSet();
      scenarioSteps.removeEntries(itemsToRemove, type: ScenarioStepRowsType.bridgeAll);
      // Group items by scenarioId

      // according to order in allItems, reorder the data .active items first.
      int starOrderNum = 1;
      allItems.where((item) => activeItems.contains(item)).forEach((item) {
        scenarioSteps.set(
          id: item!.id,
          scenarioId: item.scenarioId,
          orderNum: starOrderNum++,
          stepNum: item.stepNum,
          labelName: item.labelName,
          loadType: item.loadType,
          filters: item.filters,
          isActive: true,
          dateMillis: item.dateMillis,
          type: ScenarioStepRowsType.bridgeAll,
        );
      });
      // Process reordered items that are not in active items
      allItems.where((item) => !activeItems.contains(item)).forEach((item) {
        scenarioSteps.set(
          id: item!.id,
          scenarioId: item.scenarioId,
          orderNum: starOrderNum++,
          stepNum: item.stepNum,
          labelName: item.labelName,
          loadType: item.loadType,
          filters: item.filters,
          isActive: false,
          dateMillis: item.dateMillis,
          type: ScenarioStepRowsType.bridgeAll,
        );
      });
      //sync bridgeRows to privacy
      scenarios.syncBridgeToRows();
      scenarioSteps.syncBridgeToRows();
      allItems.sort();
      //
      showFeedback(context, FeedbackType.info, context.l10n.applyCompletedFeedback);
    });
  }

  // ScenarioStepsConfig
  void applyOneScenarioStepsReorder(
      BuildContext context, List<ScenarioStepRow?> allItems, Set<ScenarioStepRow?> activeItems) {
    setState(() {
      // First, remove items not exist.
      if (allItems.isEmpty) return;
      final curScenario = scenarios.bridgeAll.firstWhere((e) => e.id == allItems.first?.scenarioId);
      final currentItems = scenarioSteps.bridgeAll.where((e) => e.scenarioId == curScenario.id);

      final itemsToRemove = currentItems.where((item) => !allItems.contains(item)).toSet();
      // tmp use bridge.
      scenarioSteps.removeEntries(itemsToRemove, type: ScenarioStepRowsType.bridgeAll);
      // Group items by scenarioId

      // according to order in allItems, reorder the data .active items first.
      int starStepNum = 1;
      allItems.where((item) => activeItems.contains(item)).forEach((item) {
        scenarioSteps.set(
          id: item!.id,
          scenarioId: item.scenarioId,
          orderNum: item.orderNum,
          stepNum: starStepNum++,
          labelName: item.labelName,
          loadType: item.loadType,
          filters: item.filters,
          isActive: true,
          dateMillis: item.dateMillis,
          type: ScenarioStepRowsType.bridgeAll,
        );
      });
      // Process reordered items that are not in active items
      allItems.where((item) => !activeItems.contains(item)).forEach((item) {
        scenarioSteps.set(
          id: item!.id,
          scenarioId: item.scenarioId,
          orderNum: item.orderNum,
          stepNum: starStepNum++,
          labelName: item.labelName,
          loadType: item.loadType,
          filters: item.filters,
          isActive: false,
          dateMillis: item.dateMillis,
          type: ScenarioStepRowsType.bridgeAll,
        );
      });
      // not need to sync now.
      // scenarios.syncBridgeToRows();
      // scenarioSteps.syncBridgeToRows();
      allItems.sort();
      //
      showFeedback(context, FeedbackType.info, context.l10n.applyCompletedFeedback);
    });
  }

  Future<void> addScenarioSteps(
      BuildContext context, List<ScenarioStepRow?> allItems, Set<ScenarioStepRow?> activeItems) async {
    if (allItems.isEmpty) return;
    final curScenario = scenarios.bridgeAll.firstWhere((e) => e.id == allItems.first?.scenarioId);
    // add a new item to bridge.
    final newItem = await scenarioSteps.newRow(
      existMaxOrderNumOffset: 1,
      existMaxStepNumOffset: 1,
      scenarioId: curScenario!.id,
      type: ScenarioStepRowsType.bridgeAll,
    );
    debugPrint('$runtimeType addScenarioSteps newItem $newItem\n');
    await scenarioSteps.add({newItem}, type: ScenarioStepRowsType.bridgeAll);

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ScenarioStepSubPage(
          item: curScenario,
          scenarioStep: newItem,
        ),
      ),
    ).then((returnItem) {
      if (returnItem != null) {
        //final newRow = newItem as ScenarioBaseRow;
        setState(() {
          // not sync until tap apply button.
          // scenarios.syncBridgeToRows();
          final updateItem = scenarioSteps.bridgeAll.firstWhere((e) => e.id == newItem.id);
          allItems.add(updateItem);
          if (updateItem.isActive) activeItems.add(updateItem);
          allItems.sort();
        });
      } else {
        scenarioSteps.removeEntries({newItem}, type: ScenarioStepRowsType.bridgeAll);
      }
    });
  }

  void editScenarioSteps(
      BuildContext context, ScenarioStepRow? item, List<ScenarioStepRow?> allItems, Set<ScenarioStepRow?> activeItems) {
    //t4y: for the all items in Config page will not be the latest data.
    final ScenarioStepRow currentItem = scenarioSteps.bridgeAll.firstWhere((i) => i.id == item!.id);
    final curScenario = scenarios.bridgeAll.firstWhereOrNull((e) => e.id == currentItem.scenarioId);
    if (curScenario != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ScenarioStepSubPage(
            item: curScenario,
            scenarioStep: currentItem,
          ),
        ),
      ).then((updatedItem) {
        final ScenarioStepRow currentItem = scenarioSteps.bridgeAll.firstWhere((i) => i.id == item!.id);
        updatedItem = currentItem;
        if (updatedItem != null) {
          setState(() {
            final index = allItems.indexWhere((i) => i?.id == updatedItem.id);
            if (index != -1) {
              allItems[index] = updatedItem;
            } else {
              allItems.add(updatedItem);
            }
            if (updatedItem.isActive) {
              //final row = updatedItem as ScenarioStepRow;
              activeItems.add(updatedItem);
            } else {
              activeItems.remove(updatedItem);
            }
          });
        }
      });
    }
  }
}
