import 'package:aves/model/fgw/filters_set.dart';
import 'package:aves/model/fgw/guard_level.dart';
import 'package:aves/model/fgw/wallpaper_schedule.dart';
import 'package:aves/widgets/settings/presentation/common/item_page.dart';
import 'package:aves/widgets/settings/presentation/foreground_wallpaper/sections/schedule_section.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class FgwScheduleItemPage extends StatelessWidget {
  static const routeName = '/settings/presentation/fgw_edit_setting/schedule_item_page';

  final FgwScheduleRow item;

  const FgwScheduleItemPage({
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
      child: PresentRowItemPage<FgwScheduleRow>(
        item: item,
        buildTiles: (item) {
          return [
            FgwSchedulesTitleTile(item: item),
            FgwSchedulesLabelNameModifiedTile(item: item),
            FgwScheduleFilterSetTile(item: item),
            FgwSchedulesIntervalTile(item: item),
            FgwDisplayTypeSwitchTile(item: item),
            FgwSchedulesActiveListTile(item: item),
          ];
        },
      ),
    );
  }
}
