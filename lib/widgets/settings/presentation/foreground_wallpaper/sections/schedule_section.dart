import 'package:aves/model/fgw/enum/fgw_schedule_item.dart';
import 'package:aves/model/fgw/wallpaper_schedule.dart';
import 'package:aves/model/presentation/base_bridge_row.dart';
import 'package:aves/theme/format.dart';
import 'package:aves/widgets/common/action_mixins/feedback.dart';
import 'package:aves/widgets/common/extensions/build_context.dart';
import 'package:aves/widgets/dialogs/big_duration_dialog.dart';
import 'package:aves/widgets/settings/common/item_tiles.dart';
import 'package:aves/widgets/settings/presentation/common/section.dart';
import 'package:aves/widgets/settings/presentation/foreground_wallpaper/sections/schedule_collection_tile.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class FgwScheduleFilterSetTile extends ItemSettingsTile<FgwScheduleRow> {
  @override
  String title(BuildContext context) => '${context.l10n.filterSetNamePrefix}:';

  FgwScheduleFilterSetTile({required super.item});

  @override
  Widget build(BuildContext context) => Selector<FgwSchedule, FgwScheduleRow>(
        selector: (context, s) => s.bridgeAll.firstWhere((e) => e.id == item.id),
        builder: (context, current, child) {
          return ScheduleFilterSetTile(
            item: current,
            title: current.filtersSetId.toString(),
          );
        },
      );
}

class FgwSchedulesIntervalTile extends ItemSettingsTile<FgwScheduleRow> {
  @override
  String title(BuildContext context) => context.l10n.settingsActiveTitle;

  FgwSchedulesIntervalTile({required super.item});

  @override
  Widget build(BuildContext context) => _buildIntervalSelectTile(context, item);

  Widget _buildIntervalSelectTile(BuildContext context, FgwScheduleRow schedule) {
    return Selector<FgwSchedule, FgwScheduleRow>(selector: (context, s) {
      final curSchedule = fgwSchedules.bridgeAll.firstWhere((e) => e.id == item.id);
      debugPrint('$runtimeType  _buildIntervalSelectTile curSchedule $curSchedule');
      return curSchedule;
    }, builder: (context, current, child) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.settingsScheduleIntervalTile,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          Text(
            context.l10n.settingsScheduleIntervalFixedIntervalInfo,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.normal),
          ),
          Column(children: _buildIntervalOptions(context, current)),
        ],
      );
    });
  }

  List<Widget> _buildIntervalOptions(BuildContext context, FgwScheduleRow schedule) {
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
              await _buildInterval(context, schedule);
              return;
            } else {
              final newRow = fgwSchedules.bridgeAll.firstWhere((e) => e.id == item.id).copyWith(interval: 0);
              await fgwSchedules.setRows({newRow}, type: PresentationRowType.bridgeAll);
            }
            _useInterval = v;
            //setState(() {});
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
                              _buildInterval(context, schedule);
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

  Future<void> _buildInterval(BuildContext context, FgwScheduleRow schedule) async {
    final v = await showDialog<int>(
      context: context,
      builder: (context) => HmsDurationDialog(initialSeconds: schedule.interval),
    );
    if (v != null) {
      final newRow = fgwSchedules.bridgeAll.firstWhere((e) => e.id == item.id).copyWith(interval: v);
      await fgwSchedules.setRows({newRow}, type: PresentationRowType.bridgeAll);
    }
  }
}

class FgwDisplayTypeSwitchTile extends ItemSettingsTile<FgwScheduleRow> with FeedbackMixin {
  @override
  String title(BuildContext context) => context.l10n.fgwDisplayType;

  FgwDisplayTypeSwitchTile({required super.item});

  @override
  Widget build(BuildContext context) => ItemSettingsSelectionListTile<FgwSchedule, FgwDisplayedType>(
        values: FgwDisplayedType.values,
        getName: (context, v) => v.getName(context),
        selector: (context, s) => s.bridgeAll.firstWhereOrNull((e) => e.id == item.id)?.displayType ?? item.displayType,
        onSelection: (v) async {
          final newRow = fgwSchedules.bridgeAll.firstWhere((e) => e.id == item.id).copyWith(displayType: v);
          await fgwSchedules.setRows({newRow}, type: PresentationRowType.bridgeAll);
        },
        tileTitle: title(context),
        dialogTitle: context.l10n.fgwDisplayType,
      );
}
