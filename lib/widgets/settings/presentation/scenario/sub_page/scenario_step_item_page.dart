import 'package:aves/model/scenario/scenario.dart';
import 'package:aves/model/scenario/scenario_step.dart';
import 'package:aves/widgets/settings/presentation/common/item_page.dart';
import 'package:aves/widgets/settings/presentation/common/section.dart';
import 'package:aves/widgets/settings/presentation/scenario/sections/scenario_step_sections.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ScenarioStepItemPage extends StatelessWidget {
  static const routeName = '/settings/presentation/scenario/step_item_page';

  final ScenarioStepRow item;

  const ScenarioStepItemPage({
    super.key,
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<Scenario>.value(value: scenarios),
        ChangeNotifierProvider<ScenarioSteps>.value(value: scenarioSteps),
      ],
      child: Builder(
        builder: (context) {
          return PresentRowItemPage<ScenarioStepRow>(
            item: item,
            buildTiles: (item) {
              return [
                PresentInfoTile<ScenarioStepRow, ScenarioSteps>(item: item, items: scenarioSteps),
                PresentLabelNameTile<ScenarioStepRow, ScenarioSteps>(item: item, items: scenarioSteps),
                ScenarioStepLoadTypeSwitchTile(item: item),
                PresentCollectionFiltersTile<ScenarioStepRow, ScenarioSteps>(item: item, items: scenarioSteps),
                PresentActiveListTile<ScenarioStepRow, ScenarioSteps>(item: item, items: scenarioSteps),
              ];
            },
          );
        },
      ),
    );
  }
}
