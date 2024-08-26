import 'package:aves/model/assign/assign_entries.dart';
import 'package:aves/model/assign/assign_record.dart';
import 'package:aves/model/entry/entry.dart';
import 'package:aves/model/settings/settings.dart';
import 'package:aves/model/source/collection_source.dart';
import 'package:aves/widgets/common/basic/scaffold.dart';
import 'package:aves/widgets/common/extensions/build_context.dart';
import 'package:aves/widgets/settings/presentation/assign/action/assign_entries_actions.dart';
import 'package:aves/widgets/settings/presentation/assign/action/assign_record_actions.dart';
import 'package:aves/widgets/settings/presentation/foreground_wallpaper/tab_fixed.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../common/action_mixins/feedback.dart';

class AssignEditConfigPage extends StatefulWidget {
  static const routeName = '/settings/presentation/scenario/assign_edit_config';

  const AssignEditConfigPage({super.key});

  @override
  State<AssignEditConfigPage> createState() => _AssignEditConfigPageState();
}

class _AssignEditConfigPageState extends State<AssignEditConfigPage> with FeedbackMixin {
  final List<AssignRecordRow?> _assignRecords = [];
  final Set<AssignRecordRow?> _activeAssignRecords = {};
  late AssignRecordActions assignRecordsAction;

  final List<AssignEntryRow?> _assignEntries = [];
  final Set<AssignEntryRow?> _activeAssignEntries = {};
  late AssignEntryActions assignEntryActions;

  @override
  void initState() {
    super.initState();
    // first sync the rows data to the bridge data.
    // then all data shall modify in the bridgeAll data.
    assignRecords.syncRowsToBridge();
    _assignRecords.addAll(assignRecords.bridgeAll);
    _assignRecords.sort(); // to sort make it show active item first.
    _activeAssignRecords.addAll(_assignRecords.where((v) => v?.isActive ?? false));
    assignRecordsAction = AssignRecordActions(
      context: context,
      setState: setState,
    );

    // assignEntry
    assignEntries.syncRowsToBridge();
    _assignEntries.addAll(assignEntries.bridgeAll);
    _assignEntries.sort(); // to sort make it show active item first.
    _activeAssignEntries.addAll(_assignEntries.where((v) => v?.isActive ?? false));
    assignEntryActions = AssignEntryActions(
      context: context,
      setState: setState,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final source = context.read<CollectionSource>();

    final tabs = <(Tab, Widget)>[
      (
        Tab(text: l10n.settingsAssignRecordTabTypes),
        MultiOpFixedListTab<AssignRecordRow?>(
          items: _assignRecords,
          activeItems: _activeAssignRecords,
          title: (item) => Text(item?.labelName ?? 'Empty'),
          editAction: assignRecordsAction.editSelectedItem,
          applyChangesAction: assignRecordsAction.applyScenarioBaseReorder,
          //avatarColor: assignRecordsAction.privacyItemColor,
          bannerString: l10n.settingsScenarioEditBanner,
          useSyncScheduleButton: false,
          canBeEmpty: true,
          canBeActiveEmpty: true,
        ),
      ),
      (
        Tab(text: l10n.settingsAssignEntryTabTypes),
        MultiOpFixedListTab<AssignEntryRow?>(
          items: _assignEntries,
          activeItems: _activeAssignEntries,
          title: (item) => Text(
              (source.allEntries.firstWhereOrNull((e) => e.id == item?.entryId) as AvesEntry).bestTitle ?? 'Empty'),
          editAction: assignEntryActions.editSelectedItem,
          applyChangesAction: assignEntryActions.applyScenarioBaseReorder,
          bannerString: l10n.settingsScenarioEditBanner,
          useSyncScheduleButton: false,
          useActiveButton: false,
          canRemove: false,
          canBeEmpty: true,
          canBeActiveEmpty: true,
        ),
      ),
    ];

    return DefaultTabController(
      length: tabs.length,
      child: AvesScaffold(
        appBar: AppBar(
          automaticallyImplyLeading: !settings.useTvLayout,
          title: Text(l10n.settingsAssignConfigPageTitle),
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
