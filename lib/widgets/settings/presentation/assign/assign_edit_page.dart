import 'package:aves/model/assign/assign_entries.dart';
import 'package:aves/model/assign/assign_record.dart';
import 'package:aves/model/fgw/wallpaper_schedule.dart';
import 'package:aves/model/scenario/scenario.dart';
import 'package:aves/model/settings/settings.dart';
import 'package:aves/widgets/common/action_mixins/feedback.dart';
import 'package:aves/widgets/common/basic/scaffold.dart';
import 'package:aves/widgets/common/extensions/build_context.dart';
import 'package:aves/widgets/settings/presentation/assign/action/assign_entries_actions.dart';
import 'package:aves/widgets/settings/presentation/assign/action/assign_record_actions.dart';
import 'package:aves/widgets/settings/presentation/common/tab_fixed.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AssignRecordEditSettingPage extends StatefulWidget {
  static const routeName = '/settings/presentation/assign/record_edit_settings_page';

  const AssignRecordEditSettingPage({super.key});

  @override
  State<AssignRecordEditSettingPage> createState() => _AssignRecordEditSettingPageState();
}

class _AssignRecordEditSettingPageState extends State<AssignRecordEditSettingPage> with FeedbackMixin {
  late AssignRecordActions _tab1Actions;
  late AssignEntriesActions _tab2Actions;

  @override
  void initState() {
    super.initState();

    // first sync the rows data to the bridge data.
    // then all data shall modify in the bridgeAll data.
    scenarios.syncRowsToBridge();
    _tab1Actions = AssignRecordActions(context: context, setState: setState);

    fgwSchedules.syncRowsToBridge();
    _tab2Actions = AssignEntriesActions(context: context, setState: setState);
    // Add listeners to track modifications
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AssignRecord>.value(value: assignRecords),
        ChangeNotifierProvider<AssignEntries>.value(value: assignEntries),
      ],
      child: DefaultTabController(
        length: 2,
        child: AvesScaffold(
          appBar: AppBar(
            automaticallyImplyLeading: !settings.useTvLayout,
            title: Text(l10n.settingsAssignEditTitle),
            bottom: TabBar(
              tabs: [
                Tab(text: l10n.settingsAssignRecordTabTypes),
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
                      Selector<AssignRecord, List<AssignRecordRow?>>(
                        selector: (_, provider) => provider.bridgeAll.toList().sorted(),
                        builder: (context, allItems, _) {
                          return MultiEditBridgeListTab<AssignRecordRow?>(
                            items: allItems,
                            activeItems: allItems.where((v) => v?.isActive ?? false).toSet(),
                            title: (item) => Text(item?.labelName ?? 'Empty'),
                            applyAction: _tab1Actions.applyChanges,
                            resetAction: _tab1Actions.resetChanges,
                            editAction: _tab1Actions.opItem,
                            addItemAction: _tab1Actions.opItem,
                            activeChangeAction: _tab1Actions.activeItem,
                            bannerString: l10n.settingsAssignEditBanner,
                          );
                        },
                      ),
                      Selector<AssignEntries, List<AssignEntryRow?>>(
                        selector: (_, provider) => provider.bridgeAll.toList().sorted(),
                        builder: (context, allItems, _) {
                          return MultiEditBridgeListTab<AssignEntryRow?>(
                            items: allItems,
                            activeItems: allItems.where((v) => v?.isActive ?? false).toSet(),
                            title: (item) => Text(item?.labelName ?? 'Empty'),
                            applyAction: _tab2Actions.applyChanges,
                            editAction: _tab2Actions.opItem,
                            activeChangeAction: _tab2Actions.activeItem,
                            bannerString: l10n.settingsAssignStepsAllBanner,
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
