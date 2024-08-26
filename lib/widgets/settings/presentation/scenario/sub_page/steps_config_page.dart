import 'package:aves/model/scenario/scenario.dart';
import 'package:aves/model/scenario/scenario_step.dart';
import 'package:aves/model/settings/settings.dart';
import 'package:aves/widgets/common/action_mixins/feedback.dart';
import 'package:aves/widgets/common/basic/scaffold.dart';
import 'package:aves/widgets/common/extensions/build_context.dart';
import 'package:aves/widgets/settings/presentation/foreground_wallpaper/tab_fixed.dart';
import 'package:aves/widgets/settings/presentation/scenario/action/scenario_steps_actions.dart';
import 'package:flutter/material.dart';

class ScenarioStepsPage extends StatefulWidget {
  static const routeName = '/settings/presentation/scenario/scenario_steps_config';

  final ScenarioRow scenario;
  const ScenarioStepsPage({super.key, required this.scenario});

  @override
  State<ScenarioStepsPage> createState() => _ScenarioStepsPageState();
}

class _ScenarioStepsPageState extends State<ScenarioStepsPage> with FeedbackMixin {
  final List<ScenarioStepRow?> _scenarioSteps = [];
  final Set<ScenarioStepRow?> _activeScenarioSteps = {};
  late ScenarioStepsConfigActions _scenarioStepActions;

  @override
  void initState() {
    super.initState();
    // first sync the rows data to the bridge data.
    // then all data shall modify in the bridgeAll data.
    // as already sync in scenario page, not need to sync now.
    //scenarioSteps.syncRowsToBridge();
    _scenarioSteps.addAll(scenarioSteps.bridgeAll.where((e) => e.scenarioId == widget.scenario.id));
    _scenarioSteps.sort();
    _activeScenarioSteps.addAll(_scenarioSteps.where((v) => v?.isActive ?? false));
    _scenarioStepActions = ScenarioStepsConfigActions(
      context: context,
      setState: setState,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final tabs = <(Tab, Widget)>[
      (
        Tab(text: l10n.settingsScenarioStepsTabTypes),
        MultiOpFixedListTab<ScenarioStepRow?>(
          items: _scenarioSteps,
          activeItems: _activeScenarioSteps,
          title: (item) => Text(item?.labelName ?? 'Empty'),
          editAction: _scenarioStepActions.editScenarioSteps,
          addItemAction: _scenarioStepActions.addScenarioSteps,
          applyChangesAction: _scenarioStepActions.applyOneScenarioStepsReorder,
          bannerString: l10n.settingsScenarioEditBanner,
          useSyncScheduleButton: false,
        ),
      ),
    ];

    return DefaultTabController(
      length: tabs.length,
      child: AvesScaffold(
        appBar: AppBar(
          automaticallyImplyLeading: !settings.useTvLayout,
          title: Text(l10n.settingsScenariosConfigPageTitle),
          bottom: TabBar(
            tabs: tabs.map((t) => t.$1).toList(),
          ),
        ),
        body: PopScope(
          canPop: true,
          onPopInvoked: (didPop) {},
          child: SafeArea(
            child: TabBarView(
              children: tabs.map((t) => t.$2).toList(),
            ),
          ),
        ),
      ),
    );
  }
}
