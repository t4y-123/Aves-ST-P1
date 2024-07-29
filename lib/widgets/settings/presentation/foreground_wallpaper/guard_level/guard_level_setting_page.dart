import 'dart:math';
import 'package:aves/model/foreground_wallpaper/enum/fgw_schedule_item.dart';
import 'package:aves/model/foreground_wallpaper/wallpaper_schedule.dart';
import 'package:aves/model/settings/settings.dart';
import 'package:aves/theme/durations.dart';
import 'package:aves/widgets/common/extensions/build_context.dart';

import 'package:aves/widgets/common/extensions/media_query.dart';
import 'package:aves/widgets/settings/settings_definition.dart';
import 'package:aves/widgets/settings/settings_tv_page.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:provider/provider.dart';

import '../../../../../model/foreground_wallpaper/filtersSet.dart';
import '../../../../../model/foreground_wallpaper/privacy_guard_level.dart';
import '../../../../common/identity/buttons/outlined_button.dart';
import 'guard_level_section_base.dart';
import 'guard_level_settings_mobile_page.dart';

class GuardLevelSettingPage extends StatelessWidget {
  static const routeName = '/settings/presentation/guard_level_setting_page';

  final PrivacyGuardLevelRow item;
  final Set<WallpaperScheduleRow> schedules;

  const GuardLevelSettingPage({
    super.key,
    required this.item,
    required this.schedules,
  });

  @override
  Widget build(BuildContext context) {
    if (settings.useTvLayout) {
      //t4y: for I have none AndroidTV,there only have the mobile version of guard level settings.
      return const SettingsTvPage();
    } else {
      final homeSchedule = schedules.firstWhereOrNull(
          (e) => e.privacyGuardLevelId == item.privacyGuardLevelID && e.updateType == WallpaperUpdateType.home);
      final lockSchedule = schedules.firstWhereOrNull(
          (e) => e.privacyGuardLevelId == item.privacyGuardLevelID && e.updateType == WallpaperUpdateType.lock);
      final bothSchedule = schedules.firstWhereOrNull(
          (e) => e.privacyGuardLevelId == item.privacyGuardLevelID && e.updateType == WallpaperUpdateType.both);
      final widgetSchedulesList = schedules.where(
          (e) => e.privacyGuardLevelId == item.privacyGuardLevelID && e.updateType == WallpaperUpdateType.widget);

      final List<SettingsTile> preTiles = [
        GuardLevelTitleTile(item: item),
        GuardLevelLabelNameModifiedTile(item: item),
        GuardLevelColorPickerTile(item: item),
        GuardLevelCopySchedulesFromExistListTile(item: item),
        GuardLevelScheduleUpdateTypeListTile(item: item),
        if (homeSchedule != null) ScheduleSubPageTile(item: item, schedule: homeSchedule),
        if (lockSchedule != null) ScheduleSubPageTile(item: item, schedule: lockSchedule),
        if (bothSchedule != null) ScheduleSubPageTile(item: item, schedule: bothSchedule),
        ...widgetSchedulesList.map((e) => ScheduleSubPageTile(item: item, schedule: e)).toList(),
        GuardLevelActiveListTile(item: item),
      ];
      final List<Widget> postWidgets = [
        const Divider(
          height: 40,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            AvesOutlinedButton(
              onPressed: () {
                _applyChanges(context, item);
              },
              label: context.l10n.settingsForegroundWallpaperConfigApplyChanges,
            ),
          ],
        ),
      ];
      // final List<ItemSettingsSection> sections = [
      //   if(homeSchedule != null) GuardLevelScheduleItemSection(item:item,schedule: homeSchedule),
      // ];
      return ExpandableSettingsPage(
        preTiles: preTiles,
        postWidgets: postWidgets,
      );
    }
  }

  void _applyChanges(BuildContext context, PrivacyGuardLevelRow item) {
    final updateItem =
        privacyGuardLevels.bridgeAll.firstWhereOrNull((e) => e.privacyGuardLevelID == item.privacyGuardLevelID);
    Navigator.pop(context, updateItem); // Return the updated item
  }
}

class FgwSettingsListView extends StatelessWidget {
  final List<Widget> children;

  const FgwSettingsListView({
    super.key,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    debugPrint('$runtimeType FgwSettingsListView theme  $theme');
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<PrivacyGuardLevel>.value(value: privacyGuardLevels),
        ChangeNotifierProvider<WallpaperSchedules>.value(value: wallpaperSchedules),
        ChangeNotifierProvider<FilterSet>.value(value: filtersSets),
      ],
      child: Theme(
        data: theme.copyWith(
          textTheme: theme.textTheme.copyWith(
            // dense style font for tile subtitles, without modifying title font
            bodyMedium: const TextStyle(fontSize: 12),
          ),
        ),
        child: Selector<MediaQueryData, double>(
          selector: (context, mq) => max(mq.effectiveBottomPadding, mq.systemGestureInsets.bottom),
          builder: (context, mqPaddingBottom, child) {
            final durations = context.watch<DurationsData>();
            return ListView(
              padding: const EdgeInsets.all(8) + EdgeInsets.only(bottom: mqPaddingBottom),
              children: AnimationConfiguration.toStaggeredList(
                duration: durations.staggeredAnimation,
                delay: durations.staggeredAnimationDelay * timeDilation,
                childAnimationBuilder: (child) => SlideAnimation(
                  verticalOffset: 50.0,
                  child: FadeInAnimation(
                    child: child,
                  ),
                ),
                children: children,
              ),
            );
          },
        ),
      ),
    );
  }
}
