import 'package:aves/model/foreground_wallpaper/privacy_guard_level.dart';
import 'package:aves/model/foreground_wallpaper/wallpaper_schedule.dart';
import 'package:aves/model/settings/settings.dart';
import 'package:aves/widgets/common/basic/scaffold.dart';
import 'package:aves/widgets/common/extensions/build_context.dart';
import 'package:aves/widgets/settings/presentation/foreground_wallpaper/guard_level/privacy_guard_level_config_actions.dart';
import 'package:aves/widgets/settings/presentation/foreground_wallpaper/tab_fixed.dart';
import 'package:flutter/material.dart';

import '../../../../model/foreground_wallpaper/filtersSet.dart';
import '../../../common/action_mixins/feedback.dart';
import 'filter_set/filter_set_config_actions.dart';
import 'schedule/wallpaper_schedule_config_actions.dart';

class ForegroundWallpaperConfigPage extends StatefulWidget {
  static const routeName = '/settings/presentation_foreground_wallpaper_config';

  const ForegroundWallpaperConfigPage({super.key});

  @override
  State<ForegroundWallpaperConfigPage> createState() => _ForegroundWallpaperConfigPageState();
}

class _ForegroundWallpaperConfigPageState extends State<ForegroundWallpaperConfigPage> with FeedbackMixin {
  final List<PrivacyGuardLevelRow?> _privacyGuardLevels = [];
  final Set<PrivacyGuardLevelRow?> _activePrivacyGuardLevelsTypes = {};
  late PrivacyGuardLevelConfigActions _privacyGuardLevelActions;

  final List<FiltersSetRow?> _filterSet = [];
  final Set<FiltersSetRow?> _activeFilterSet = {};
  late FilterSetConfigActions _filterSetActions;

  final List<WallpaperScheduleRow?> _wallpaperSchedules = [];
  final Set<WallpaperScheduleRow?> _activeWallpaperSchedules = {};
  late WallpaperScheduleConfigActions _wallpaperSchedulesActions;

  @override
  void initState() {
    super.initState();
    // first sync the rows data to the bridge data.
    // then all data shall modify in the bridgeAll data.
    privacyGuardLevels.syncRowsToBridge();
    _privacyGuardLevels.addAll(privacyGuardLevels.bridgeAll);
    _privacyGuardLevels.sort(); // to sort make it show active item first.
    _activePrivacyGuardLevelsTypes.addAll(_privacyGuardLevels.where((v) => v?.isActive ?? false));
    _privacyGuardLevelActions = PrivacyGuardLevelConfigActions(
      context: context,
      setState: setState,
    );

    wallpaperSchedules.syncRowsToBridge();
    _wallpaperSchedules.addAll(wallpaperSchedules.bridgeAll);
    _wallpaperSchedules.sort(); // to sort make it show active item first.
    _activeWallpaperSchedules.addAll(_wallpaperSchedules.where((v) => v?.isActive ?? false));
    _wallpaperSchedulesActions = WallpaperScheduleConfigActions(context: context, setState: setState);

    // t4y: TODO: only the filtersSet not use bridge.
    // do it later or not.
    _filterSet.addAll(filtersSets.all);
    _filterSet.sort(); // to sort make it show active item first.
    _activeFilterSet.addAll(_filterSet.where((v) => v?.isActive ?? false));
    _filterSetActions = FilterSetConfigActions(context: context, setState: setState);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final tabs = <(Tab, Widget)>[
      (
        Tab(text: l10n.settingsPrivacyGuardLevelTabTypes),
        MultiOpFixedListTab<PrivacyGuardLevelRow?>(
          items: _privacyGuardLevels,
          activeItems: _activePrivacyGuardLevelsTypes,
          title: (item) => Text(item?.labelName ?? 'Empty'),
          editAction: _privacyGuardLevelActions.editPrivacyGuardLevel,
          applyChangesAction: _privacyGuardLevelActions.applyPrivacyGuardLevelReorder,
          addItemAction: _privacyGuardLevelActions.addPrivacyGuardLevel,
          avatarColor: _privacyGuardLevelActions.privacyItemColor,
          bannerString: l10n.settingsForegroundWallpaperConfigBanner,
        ),
      ),
      (
        Tab(text: l10n.settingsWallpaperScheduleTabTypes),
        MultiOpFixedListTab<WallpaperScheduleRow?>(
          items: _wallpaperSchedules,
          activeItems: _activeWallpaperSchedules,
          title: (item) => Text(item?.labelName ?? 'Empty'),
          applyChangesAction: _wallpaperSchedulesActions.applyWallpaperScheduleReorder,
          editAction: _wallpaperSchedulesActions.editWallpaperSchedule,
          canRemove: false,
          bannerString: l10n.settingsFgwScheduleBanner,
        ),
      ),
      (
        Tab(text: l10n.settingsFilterSetTabTypes),
        MultiOpFixedListTab<FiltersSetRow?>(
          items: _filterSet,
          activeItems: _activeFilterSet,
          title: (item) => Text(item?.labelName ?? 'Empty'),
          editAction: _filterSetActions.editFilterSet,
          applyChangesAction: _filterSetActions.applyFilterSet,
          addItemAction: _filterSetActions.addFilterSet,
          bannerString: l10n.settingsFgwFiltersSetBanner,
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
