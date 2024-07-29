import 'dart:async';

import 'package:aves/model/foreground_wallpaper/privacy_guard_level.dart';
import 'package:aves/model/foreground_wallpaper/wallpaper_schedule.dart';
import 'package:aves/widgets/common/extensions/build_context.dart';
import 'package:aves/widgets/settings/common/item_tiles.dart';

import 'package:aves/widgets/settings/settings_definition.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../../theme/format.dart';
import '../../../../dialogs/big_duration_dialog.dart';
import '../../../navigation/navigation.dart';
import '../common/item_settings_definition.dart';
import '../guard_level/guard_level_schedules_sub_page.dart';


class GuardLevelScheduleItemSection extends ItemSettingsSection {
  static const routeName = '/settings/presentation/guard_level_setting_page/gl_schedule_sub_page';
  final PrivacyGuardLevelRow item;
  final WallpaperScheduleRow schedule;

  GuardLevelScheduleItemSection({
    required this.item,
    required this.schedule,
  });

  @override
  String get key => 'guard_level_schedule_sub_page_${schedule.id}';

  @override
  Widget icon(BuildContext context) {
    return const Icon(Icons.schedule);
  }

  @override
  String title(BuildContext context) {
    return 'Guard Level Schedule';
  }

  @override
  FutureOr<List<SettingsTile>> tiles(BuildContext context) => [
    ScheduleInfoTile(schedule: schedule),
    SettingsTileNavigationHomePage(),
    ScheduleLabelNameModifiedTile(schedule: schedule),
    ScheduleFiltersSetSettingTile(schedule: schedule),
  ];
}

class ScheduleInfoTile extends SettingsTile {
  @override
  String title(BuildContext context) =>'${context.l10n.settingsScheduleNamePrefix}${schedule.labelName}';

  final WallpaperScheduleRow schedule;


  ScheduleInfoTile({
    required this.schedule,
  });

  @override
  Widget build(BuildContext context) => ItemInfoListTile<WallpaperSchedules>(
    tileTitle: title(context),
    selector: (context, levels) {
      debugPrint('$runtimeType GuardLevelLabelNameModifiedTile\n');
      return ('id:${schedule.id}');
    },
  );
}

class ScheduleFiltersSetSettingTile extends SettingsTile {
  @override
  String title(BuildContext context) => context.l10n.settingsGuardLevelColor;
  final WallpaperScheduleRow schedule;

  ScheduleFiltersSetSettingTile({
    required this.schedule,
  });

  @override
  Widget build(BuildContext context) => Selector<WallpaperSchedules, WallpaperScheduleRow>(selector: (context, s) {
    final curSchedule = wallpaperSchedules.bridgeAll.firstWhereOrNull((e) => e.id == schedule.id);
    debugPrint('GuardLevelScheduleSubPage in context: $context');
    debugPrint('$runtimeType ScheduleFiltersSetSettingTile Selector curSchedule:$curSchedule');
    return curSchedule ?? schedule;
  }, builder: (context, current, child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 10,thickness: 1),
        Text(
          context.l10n.settingsScheduleIntervalTile,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        Column(children: _buildIntervalOptions(context,current)),
      ],
    );
  });

  List<Widget> _buildIntervalOptions(BuildContext context,WallpaperScheduleRow schedule) {
    final l10n = context.l10n;
    String _curIntervalString = formatToLocalDuration(context, Duration(seconds: schedule.interval));
    var _useInterval = schedule.interval == 0 ? false : true;
    return [false, true].map(
          (isCustom) {
        final title = Text(
          isCustom ? l10n.settingsWallpaperUpdateFixedInterval : l10n.settingsWallpaperUpdateEveryTimeUnlock,
          softWrap: true,
          overflow: TextOverflow.fade,
          maxLines: 3, // Adjust as needed
        );
        return RadioListTile<bool>(
          value: isCustom,
          groupValue: _useInterval,
          onChanged: (v) async {
            if (v == null) return;
            if (v) {
              await _buildInterval(context,schedule);
              return;
            }else{
              await wallpaperSchedules
                  .setExistRows({schedule}, {WallpaperScheduleRow.propInterval: 0}, type: ScheduleRowType.bridgeAll);
            }
            _useInterval = v;
          },
          title: isCustom
              ? LayoutBuilder(
            builder: (context, constraints) {
              return Row(
                children: [
                  Expanded(child: title),
                  // Wrap title in Expanded to make it flexible
                  const Spacer(),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        _buildInterval(context,schedule);
                      },
                      child: (Text(_curIntervalString, maxLines: 3)),
                    ),
                  ),
                ],
              );
            },
          )
              : title,
        );
      },
    ).toList();
  }

  Future<void> _buildInterval(BuildContext context,WallpaperScheduleRow schedule) async {
    debugPrint('$runtimeType _buildInterval schedule: $schedule\n schedule.interval:${schedule.interval}');
    final int curInterval = schedule.interval;
    debugPrint('$runtimeType _buildInterval schedule: $schedule\n'
        ' schedule.interval:${schedule.interval}\n'
        'curInterval: $curInterval');
    final v = await showDialog<int>(
      context: context,
      builder: (context) => HmsDurationDialog(initialSeconds: curInterval),
    );
    if (v != null) {
      await wallpaperSchedules
          .setExistRows({schedule}, {WallpaperScheduleRow.propInterval: v}, type: ScheduleRowType.bridgeAll);
    }
  }

}
