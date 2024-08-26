import 'dart:math';

import 'package:aves/model/scenario/scenario.dart';
import 'package:aves/model/scenario/scenario_step.dart';
import 'package:aves/theme/durations.dart';
import 'package:aves/widgets/common/action_mixins/feedback.dart';
import 'package:aves/widgets/common/app_bar/app_bar_title.dart';
import 'package:aves/widgets/common/basic/insets.dart';
import 'package:aves/widgets/common/basic/scaffold.dart';
import 'package:aves/widgets/common/extensions/build_context.dart';
import 'package:aves/widgets/common/extensions/media_query.dart';
import 'package:aves/widgets/settings/presentation/scenario/sub_page/scenario_base_section.dart';
import 'package:aves/widgets/settings/presentation/scenario/sub_page/steps_config_page.dart';
import 'package:aves/widgets/settings/settings_definition.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:provider/provider.dart';

import '../../../../common/identity/buttons/outlined_button.dart';

class ScenarioBaseSettingPage extends StatefulWidget {
  static const routeName = '/settings/presentation/scenario_base_settings_page';

  final ScenarioRow item;
  final Set<ScenarioStepRow> subItems;

  const ScenarioBaseSettingPage({
    super.key,
    required this.item,
    required this.subItems,
  });

  @override
  State<ScenarioBaseSettingPage> createState() => _ScenarioBaseSettingPageState();
}

class _ScenarioBaseSettingPageState extends State<ScenarioBaseSettingPage> with FeedbackMixin {
  final ValueNotifier<String?> _expandedNotifier = ValueNotifier(null);
  ScenarioRow get _item => widget.item;

  @override
  void dispose() {
    _expandedNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    List<ScenarioStepRow> thisScenarioSteps =
        scenarioSteps.bridgeAll.where((e) => e.scenarioId == widget.item.id).toList();
    debugPrint('$runtimeType _ScenarioBaseSettingPageState $thisScenarioSteps');
    final List<SettingsTile> preTiles = [
      ScenarioPreInfoTitleTile(item: _item),
      ScenarioLabelNameModifiedTile(item: _item),
      //ScenarioColorPickerTile(item: _item),// not effect for the filter have its color.
      ScenarioCopyStepsFromExistListTile(item: _item),
      ScenarioLoadTypeSwitchTile(item: _item),
      ScenarioActiveListTile(item: _item),
    ];
    // final List<SettingsTile> stepTiles =
    //     thisScenarioSteps.map((e) => ScenarioStepSubPageTile(item: widget.item, subItem: e)).toList();
    // debugPrint('$runtimeType _ScenarioBaseSettingPageState  stepTiles $stepTiles');
    final List<Widget> postWidgets = [
      const Divider(height: 10),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          AvesOutlinedButton(
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ScenarioStepsPage(
                    scenario: _item,
                  ),
                ),
              );
            },
            label: context.l10n.settingsScenarioEditSteps,
          ),
          AvesOutlinedButton(
            onPressed: () {
              _applyChanges(context, widget.item);
            },
            label: context.l10n.settingsForegroundWallpaperConfigApplyChanges,
          ),
        ],
      ),
    ];

    return AvesScaffold(
      appBar: AppBar(
        title: InteractiveAppBarTitle(
          child: Text(context.l10n.settingsPageTitle),
        ),
      ),
      body: GestureAreaProtectorStack(
        child: SafeArea(
          bottom: false,
          child: AnimationLimiter(
            child: _buildSettingsList(context, preTiles, postWidgets),
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsList(BuildContext context, List<SettingsTile> preTiles, List<Widget> postWidgets) {
    final theme = Theme.of(context);
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<Scenario>.value(value: scenarios),
        ChangeNotifierProvider<ScenarioSteps>.value(value: scenarioSteps),
      ],
      child: Theme(
        data: theme.copyWith(
          textTheme: theme.textTheme.copyWith(
            bodyMedium: const TextStyle(fontSize: 12),
          ),
        ),
        child: Selector<ScenarioSteps, List<ScenarioStepRow>>(
          selector: (context, steps) => steps.bridgeAll.where((e) => e.scenarioId == widget.item.id).toList(),
          builder: (context, thisScenarioSteps, _) {
            final stepTiles =
                thisScenarioSteps.map((e) => ScenarioStepSubPageTile(item: widget.item, subItem: e)).toList();

            final durations = context.watch<DurationsData>();
            debugPrint('$runtimeType _buildSettingsList stepTiles $stepTiles');
            return Selector<MediaQueryData, double>(
              selector: (context, mq) => max(mq.effectiveBottomPadding, mq.systemGestureInsets.bottom),
              builder: (context, mqPaddingBottom, __) {
                return ListView(
                  padding: const EdgeInsets.all(8) + EdgeInsets.only(bottom: mqPaddingBottom),
                  children: AnimationConfiguration.toStaggeredList(
                    duration: durations.staggeredAnimation,
                    delay: durations.staggeredAnimationDelay * timeDilation,
                    childAnimationBuilder: (child) => SlideAnimation(
                      verticalOffset: 50.0,
                      child: FadeInAnimation(child: child),
                    ),
                    children: [
                      ...preTiles.map((v) => v.build(context)),
                      ...stepTiles.map((v) => v.build(context)),
                      ...postWidgets,
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  void _applyChanges(BuildContext context, ScenarioRow item) {
    Navigator.pop(context, item);
  }
}
