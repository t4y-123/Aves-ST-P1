import 'package:aves/model/fgw/enum/fgw_schedule_item.dart';
import 'package:aves/model/fgw/filters_set.dart';
import 'package:aves/model/fgw/guard_level.dart';
import 'package:aves/model/fgw/wallpaper_schedule.dart';
import 'package:aves/model/presentation/base_bridge_row.dart';
import 'package:aves/widgets/common/extensions/build_context.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../../theme/format.dart';
import '../../../../common/action_mixins/feedback.dart';
import '../../../../dialogs/big_duration_dialog.dart';
import '../../../common/item_tiles.dart';
import '../../../settings_definition.dart';
import '../schedule/schedule_collection_tile.dart';

class GuardLevelScheduleSubPage extends StatefulWidget {
  static const routeName = '/settings/presentation/guard_level_setting_page/gl_schedule_sub_page';
  final FgwGuardLevelRow item;
  final FgwScheduleRow schedule;

  const GuardLevelScheduleSubPage({
    super.key,
    required this.item,
    required this.schedule,
  });

  @override
  State<GuardLevelScheduleSubPage> createState() => _GuardLevelScheduleSubPageState();
}

class _GuardLevelScheduleSubPageState extends State<GuardLevelScheduleSubPage> with FeedbackMixin {
  @override
  void initState() {
    super.initState();
    debugPrint('_GuardLevelScheduleSubPageState in context: $context');

    // If _currentUpdateTypes is empty, do nothing.
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
        appBar: AppBar(
          title: Text(l10n.settingsWallpaperScheduleTabTypes),
        ),
        body: MultiProvider(
          providers: [
            ChangeNotifierProvider<GuardLevel>.value(value: fgwGuardLevels),
            ChangeNotifierProvider<FgwSchedule>.value(value: fgwSchedules),
            ChangeNotifierProvider<FiltersSet>.value(value: filtersSets),
          ],
          child: SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                Text('ID: ${widget.schedule.id}'),
                const Divider(height: 16),
                ScheduleLabelNameModifiedTile(schedule: widget.schedule).build(context),
                const Divider(height: 16),
                buildFilterSetTile(),
                const Divider(
                  height: 16,
                ),
                _buildIntervalSelectTile(widget.schedule),
                const Divider(
                  height: 16,
                ),
                ScheduleDisplayTypeSwitchTile(schedule: widget.schedule).build(context),
                const Divider(
                  height: 16,
                ),
                ItemSettingsSwitchListTile<FgwSchedule>(
                  selector: (context, s) =>
                      (s.bridgeAll.firstWhereOrNull((e) => e.id == widget.schedule.id) ?? widget.schedule).isActive,
                  onChanged: (v) async {
                    final curSchedule =
                        fgwSchedules.bridgeAll.firstWhereOrNull((e) => e.id == widget.schedule.id) ?? widget.schedule;
                    await fgwSchedules.setExistRows({curSchedule}, {FgwScheduleRow.propIsActive: v},
                        type: PresentationRowType.bridgeAll);
                  },
                  title: l10n.settingsScheduleIsActiveTitle,
                ),
                const Divider(
                  height: 16,
                ),
                // Row(
                //   mainAxisAlignment: MainAxisAlignment.spaceAround,
                //   children: [
                //     AvesOutlinedButton(
                //       onPressed: _applyChanges,
                //       label: context.l10n.settingsForegroundWallpaperConfigApplyChanges,
                //     ),
                //   ],
                // ),
              ],
            ),
          ),
        ));
  }

  Widget _buildIntervalSelectTile(FgwScheduleRow schedule) {
    return Selector<FgwSchedule, FgwScheduleRow>(selector: (context, s) {
      final curSchedule = fgwSchedules.bridgeAll.firstWhere((e) => e.id == widget.schedule.id);
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
          Column(children: _buildIntervalOptions(current)),
        ],
      );
    });
  }

  List<Widget> _buildIntervalOptions(FgwScheduleRow schedule) {
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
              await _buildInterval(schedule);
              return;
            } else {
              await fgwSchedules
                  .setExistRows({schedule}, {FgwScheduleRow.propInterval: 0}, type: PresentationRowType.bridgeAll);
            }
            _useInterval = v;
            setState(() {});
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
                              _buildInterval(schedule);
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

  Future<void> _buildInterval(FgwScheduleRow schedule) async {
    final v = await showDialog<int>(
      context: context,
      builder: (context) => HmsDurationDialog(initialSeconds: schedule.interval),
    );
    if (v != null) {
      await fgwSchedules
          .setExistRows({schedule}, {FgwScheduleRow.propInterval: v}, type: PresentationRowType.bridgeAll);
    }
  }

  Selector<FgwSchedule, Set<FiltersSetRow>> buildFilterSetTile() {
    return Selector<FgwSchedule, Set<FiltersSetRow>>(
      selector: (context, s) {
        final curSchedule = s.bridgeAll.firstWhere((e) => e.id == widget.schedule.id);

        final selectedFiltersSet = filtersSets.bridgeAll.firstWhere((e) => e.id == curSchedule.filtersSetId);
        return {selectedFiltersSet};
      },
      builder: (context, current, child) {
        return ScheduleCollectionTile(
          selectedFilterSet: current,
          onSelection: (v) {
            final curFilterSetRow = v.first;
            fgwSchedules.setExistRows({widget.schedule}, {FgwScheduleRow.propFiltersSetId: curFilterSetRow.id},
                type: PresentationRowType.bridgeAll);
          },
          title: current.first.id.toString(),
        );
      },
    );
  }
}

class ScheduleLabelNameModifiedTile extends SettingsTile {
  @override
  String title(BuildContext context) => context.l10n.renameLabelNameTileTitle;
  final FgwScheduleRow schedule;

  ScheduleLabelNameModifiedTile({
    required this.schedule,
  });

  @override
  Widget build(BuildContext context) => ItemSettingsLabelNameListTile<FgwSchedule>(
        tileTitle: title(context),
        selector: (context, levels) {
          debugPrint('$runtimeType GuardLevelLabelNameModifiedTile\n'
              'item: $schedule \n'
              'rows ${levels.all} \n'
              'bridges ${levels.bridgeAll}\n');
          final row = levels.bridgeAll.firstWhereOrNull((e) => e.id == schedule.id);
          if (row != null) {
            return row.labelName;
          } else {
            return 'Error';
          }
        },
        onChanged: (value) {
          debugPrint('$runtimeType GuardLevelSectionBaseSection\n'
              'row.labelName ${schedule.labelName} \n'
              'to value $value\n');
          // if(wallpaperSchedules.bridgeAll.map((e)=> e.id).contains(schedule.id)){
          fgwSchedules
              .setExistRows({schedule}, {FgwScheduleRow.propLabelName: value}, type: PresentationRowType.bridgeAll);
          // };
        },
      );
}

class ScheduleDisplayTypeSwitchTile extends SettingsTile with FeedbackMixin {
  @override
  String title(BuildContext context) => context.l10n.fgwDisplayType;
  final FgwScheduleRow schedule;

  ScheduleDisplayTypeSwitchTile({
    required this.schedule,
  });

  @override
  Widget build(BuildContext context) => ItemSettingsSelectionListTile<FgwSchedule, FgwDisplayedType>(
        values: FgwDisplayedType.values,
        getName: (context, v) => v.getName(context),
        selector: (context, s) =>
            s.bridgeAll.firstWhereOrNull((e) => e.id == schedule.id)?.displayType ?? schedule.displayType,
        onSelection: (v) async {
          debugPrint('$runtimeType ScheduleDisplayTypeSwitchTile\n'
              'ItemSettingsSelectionListTile onSelection v :$schedule \n');
          final curSchedule = fgwSchedules.bridgeAll.firstWhereOrNull((e) => e.id == schedule.id) ?? schedule;
          await fgwSchedules
              .setExistRows({curSchedule}, {FgwScheduleRow.propDisplayType: v}, type: PresentationRowType.bridgeAll);
          // t4y:TODO：　after copy, reset all related schedules.
        },
        tileTitle: title(context),
        dialogTitle: context.l10n.fgwDisplayType,
      );
}
