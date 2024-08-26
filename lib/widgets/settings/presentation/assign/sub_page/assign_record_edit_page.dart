import 'dart:math';

import 'package:aves/model/assign/assign_entries.dart';
import 'package:aves/model/assign/assign_record.dart';
import 'package:aves/theme/durations.dart';
import 'package:aves/widgets/common/action_mixins/feedback.dart';
import 'package:aves/widgets/common/app_bar/app_bar_title.dart';
import 'package:aves/widgets/common/basic/insets.dart';
import 'package:aves/widgets/common/basic/scaffold.dart';
import 'package:aves/widgets/common/extensions/build_context.dart';
import 'package:aves/widgets/common/extensions/media_query.dart';
import 'package:aves/widgets/common/identity/buttons/outlined_button.dart';
import 'package:aves/widgets/settings/presentation/assign/sub_page/assign_entries_edit_page.dart';
import 'package:aves/widgets/settings/presentation/assign/sub_page/assign_record_base_section.dart';
import 'package:aves/widgets/settings/settings_definition.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:provider/provider.dart';

class AssignRecordSettingPage extends StatefulWidget {
  static const routeName = '/settings/presentation/assign_record_edit_sub_page';

  final AssignRecordRow item;
  final Set<AssignEntryRow> subItems;

  const AssignRecordSettingPage({
    super.key,
    required this.item,
    required this.subItems,
  });

  @override
  State<AssignRecordSettingPage> createState() => _AssignRecordSettingPageState();
}

class _AssignRecordSettingPageState extends State<AssignRecordSettingPage> with FeedbackMixin {
  final ValueNotifier<String?> _expandedNotifier = ValueNotifier(null);
  AssignRecordRow get _item => widget.item;

  @override
  void dispose() {
    _expandedNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    List<AssignEntryRow> thisAssignEntry = assignEntries.bridgeAll.where((e) => e.assignId == widget.item.id).toList();
    debugPrint('$runtimeType _ScenarioBaseSettingPageState $thisAssignEntry');
    final List<SettingsTile> preTiles = [
      AssignRecordPreInfoTitleTile(item: _item),
      AssignRecordLabelNameModifiedTile(item: _item),
      //AssignRecordColorPickerTile(item: _item),// not effect for the filter have its color.
      AssignRecordActiveListTile(item: _item),
    ];
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
                  builder: (context) => AssignEntriesEditConfigPage(
                    assignRecord: _item,
                  ),
                ),
              );
            },
            label: context.l10n.settingsAssignEditEntries,
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
        ChangeNotifierProvider<AssignRecord>.value(value: assignRecords),
        ChangeNotifierProvider<AssignEntries>.value(value: assignEntries),
      ],
      child: Theme(
        data: theme.copyWith(
          textTheme: theme.textTheme.copyWith(
            bodyMedium: const TextStyle(fontSize: 12),
          ),
        ),
        child: Selector<AssignEntries, List<AssignEntryRow>>(
          selector: (context, subItems) => subItems.bridgeAll.where((e) => e.assignId == widget.item.id).toList(),
          builder: (context, thisAssignEntry, _) {
            final stepTiles =
                thisAssignEntry.map((e) => AssignEntrySubPageTile(item: widget.item, subItem: e)).toList();

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

  void _applyChanges(BuildContext context, AssignRecordRow item) {
    Navigator.pop(context, item);
  }
}
