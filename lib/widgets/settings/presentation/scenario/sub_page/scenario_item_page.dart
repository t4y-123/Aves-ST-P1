import 'package:aves/model/scenario/scenario.dart';
import 'package:aves/model/scenario/scenario_step.dart';
import 'package:aves/widgets/settings/presentation/common/item_page.dart';
import 'package:aves/widgets/settings/presentation/common/section.dart';
import 'package:aves/widgets/settings/presentation/scenario/sections/scenario_sections.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ScenarioItemPage extends StatelessWidget {
  static const routeName = '/settings/presentation/scenario_edit_setting/scenario_item_page';

  final ScenarioRow item;

  const ScenarioItemPage({
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
          return PresentRowItemPage<ScenarioRow>(
            item: item,
            buildTiles: (item) {
              return [
                PresentInfoTile<ScenarioRow, Scenario>(item: item, items: scenarios),
                PresentLabelNameTile<ScenarioRow, Scenario>(item: item, items: scenarios),
                // PresentColorPickTile<ScenarioRow, Scenario>(item: item, items: scenarios),
                ScenarioCopyStepsFromExistListTile(item: item),
                ScenarioLoadTypeSwitchTile(item: item),
                ...context
                    .watch<ScenarioSteps>()
                    .bridgeAll
                    .where((e) => e.scenarioId == item.id)
                    .map((e) => ScenarioStepItemPageTile(item: e))
                    .toList(),
                ScenarioEditStepTile(item: item),
                PresentActiveListTile<ScenarioRow, Scenario>(item: item, items: scenarios),
              ];
            },
          );
        },
      ),
    );
  }
}
