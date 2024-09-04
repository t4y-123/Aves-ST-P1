import 'package:aves/model/scenario/scenario.dart';
import 'package:aves/model/scenario/scenario_step.dart';
import 'package:aves/model/settings/settings.dart';
import 'package:aves/widgets/common/action_mixins/feedback.dart';
import 'package:aves/widgets/common/basic/scaffold.dart';
import 'package:aves/widgets/common/extensions/build_context.dart';
import 'package:aves/widgets/settings/presentation/common/tab_fixed.dart';
import 'package:aves/widgets/settings/presentation/scenario/action/scenario_steps_actions.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SingleScenarioStepsEditSettingPage extends StatefulWidget {
  static const routeName = '/settings/presentation/scenario_edit_setting/steps_edit_setting';
  final ScenarioRow item;
  const SingleScenarioStepsEditSettingPage({super.key, required this.item});

  @override
  State<SingleScenarioStepsEditSettingPage> createState() => _SingleScenarioStepsEditSettingPageState();
}

class _SingleScenarioStepsEditSettingPageState extends State<SingleScenarioStepsEditSettingPage> with FeedbackMixin {
  late SingleScenarioStepsActions _singleScenarioStepsActions;

  ScenarioRow get _item => widget.item;
  @override
  void initState() {
    super.initState();

    // t4y: not need to sync it this page as synced pre.
    // scenarioSteps.syncRowsToBridge();
    _singleScenarioStepsActions = SingleScenarioStepsActions(
      context: context,
      setState: setState,
      item: _item,
    );
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
        length: 1,
        child: AvesScaffold(
          appBar: AppBar(
            automaticallyImplyLeading: !settings.useTvLayout,
            title: Text(l10n.settingsFgwEditSettingsTitle),
            bottom: TabBar(
              tabs: [
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
                      Selector<ScenarioSteps, List<ScenarioStepRow?>>(
                        selector: (_, provider) =>
                            provider.bridgeAll.where((e) => e.scenarioId == _item.id).toList().sorted(),
                        builder: (context, allItems, _) {
                          return MultiEditBridgeListTab<ScenarioStepRow?>(
                            items: allItems,
                            activeItems: allItems.where((v) => v?.isActive ?? false).toSet(),
                            title: (item) => Text(item?.labelName ?? 'Empty'),
                            applyAction: _singleScenarioStepsActions.applyChanges,
                            resetAction: _singleScenarioStepsActions.resetChanges,
                            editAction: _singleScenarioStepsActions.opItem,
                            addItemAction: _singleScenarioStepsActions.opItem,
                            activeChangeAction: _singleScenarioStepsActions.activeItem,
                            bannerString: l10n.settingsMultiTabEditPageBanner,
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
