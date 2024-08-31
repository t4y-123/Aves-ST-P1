import 'package:aves/model/fgw/enum/fgw_schedule_item.dart';
import 'package:aves/model/fgw/filters_set.dart';
import 'package:aves/model/fgw/wallpaper_schedule.dart';
import 'package:aves/model/presentation/base_bridge_row.dart';
import 'package:aves/theme/format.dart';
import 'package:aves/widgets/common/action_mixins/feedback.dart';
import 'package:aves/widgets/common/extensions/build_context.dart';
import 'package:aves/widgets/dialogs/big_duration_dialog.dart';
import 'package:aves/widgets/settings/common/item_tiles.dart';
import 'package:aves/widgets/settings/presentation/foreground_wallpaper/schedule/schedule_collection_tile.dart';
import 'package:aves/widgets/settings/settings_definition.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class FgwSchedulesTitleTile extends SettingsTile {
  @override
  String title(BuildContext context) => '${context.l10n.settingsScheduleNamePrefix} ${item.orderNum}';

  final FgwScheduleRow item;

  FgwSchedulesTitleTile({
    required this.item,
  });

  @override
  Widget build(BuildContext context) => ItemInfoListTile<FgwSchedule>(
        tileTitle: title(context),
        selector: (context, levels) {
          debugPrint('$runtimeType FgwSchedulesLabelNameModifiedTile\n'
              'item: $item \n'
              'rows ${levels.all} \n'
              'bridges ${levels.bridgeAll}\n');
          return ('id:${item.id}');
        },
      );
}

class FgwSchedulesLabelNameModifiedTile extends SettingsTile {
  @override
  String title(BuildContext context) => context.l10n.renameLabelNameTileTitle;
  final FgwScheduleRow item;

  FgwSchedulesLabelNameModifiedTile({
    required this.item,
  });

  @override
  Widget build(BuildContext context) => ItemSettingsLabelNameListTile<FgwSchedule>(
        tileTitle: title(context),
        selector: (context, levels) {
          debugPrint('$runtimeType FgwSchedulesLabelNameModifiedTile\n'
              'item: $item \n'
              'rows ${levels.all} \n'
              'bridges ${levels.bridgeAll}\n');
          final row = levels.bridgeAll.firstWhereOrNull((e) => e.id == item.id);
          if (row != null) {
            return row.labelName;
          } else {
            return 'Error';
          }
        },
        onChanged: (value) {
          debugPrint('$runtimeType FgwSchedulesSectionBaseSection\n'
              'row.labelName ${item.labelName} \n'
              'to value $value\n');
          final newRow = item.copyWith(labelName: value);
          fgwSchedules.setRows({newRow}, type: PresentationRowType.bridgeAll);
        },
      );
}

class FgwScheduleFilterSetTile extends SettingsTile {
  @override
  String title(BuildContext context) => '${context.l10n.filterSetNamePrefix}:';

  final FgwScheduleRow item;

  FgwScheduleFilterSetTile({
    required this.item,
  });

  @override
  Widget build(BuildContext context) => Selector<FgwSchedule, Set<FiltersSetRow>>(
        selector: (context, s) {
          final curSchedule = s.bridgeAll.firstWhere((e) => e.id == item.id);

          final selectedFiltersSet = filtersSets.bridgeAll.firstWhere((e) => e.id == curSchedule.filtersSetId);
          return {selectedFiltersSet};
        },
        builder: (context, current, child) {
          return ScheduleCollectionTile(
            selectedFilterSet: current,
            onSelection: (v) async {
              final curFilterSetRow = v.first;
              final newRow = item.copyWith(filtersSetId: curFilterSetRow.id);
              await fgwSchedules.setRows({newRow}, type: PresentationRowType.bridgeAll);
            },
            title: current.first.id.toString(),
          );
        },
      );
}

class FgwSchedulesIntervalTile extends SettingsTile {
  @override
  String title(BuildContext context) => context.l10n.settingsActiveTitle;

  final FgwScheduleRow item;

  FgwSchedulesIntervalTile({
    required this.item,
  });

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
              final newRow = schedule.copyWith(interval: 0);
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
      final newRow = schedule.copyWith(interval: v);
      await fgwSchedules.setRows({newRow}, type: PresentationRowType.bridgeAll);
    }
  }
}

class FgwDisplayTypeSwitchTile extends SettingsTile with FeedbackMixin {
  @override
  String title(BuildContext context) => context.l10n.fgwDisplayType;
  final FgwScheduleRow item;

  FgwDisplayTypeSwitchTile({
    required this.item,
  });

  @override
  Widget build(BuildContext context) => ItemSettingsSelectionListTile<FgwSchedule, FgwDisplayedType>(
        values: FgwDisplayedType.values,
        getName: (context, v) => v.getName(context),
        selector: (context, s) => s.bridgeAll.firstWhereOrNull((e) => e.id == item.id)?.displayType ?? item.displayType,
        onSelection: (v) async {
          final newRow = item.copyWith(displayType: v);
          await fgwSchedules.setRows({newRow}, type: PresentationRowType.bridgeAll);
        },
        tileTitle: title(context),
        dialogTitle: context.l10n.fgwDisplayType,
      );
}

class FgwSchedulesActiveListTile extends SettingsTile {
  @override
  String title(BuildContext context) => context.l10n.settingsActiveTitle;

  final FgwScheduleRow item;

  FgwSchedulesActiveListTile({
    required this.item,
  });

  @override
  Widget build(BuildContext context) => ItemSettingsSwitchListTile<FgwSchedule>(
        selector: (context, s) => s.bridgeAll.firstWhere((e) => e.id == item.id).isActive,
        onChanged: (v) async {
          final schedule = fgwSchedules.bridgeAll.firstWhere((e) => e.id == item.id);
          final newRow = schedule.copyWith(isActive: v);
          await fgwSchedules.setRows({newRow}, type: PresentationRowType.bridgeAll);
        },
        title: title(context),
      );
}
