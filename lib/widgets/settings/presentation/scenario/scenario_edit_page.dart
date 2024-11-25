import 'package:aves/model/assign/assign_record.dart';
import 'package:aves/model/fgw/wallpaper_schedule.dart';
import 'package:aves/model/scenario/scenario.dart';
import 'package:aves/model/scenario/scenario_step.dart';
import 'package:aves/model/settings/settings.dart';
import 'package:aves/widgets/common/action_mixins/feedback.dart';
import 'package:aves/widgets/common/basic/scaffold.dart';
import 'package:aves/widgets/common/extensions/build_context.dart';
import 'package:aves/widgets/settings/presentation/common/tab_fixed.dart';
import 'package:aves/widgets/settings/presentation/scenario/action/scenario_actions.dart';
import 'package:aves/widgets/settings/presentation/scenario/action/scenario_steps_actions.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ScenarioEditSettingPage extends StatefulWidget {
  static const routeName = '/settings/presentation/scenario_edit_setting';

  const ScenarioEditSettingPage({super.key});

  @override
  State<ScenarioEditSettingPage> createState() => _ScenarioEditSettingPageState();
}

class _ScenarioEditSettingPageState extends State<ScenarioEditSettingPage> with FeedbackMixin {
  late ScenarioActions _scenarioActions;
  late AllScenarioStepsActions _allScenarioStepsAction;

  @override
  void initState() {
    super.initState();

    // first sync the rows data to the bridge data.
    // then all data shall modify in the bridgeAll data.
    scenarios.syncRowsToBridge();
    fgwSchedules.syncRowsToBridge();
    assignRecords.removeExpiredRecord();
    _scenarioActions = ScenarioActions(context: context, setState: setState);
    _allScenarioStepsAction = AllScenarioStepsActions(context: context, setState: setState);
    // Add listeners to track modifications
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<Scenario>.value(value: scenarios),
        ChangeNotifierProvider<ScenarioSteps>.value(value: scenarioSteps),
      ],
      child: DefaultTabController(
        length: 2,
        child: AvesScaffold(
          appBar: AppBar(
            automaticallyImplyLeading: !settings.useTvLayout,
            title: Text(l10n.settingsScenariosEditConfigPageTile),
            bottom: TabBar(
              tabs: [
                Tab(text: l10n.settingsScenarioTabTypes),
                Tab(text: l10n.settingsScenarioStepsTabTypes),
              ],
            ),
          ),
          body: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: TabBarView(
                    children: [
                      Selector<Scenario, List<ScenarioRow?>>(
                        selector: (_, provider) => provider.bridgeAll.toList().sorted(),
                        builder: (context, allItems, _) {
                          return MultiEditBridgeListTab<ScenarioRow?>(
                            items: allItems,
                            activeItems: allItems.where((v) => v?.isActive ?? false).toSet(),
                            title: (item) => Text(item?.labelName ?? 'Empty'),
                            applyAction: _scenarioActions.applyChanges,
                            resetAction: _scenarioActions.resetChanges,
                            editAction: _scenarioActions.opItem,
                            addItemAction: _scenarioActions.opItem,
                            activeChangeAction: _scenarioActions.activeItem,
                            bannerString: l10n.settingsScenarioEditBanner,
                          );
                        },
                      ),
                      Selector<ScenarioSteps, List<ScenarioStepRow?>>(
                        selector: (_, provider) => provider.bridgeAll.toList().sorted(),
                        builder: (context, allItems, _) {
                          return MultiEditBridgeListTab<ScenarioStepRow?>(
                            items: allItems,
                            activeItems: allItems.where((v) => v?.isActive ?? false).toSet(),
                            title: (item) => Text(item?.labelName ?? 'Empty'),
                            applyAction: _allScenarioStepsAction.applyChanges,
                            editAction: _allScenarioStepsAction.opItem,
                            activeChangeAction: _allScenarioStepsAction.activeItem,
                            bannerString: l10n.settingsScenarioStepsAllBanner,
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
