import 'package:aves/model/assign/assign_entries.dart';
import 'package:aves/model/assign/assign_record.dart';
import 'package:aves/model/entry/entry.dart';
import 'package:aves/model/settings/settings.dart';
import 'package:aves/model/source/collection_source.dart';
import 'package:aves/widgets/common/action_mixins/feedback.dart';
import 'package:aves/widgets/common/basic/scaffold.dart';
import 'package:aves/widgets/common/extensions/build_context.dart';
import 'package:aves/widgets/settings/presentation/assign/action/assign_entries_actions.dart';
import 'package:aves/widgets/settings/presentation/foreground_wallpaper/tab_fixed.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AssignEntriesEditConfigPage extends StatefulWidget {
  static const routeName = '/settings/presentation/assignRecord/assign_edit_config';
  final AssignRecordRow assignRecord;

  const AssignEntriesEditConfigPage({super.key, required this.assignRecord});

  @override
  State<AssignEntriesEditConfigPage> createState() => _AssignEntriesEditConfigPageState();
}

class _AssignEntriesEditConfigPageState extends State<AssignEntriesEditConfigPage> with FeedbackMixin {
  final List<AssignEntryRow?> _assignEntries = [];
  final Set<AssignEntryRow?> _activeAssignEntries = {};
  late AssignEntryActions assignEntryActions;

  @override
  void initState() {
    super.initState();
    // assignEntry
    assignEntries.syncRowsToBridge();
    _assignEntries.addAll(assignEntries.bridgeAll.where((e) => e.assignId == widget.assignRecord.id));
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
