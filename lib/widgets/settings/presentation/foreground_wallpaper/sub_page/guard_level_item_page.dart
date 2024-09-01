import 'package:aves/model/fgw/enum/fgw_schedule_item.dart';
import 'package:aves/model/fgw/filters_set.dart';
import 'package:aves/model/fgw/guard_level.dart';
import 'package:aves/model/fgw/wallpaper_schedule.dart';
import 'package:aves/widgets/settings/presentation/common/item_page.dart';
import 'package:aves/widgets/settings/presentation/foreground_wallpaper/sections/guard_level_section.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class GuardLevelItemPage extends StatelessWidget {
  static const routeName = '/settings/presentation/guard_level_item_page';

  final FgwGuardLevelRow item;

  const GuardLevelItemPage({
    super.key,
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<GuardLevel>.value(value: fgwGuardLevels),
        ChangeNotifierProvider<FgwSchedule>.value(value: fgwSchedules),
        ChangeNotifierProvider<FiltersSet>.value(value: filtersSets),
      ],
      child: PresentRowItemPage<FgwGuardLevelRow>(
        item: item,
        buildTiles: (item) {
          final homeSchedule = fgwSchedules.bridgeAll
              .firstWhereOrNull((e) => e.guardLevelId == item.id && e.updateType == WallpaperUpdateType.home);
          final lockSchedule = fgwSchedules.bridgeAll
              .firstWhereOrNull((e) => e.guardLevelId == item.id && e.updateType == WallpaperUpdateType.lock);
          final bothSchedule = fgwSchedules.bridgeAll
              .firstWhereOrNull((e) => e.guardLevelId == item.id && e.updateType == WallpaperUpdateType.both);
          debugPrint(
              'widgetSchedulesList all =${fgwSchedules.all.where((e) => e.guardLevelId == item.id && e.updateType == WallpaperUpdateType.widget).toSet()}');
          final widgetSchedulesList = fgwSchedules.bridgeAll
              .where((e) => e.guardLevelId == item.id && e.updateType == WallpaperUpdateType.widget);
          debugPrint('widgetSchedulesList=$widgetSchedulesList');
          return [
            GuardLevelTitleTile(item: item),
            GuardLevelLabelNameModifiedTile(item: item),
            GuardLevelColorPickerTile(item: item),
            GuardLevelCopySchedulesFromExistListTile(item: item),
            GuardLevelScheduleUpdateTypeListTile(item: item),
            if (homeSchedule != null) ScheduleItemPageTile(schedule: homeSchedule),
            if (lockSchedule != null) ScheduleItemPageTile(schedule: lockSchedule),
            if (bothSchedule != null) ScheduleItemPageTile(schedule: bothSchedule),
            ...widgetSchedulesList.map((e) => ScheduleItemPageTile(schedule: e)),
            GuardLevelActiveListTile(item: item),
          ];
        },
      ),
    );
  }
}
