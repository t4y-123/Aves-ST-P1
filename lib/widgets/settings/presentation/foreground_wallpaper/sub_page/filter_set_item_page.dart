import 'package:aves/model/fgw/filters_set.dart';
import 'package:aves/model/fgw/guard_level.dart';
import 'package:aves/model/fgw/wallpaper_schedule.dart';
import 'package:aves/widgets/settings/presentation/common/item_page.dart';
import 'package:aves/widgets/settings/presentation/foreground_wallpaper/sections/filter_set_section.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class FiltersSetItemPage extends StatelessWidget {
  static const routeName = '/settings/presentation/fgw_edit_setting/scheduleitem_page';

  final FiltersSetRow item;

  const FiltersSetItemPage({
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
      child: PresentRowItemPage<FiltersSetRow>(
        item: item,
        buildTiles: (item) {
          return [
            FiltersSetTitleTile(item: item),
            FiltersSetLabelNameModifiedTile(item: item),
            FiltersCollectionTile(item: item),
            FiltersSetActiveListTile(item: item),
          ];
        },
      ),
    );
  }
}
