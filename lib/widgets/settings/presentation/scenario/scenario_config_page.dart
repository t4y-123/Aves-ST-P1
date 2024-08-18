import 'package:aves/model/scenario/scenario.dart';
import 'package:aves/model/settings/settings.dart';
import 'package:aves/widgets/common/basic/scaffold.dart';
import 'package:aves/widgets/common/extensions/build_context.dart';
import 'package:aves/widgets/settings/presentation/foreground_wallpaper/tab_fixed.dart';
import 'package:aves/widgets/settings/presentation/scenario/action/scenario_base_config_actions.dart';
import 'package:flutter/material.dart';

import '../../../common/action_mixins/feedback.dart';

class ScenarioConfigPage extends StatefulWidget {
  static const routeName = '/settings/scenario_config';

  const ScenarioConfigPage({super.key});

  @override
  State<ScenarioConfigPage> createState() => _ScenarioConfigPageState();
}

class _ScenarioConfigPageState extends State<ScenarioConfigPage> with FeedbackMixin {
  final List<ScenarioRow?> _scenarios = [];
  final Set<ScenarioRow?> _activeScenarios = {};
  late ScenarioBaseConfigActions _scenarioActions;

  @override
  void initState() {
    super.initState();
    // first sync the rows data to the bridge data.
    // then all data shall modify in the bridgeAll data.
    scenarios.syncRowsToBridge();
    _scenarios.addAll(scenarios.bridgeAll);
    _scenarios.sort(); // to sort make it show active item first.
    _activeScenarios.addAll(_scenarios.where((v) => v?.isActive ?? false));
    _scenarioActions = ScenarioBaseConfigActions(
      context: context,
      setState: setState,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final tabs = <(Tab, Widget)>[
      (
        Tab(text: l10n.settingsPrivacyGuardLevelTabTypes),
        ForegroundWallpaperFixedListTab<ScenarioRow?>(
          items: _scenarios,
          activeItems: _activeScenarios,
          title: (item) => Text(item?.labelName ?? 'Empty'),
          editAction: _scenarioActions.editScenarioBase,
          applyChangesAction: _scenarioActions.applyScenarioBaseReorder,
          addItemAction: _scenarioActions.addScenarioBase,
          avatarColor: _scenarioActions.privacyItemColor,
          bannerString: l10n.settingsForegroundWallpaperConfigBanner,
        ),
      ),
    ];

    return DefaultTabController(
      length: tabs.length,
      child: AvesScaffold(
        appBar: AppBar(
          automaticallyImplyLeading: !settings.useTvLayout,
          title: Text(l10n.settingsPresentationForegroundWallpaperConfigTile),
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
