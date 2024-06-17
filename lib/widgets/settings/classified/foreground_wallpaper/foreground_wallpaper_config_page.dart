import 'package:aves/model/foreground_wallpaper/privacyGuardLevel.dart';
import 'package:aves/model/foreground_wallpaper/wallpaperSchedule.dart';
import 'package:aves/model/settings/settings.dart';
import 'package:aves/widgets/common/basic/scaffold.dart';
import 'package:aves/widgets/common/extensions/build_context.dart';
import 'package:aves/widgets/settings/classified/foreground_wallpaper/privacy_guard_level/privacy_guard_level_config_actions.dart';
import 'package:aves/widgets/settings/classified/foreground_wallpaper/tab_fixed.dart';

import 'package:flutter/material.dart';
import '../../../../model/foreground_wallpaper/filterSet.dart';
import '../../../common/action_mixins/feedback.dart';
import 'filter_set/filter_set_config_actions.dart';
import 'schedule/wallpaper_schedule_config_actions.dart';

class ForegroundWallpaperConfigPage extends StatefulWidget  {
  static const routeName = '/settings/classified_foreground_wallpaper_config';

  const ForegroundWallpaperConfigPage({super.key});

  @override
  State<ForegroundWallpaperConfigPage> createState() => _ForegroundWallpaperConfigPageState();
}

class _ForegroundWallpaperConfigPageState extends State<ForegroundWallpaperConfigPage> with FeedbackMixin{
  final List<PrivacyGuardLevelRow?> _privacyGuardLevels = [];
  final Set<PrivacyGuardLevelRow?> _activePrivacyGuardLevelsTypes = {};
  late PrivacyGuardLevelConfigActions _privacyGuardLevelActions;

  final List<FilterSetRow?> _filterSet = [];
  final Set<FilterSetRow?> _activeFilterSet = {};
  late FilterSetConfigActions _filterSetActions;

  final List<WallpaperScheduleRow?> _wallpaperSchedules = [];
  final Set<WallpaperScheduleRow?> _activeWallpaperSchedules = {};
  late WallpaperScheduleConfigActions _wallpaperSchedulesActions;

  @override
  void initState() {
    super.initState();

    _privacyGuardLevels.addAll(privacyGuardLevels.all);
    _privacyGuardLevels.sort();// to sort make it show active item first.
    _activePrivacyGuardLevelsTypes.addAll(_privacyGuardLevels.where((v) => v?.isActive ?? false));
    _privacyGuardLevelActions = PrivacyGuardLevelConfigActions(context: context,setState: setState,);

    _filterSet.addAll(filterSet.all);
    _filterSet.sort();// to sort make it show active item first.
    _activeFilterSet.addAll(_filterSet.where((v) => v?.isActive ?? false));
    _filterSetActions = FilterSetConfigActions(context: context, setState: setState);

    _wallpaperSchedules.addAll(wallpaperSchedules.all);
    _wallpaperSchedules.sort();// to sort make it show active item first.
    _activeWallpaperSchedules.addAll(_wallpaperSchedules.where((v) => v?.isActive ?? false));
    _wallpaperSchedulesActions = WallpaperScheduleConfigActions(context: context, setState: setState);

  }


  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final tabs = <(Tab, Widget)>[
      (
      Tab(text: l10n.settingsPrivacyGuardLevelTabTypes),
        ForegroundWallpaperFixedListTab<PrivacyGuardLevelRow?>(
          items: _privacyGuardLevels,
          activeItems: _activePrivacyGuardLevelsTypes,
          title: (item) => Text(item?.aliasName ?? 'Empty'),
          editAction:_privacyGuardLevelActions.editPrivacyGuardLevel,
          applyChangesAction: _privacyGuardLevelActions.applyPrivacyGuardLevelReorder,
          addItemAction: _privacyGuardLevelActions.addPrivacyGuardLevel,
          avatarColor: _privacyGuardLevelActions.privacyItemColor,
        ),
      ),
      (
      Tab(text: l10n.settingsFilterSetTabTypes),
        ForegroundWallpaperFixedListTab<FilterSetRow?>(
          items: _filterSet,
          activeItems: _activeFilterSet,
          title: (item) => Text(item?.aliasName ?? 'Empty'),
          editAction:_filterSetActions.editFilterSet,
          applyChangesAction: _filterSetActions.applyFilterSet,
          addItemAction: _filterSetActions.addFilterSet,
        ),
      ),
    ];

    return DefaultTabController(
      length: tabs.length,
      child: AvesScaffold(
        appBar: AppBar(
          automaticallyImplyLeading: !settings.useTvLayout,
          title: Text(l10n.settingsClassifiedForegroundWallpaperConfigTile),
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
