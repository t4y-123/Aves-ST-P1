import 'package:aves/model/fgw/filters_set.dart';
import 'package:aves/model/fgw/guard_level.dart';
import 'package:aves/model/fgw/wallpaper_schedule.dart';
import 'package:aves/model/settings/settings.dart';
import 'package:aves/widgets/common/action_mixins/feedback.dart';
import 'package:aves/widgets/common/basic/scaffold.dart';
import 'package:aves/widgets/common/extensions/build_context.dart';
import 'package:aves/widgets/settings/presentation/foreground_wallpaper/filter_set/filter_set_config_actions.dart';
import 'package:aves/widgets/settings/presentation/foreground_wallpaper/guard_level/privacy_guard_level_config_actions.dart';
import 'package:aves/widgets/settings/presentation/foreground_wallpaper/schedule/wallpaper_schedule_config_actions.dart';
import 'package:aves/widgets/settings/presentation/foreground_wallpaper/tab_fixed.dart';
import 'package:flutter/material.dart';

class ForegroundWallpaperConfigPage extends StatefulWidget {
  static const routeName = '/settings/presentation_foreground_wallpaper_config';

  const ForegroundWallpaperConfigPage({super.key});

  @override
  State<ForegroundWallpaperConfigPage> createState() => _ForegroundWallpaperConfigPageState();
}

class _ForegroundWallpaperConfigPageState extends State<ForegroundWallpaperConfigPage> with FeedbackMixin {
  final List<FgwGuardLevelRow?> _privacyGuardLevels = [];
  final Set<FgwGuardLevelRow?> _activePrivacyGuardLevelsTypes = {};
  late PrivacyGuardLevelConfigActions _privacyGuardLevelActions;

  final List<FiltersSetRow?> _filterSet = [];
  final Set<FiltersSetRow?> _activeFilterSet = {};
  late FilterSetConfigActions _filterSetActions;

  final List<FgwScheduleRow?> _wallpaperSchedules = [];
  final Set<FgwScheduleRow?> _activeWallpaperSchedules = {};
  late WallpaperScheduleConfigActions _wallpaperSchedulesActions;

  @override
  void initState() {
    super.initState();
    // first sync the rows data to the bridge data.
    // then all data shall modify in the bridgeAll data.
    fgwGuardLevels.syncRowsToBridge();
    _privacyGuardLevels.addAll(fgwGuardLevels.bridgeAll);
    _privacyGuardLevels.sort(); // to sort make it show active item first.
    _activePrivacyGuardLevelsTypes.addAll(_privacyGuardLevels.where((v) => v?.isActive ?? false));
    _privacyGuardLevelActions = PrivacyGuardLevelConfigActions(
      context: context,
      setState: setState,
    );

    fgwSchedules.syncRowsToBridge();
    _wallpaperSchedules.addAll(fgwSchedules.bridgeAll);
    _wallpaperSchedules.sort(); // to sort make it show active item first.
    _activeWallpaperSchedules.addAll(_wallpaperSchedules.where((v) => v?.isActive ?? false));
    _wallpaperSchedulesActions = WallpaperScheduleConfigActions(context: context, setState: setState);

    filtersSets.syncRowsToBridge();
    _filterSet.addAll(filtersSets.bridgeAll);
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
        MultiOpFixedListTab<FgwGuardLevelRow?>(
          items: _privacyGuardLevels,
          activeItems: _activePrivacyGuardLevelsTypes,
          title: (item) => Text(item?.labelName ?? 'Empty'),
          editAction: _privacyGuardLevelActions.editItem,
          applyChangesAction: _privacyGuardLevelActions.applyChanges,
          addItemAction: _privacyGuardLevelActions.addNewItem,
          avatarColor: _privacyGuardLevelActions.privacyItemColor,
          bannerString: l10n.settingsMultiTabEditPageBanner,
        ),
      ),
      (
        Tab(text: l10n.settingsWallpaperScheduleTabTypes),
        MultiOpFixedListTab<FgwScheduleRow?>(
          items: _wallpaperSchedules,
          activeItems: _activeWallpaperSchedules,
          title: (item) => Text(item?.labelName ?? 'Empty'),
          applyChangesAction: _wallpaperSchedulesActions.applyChanges,
          editAction: _wallpaperSchedulesActions.editItem,
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
          editAction: _filterSetActions.editItem,
          applyChangesAction: _filterSetActions.applyChanges,
          addItemAction: _filterSetActions.addItem,
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
