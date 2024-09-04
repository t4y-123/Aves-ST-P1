import 'package:aves/model/assign/assign_entries.dart';
import 'package:aves/model/assign/assign_record.dart';
import 'package:aves/model/scenario/scenario.dart';
import 'package:aves/model/scenario/scenario_step.dart';
import 'package:aves/model/settings/settings.dart';
import 'package:aves/widgets/common/action_mixins/feedback.dart';
import 'package:aves/widgets/common/basic/scaffold.dart';
import 'package:aves/widgets/common/extensions/build_context.dart';
import 'package:aves/widgets/settings/presentation/assign/action/assign_entries_actions.dart';
import 'package:aves/widgets/settings/presentation/common/tab_fixed.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SingleAssignRecordEditEntriesPage extends StatefulWidget {
  static const routeName = '/settings/presentation/assign_edit_settings/single_record_entries_edit_setting';
  final AssignRecordRow item;
  const SingleAssignRecordEditEntriesPage({super.key, required this.item});

  @override
  State<SingleAssignRecordEditEntriesPage> createState() => _SingleAssignRecordEditEntriesPageState();
}

class _SingleAssignRecordEditEntriesPageState extends State<SingleAssignRecordEditEntriesPage> with FeedbackMixin {
  late AssignEntriesActions _tab1Actions;

  AssignRecordRow get _item => widget.item;
  @override
  void initState() {
    super.initState();

    // t4y: not need to sync it this page as synced pre.
    // scenarioSteps.syncRowsToBridge();
    _tab1Actions = AssignEntriesActions(
      context: context,
      setState: setState,
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
            title: Text(l10n.settingsAssignRecordTabTypes),
            bottom: TabBar(
              tabs: [
                Tab(text: l10n.settingsAssignEntriesTabTypes),
              ],
            ),
          ),
          body: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: TabBarView(
                    children: [
                      Selector<AssignEntries, List<AssignEntryRow?>>(
                        selector: (_, provider) =>
                            provider.bridgeAll.where((e) => e.assignId == _item.id).toList().sorted(),
                        builder: (context, allItems, _) {
                          return MultiEditBridgeListTab<AssignEntryRow?>(
                            items: allItems,
                            activeItems: allItems.where((v) => v?.isActive ?? false).toSet(),
                            title: (item) => Text(item?.labelName ?? 'Empty'),
                            applyAction: _tab1Actions.applyChanges,
                            editAction: _tab1Actions.opItem,
                            activeChangeAction: _tab1Actions.activeItem,
                            bannerString: l10n.settingsAssignStepsOneBanner,
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
