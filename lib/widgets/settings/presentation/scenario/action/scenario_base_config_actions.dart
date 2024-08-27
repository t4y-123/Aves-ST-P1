import 'package:aves/model/scenario/scenario.dart';
import 'package:aves/model/scenario/scenario_step.dart';
import 'package:aves/model/scenario/scenarios_helper.dart';
import 'package:aves/model/settings/settings.dart';
import 'package:aves/widgets/common/action_mixins/feedback.dart';
import 'package:aves/widgets/common/extensions/build_context.dart';
import 'package:aves/widgets/settings/presentation/scenario/sub_page/scenario_base_setting_page.dart';
import 'package:flutter/material.dart';

class ScenarioBaseConfigActions with FeedbackMixin {
  final BuildContext context;
  final Function setState;

  ScenarioBaseConfigActions({
    required this.context,
    required this.setState,
  });

  Color privacyItemColor(ScenarioRow? item) {
    return item?.color ?? Theme.of(context).primaryColor;
  }

  // ScenarioBaseConfig
  void applyScenarioBaseReorder(BuildContext context, List<ScenarioRow?> allItems, Set<ScenarioRow?> activeItems) {
    setState(() {
      // First, remove items not exist.      // remove relate schedules too.
      final currentItems = scenarios.bridgeAll;
      final itemsToRemove = currentItems.where((item) => !allItems.contains(item)).toSet();
      // remove scenarios
      final removeBaseIds = itemsToRemove.map((e) => e.id).toSet();
      scenarios.removeRows(itemsToRemove, type: ScenarioRowsType.bridgeAll);
      scenariosHelper.removeScenarioPinnedFilters(itemsToRemove);
      // remove scenario steps
      final removeSteps = scenarioSteps.bridgeAll.where((e) => removeBaseIds.contains(e.scenarioId)).toSet();
      scenarioSteps.removeEntries(removeSteps, type: ScenarioStepRowsType.bridgeAll);

      // according to order in allItems, reorder the data .active items first.
      int starOrderNum = 1;
      allItems.where((item) => activeItems.contains(item)).forEach((item) {
        scenarios.set(
          id: item!.id,
          orderNum: starOrderNum++,
          labelName: item.labelName,
          loadType: item.loadType,
          color: item.color!,
          isActive: true,
          dateMillis: item.dateMillis,
          type: ScenarioRowsType.bridgeAll,
        );
      });
      // Process reordered items that are not in active items
      allItems.where((item) => !activeItems.contains(item)).forEach((item) {
        scenarios.set(
          id: item!.id,
          orderNum: starOrderNum++,
          labelName: item.labelName,
          loadType: item.loadType,
          color: item.color!,
          isActive: false,
          dateMillis: item.dateMillis,
          type: ScenarioRowsType.bridgeAll,
        );
      });
      //sync bridgeRows to privacy
      scenarios.syncBridgeToRows();
      scenarioSteps.syncBridgeToRows();
      allItems.sort();
      //
      if (settings.scenarioPinnedExcludeFilters.isEmpty) {
        scenariosHelper.setExcludeDefaultFirst();
      }
      showFeedback(context, FeedbackType.info, context.l10n.applyCompletedFeedback);
    });
  }

  // when add a new item, temp add to bridge. in add process,
  // it should not effect the real value, but a bridge value.
  // the bridge value will be sync to real value after tap the apply button call above apply action.
  Future<void> addScenarioBase(BuildContext context, List<ScenarioRow?> allItems, Set<ScenarioRow?> activeItems) async {
    // add a new item to bridge.
    final newItem = await scenarios.newRow(1, type: ScenarioRowsType.bridgeAll);
    debugPrint('addScenarioBase newItem $newItem\n');
    await scenarios.add({newItem}, type: ScenarioRowsType.bridgeAll);

    // add a new group of schedule to schedules bridge.
    final bridgeSubItems =
        await scenariosHelper.newScenarioStepsGroup(newItem, rowsType: ScenarioStepRowsType.bridgeAll);
    await scenarioSteps.add(bridgeSubItems.toSet(), type: ScenarioStepRowsType.bridgeAll);

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ScenarioBaseSettingPage(
          item: newItem,
          subItems: bridgeSubItems.toSet(),
        ),
      ),
    ).then((newItem) {
      if (newItem != null) {
        //final newRow = newItem as ScenarioBaseRow;
        setState(() {
          // not sync until tap apply button.
          // scenarios.syncBridgeToRows();
          final updateItem = scenarios.bridgeAll.firstWhere((e) => e.id == newItem.id);
          allItems.add(updateItem);
          if (updateItem.isActive) activeItems.add(updateItem);
          allItems.sort();
        });
      } else {
        scenarios.removeRows({newItem}, type: ScenarioRowsType.bridgeAll);
        scenarioSteps.removeEntries(bridgeSubItems.toSet(), type: ScenarioStepRowsType.bridgeAll);
      }
    });
  }

  Future<void> editScenarioBase(
      BuildContext context, ScenarioRow? item, List<ScenarioRow?> allItems, Set<ScenarioRow?> activeItems) async {
    //t4y: for the all items in Config page will not be the latest data.
    final ScenarioRow curItem = scenarios.bridgeAll.firstWhere((i) => i.id == item!.id);
    // add a new group of schedule to schedules bridge.
    final bridgeSubItems = scenarioSteps.bridgeAll.where((e) => e.scenarioId == curItem.id);
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ScenarioBaseSettingPage(
          item: curItem,
          subItems: bridgeSubItems.toSet(),
        ),
      ),
    ).then((updatedItem) async {
      if (updatedItem != null) {
        setState(() {
          final index = allItems.indexWhere((i) => i?.id == updatedItem.id);
          if (index != -1) {
            allItems[index] = updatedItem;
          } else {
            allItems.add(updatedItem);
          }
          if (updatedItem.isActive) {
            activeItems.add(updatedItem);
          } else {
            activeItems.remove(updatedItem);
          }
          scenarios.setRows({updatedItem}, type: ScenarioRowsType.bridgeAll);
        });
      }
    });
  }
}
