import 'package:aves/model/fgw/filters_set.dart';
import 'package:aves/model/fgw/guard_level.dart';
import 'package:aves/model/fgw/wallpaper_schedule.dart';
import 'package:aves/model/settings/settings.dart';
import 'package:aves/widgets/common/action_mixins/feedback.dart';
import 'package:aves/widgets/common/basic/scaffold.dart';
import 'package:aves/widgets/common/extensions/build_context.dart';
import 'package:aves/widgets/settings/presentation/common/tab_fixed.dart';
import 'package:aves/widgets/settings/presentation/foreground_wallpaper/action/filter_set_edit_actions.dart';
import 'package:aves/widgets/settings/presentation/foreground_wallpaper/action/guard_level_actions.dart';
import 'package:aves/widgets/settings/presentation/foreground_wallpaper/action/schedule_actions.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class FgwEditSettingPage extends StatefulWidget {
  static const routeName = '/settings/presentation/fgw_edit_setting';

  const FgwEditSettingPage({super.key});

  @override
  State<FgwEditSettingPage> createState() => _FgwEditSettingPageState();
}

class _FgwEditSettingPageState extends State<FgwEditSettingPage> with FeedbackMixin {
  late GuardLevelActions _guardLevelActions;
  late FiltersSetConfigActions _filterSetActions;
  late FgwScheduleActions _fgwSchedulesActions;

  @override
  void initState() {
    super.initState();
    // first sync the rows data to the bridge data.
    // then all data shall modify in the bridgeAll data.
    fgwGuardLevels.syncRowsToBridge();
    _guardLevelActions = GuardLevelActions(
      setState: setState,
    );

    fgwSchedules.syncRowsToBridge();
    _fgwSchedulesActions = FgwScheduleActions(context: context, setState: setState);

    filtersSets.syncRowsToBridge();
    _filterSetActions = FiltersSetConfigActions(context: context, setState: setState);
    // Add listeners to track modifications
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<GuardLevel>.value(value: fgwGuardLevels),
        ChangeNotifierProvider<FgwSchedule>.value(value: fgwSchedules),
        ChangeNotifierProvider<FiltersSet>.value(value: filtersSets),
      ],
      child: DefaultTabController(
        length: 3,
        child: AvesScaffold(
          appBar: AppBar(
            automaticallyImplyLeading: !settings.useTvLayout,
            title: Text(l10n.settingsPresentationForegroundWallpaperConfigTile),
            bottom: TabBar(
              tabs: [
                Tab(text: l10n.settingsPrivacyGuardLevelTabTypes),
                Tab(text: l10n.settingsWallpaperScheduleTabTypes),
                Tab(text: l10n.settingsFilterSetTabTypes),
              ],
            ),
          ),
          body: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: TabBarView(
                    children: [
                      Selector<GuardLevel, List<FgwGuardLevelRow?>>(
                        selector: (_, provider) => provider.bridgeAll.toList().sorted(),
                        builder: (context, allItems, _) {
                          return MultiEditBridgeListTab<FgwGuardLevelRow?>(
                            items: allItems,
                            activeItems: allItems.where((v) => v?.isActive ?? false).toSet(),
                            title: (item) => Text(item?.labelName ?? 'Empty'),
                            applyAction: _guardLevelActions.applyChanges,
                            resetAction: _guardLevelActions.resetChanges,
                            editAction: _guardLevelActions.opItem,
                            addItemAction: _guardLevelActions.opItem,
                            activeChangeAction: _guardLevelActions.activeItem,
                            bannerString: l10n.settingsMultiTabEditPageBanner,
                            avatarColor: _guardLevelActions.privacyItemColor,
                          );
                        },
                      ),
                      Selector<FgwSchedule, List<FgwScheduleRow?>>(
                        selector: (_, provider) => provider.bridgeAll.toList().sorted(),
                        builder: (context, allItems, _) {
                          return MultiEditBridgeListTab<FgwScheduleRow?>(
                            items: allItems,
                            activeItems: allItems.where((v) => v?.isActive ?? false).toSet(),
                            title: (item) => Text(item?.labelName ?? 'Empty'),
                            applyAction: _fgwSchedulesActions.applyChanges,
                            editAction: _fgwSchedulesActions.opItem,
                            activeChangeAction: _fgwSchedulesActions.activeItem,
                            bannerString: l10n.settingsFgwScheduleBanner,
                          );
                        },
                      ),
                      Selector<FiltersSet, List<FiltersSetRow?>>(
                        selector: (_, provider) => provider.bridgeAll.toList().sorted(),
                        builder: (context, filtersSet, _) {
                          return MultiEditBridgeListTab<FiltersSetRow?>(
                            items: filtersSet,
                            activeItems: filtersSet.where((v) => v?.isActive ?? false).toSet(),
                            title: (item) => Text(item?.labelName ?? 'Empty'),
                            applyAction: _filterSetActions.applyChanges,
                            editAction: _filterSetActions.opItem,
                            addItemAction: _filterSetActions.opItem,
                            activeChangeAction: _filterSetActions.activeItem,
                            removeItemAction: _filterSetActions.removeItem,
                            bannerString: l10n.settingsFgwFiltersSetBanner,
                          );
                        },
                      ),
                      // Selector<FilterSet, List<FiltersSetRow?>>(
                      //   selector: (_, provider) => provider.bridgeAll.toList().sorted(),
                      //   builder: (context, filterSet, _) {
                      //     return MultiEditBridgeListTab<FiltersSetRow?>(
                      //       items: filterSet,
                      //       activeItems: filterSet.where((v) => v?.isActive ?? false).toSet(),
                      //       title: (item) => Text(item?.labelName ?? 'Empty'),
                      //       applyAction: _filterSetActions.applyChanges,
                      //       editAction: _filterSetActions.editItem,
                      //       addItemAction: _filterSetActions.addItem,
                      //       bannerString: l10n.settingsFgwFiltersSetBanner,
                      //     );
                      //   },
                      // ),
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
