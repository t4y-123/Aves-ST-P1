import 'package:aves/model/foreground_wallpaper/privacy_guard_level.dart';
import 'package:aves/widgets/common/basic/scaffold.dart';
import 'package:aves/widgets/common/extensions/build_context.dart';
import 'package:aves/widgets/settings/presentation/foreground_wallpaper/schedule/select_filter_set_page.dart';
import 'package:aves/widgets/settings/presentation/foreground_wallpaper/schedule/select_privcy_guard_level_page.dart';
import 'package:flutter/material.dart';
import '../../../../../model/foreground_wallpaper/enum/fgw_schedule_item.dart';
import '../../../../../model/foreground_wallpaper/filtersSet.dart';
import '../../../../../model/foreground_wallpaper/wallpaper_schedule.dart';
import '../../../../collection/filter_bar.dart';
import '../../../../common/action_mixins/feedback.dart';
import '../../../../common/identity/buttons/outlined_button.dart';
import '../../../../dialogs/big_duration_dialog.dart';

class WallpaperScheduleConfigPage extends StatefulWidget {
  static const routeName = '/settings/classified/wallpaper_schedule_config';
  final WallpaperScheduleRow? item;
  final List<WallpaperScheduleRow?> allItems;
  final Set<WallpaperScheduleRow?> activeItems;

  const WallpaperScheduleConfigPage({
    super.key,
    this.item,
    required this.allItems,
    required this.activeItems,
  });

  @override
  State<WallpaperScheduleConfigPage> createState() =>
      _WallpaperScheduleConfigPageState();
}

class _WallpaperScheduleConfigPageState
    extends State<WallpaperScheduleConfigPage> with FeedbackMixin {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _aliasNameController;
  bool _isActive = false;
  late WallpaperScheduleRow? _currentItem;

  late Set<PrivacyGuardLevelRow> _selectedPrivacyGuardLevels;
  late Set<FiltersSetRow> _selectedFilterSet;

  late Set<WallpaperUpdateType> _currentUpdateTypes;

  late bool _useInterval;
  late int _curInterval;
  late String _curIntervalString;
  late bool _IsWidgetSchdeule;
  late int _curWidgetID;

  @override
  void initState() {
    super.initState();
    final int newNum = _generateNewNum();
    final int newId = _generateUniqueId();
    _currentItem = widget.item;
    // _currentItem = widget.item ??
    //     WallpaperScheduleRow(
    //       id: newId,
    //       scheduleNum: newNum,
    //       scheduleName: 'S$newNum Id:$newId',
    //       isActive: true,
    //     );
    _aliasNameController =
        TextEditingController(text: _currentItem!.labelName);
    _isActive = _currentItem!.isActive;

    //Get schedule details, if exist.
    if (widget.item != null) {
      final int scheduleId = _currentItem!.id;
      final firstScheduleDetail = wallpaperSchedules.all
          .firstWhere((e) => e.id == scheduleId);

      // _currentUpdateTypes = firstScheduleDetail.updateType;
      // if (_currentUpdateTypes.contains(WallpaperUpdateType.widget)) {
      //   _IsWidgetSchdeule = true;
      // }
      _curWidgetID = firstScheduleDetail.widgetId;
      // Filter the WallpaperScheduleDetailRow objects by scheduleId
      final relevantDetails = wallpaperSchedules.all
          .where((detail) => detail.id == scheduleId)
          .toSet();
      // Extract the privacyGuardLevelIds from the filtered details
      final privacyGuardLevelIds =
          relevantDetails.map((detail) => detail.privacyGuardLevelId).toSet();
      // Filter the PrivacyGuardLevelRow objects based on the extracted privacyGuardLevelIds
      _selectedPrivacyGuardLevels = privacyGuardLevels.all
          .where(
              (row) => privacyGuardLevelIds.contains(row.privacyGuardLevelID))
          .toSet();

      final ids =
          relevantDetails.map((detail) => detail.filtersSetId).toSet();
      // Filter the PrivacyGuardLevelRow objects based on the extracted privacyGuardLevelIds
      _selectedFilterSet = filtersSets.all
          .where((row) => ids.contains(row.id))
          .toSet();

      _curInterval = firstScheduleDetail.interval >= 3
          ? firstScheduleDetail.interval
          : 0;
      _useInterval = _curInterval >= 3 ? true : false;
    } else {
      _currentUpdateTypes = {WallpaperUpdateType.home};
      _selectedPrivacyGuardLevels = {
        privacyGuardLevels.all.firstWhere((e) => e.isActive)
      };
      _selectedFilterSet = {filtersSets.all.firstWhere((e) => e.isActive)};
      _IsWidgetSchdeule = false;
      _useInterval = false;
      _curWidgetID = 0;
      _curInterval = 0;
    }
    _curIntervalString = '';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AvesScaffold(
      appBar: AppBar(
        title: Text(l10n.settingsConfirmationDialogTitle),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Text('ID: ${_currentItem?.id ?? ''}'),
                  Text('Sequence Number: ${_currentItem?.orderNum ?? ''}'),
                ],
              ),
              const Divider(height: 32),
              TextFormField(
                controller: _aliasNameController,
                decoration: const InputDecoration(
                  labelText: 'Alias Name',
                  labelStyle: TextStyle(
                    fontSize: 20,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an alias name';
                  }
                  return null;
                },
              ),
              _buildPrivacyGuardLevelSelectTile(),
              const SizedBox(height: 8),
              _buildFilterSetListTile(),
              const Divider(height: 28),
              Column(children: _buildUpdateType()),
              const Text(
                'Interval:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Column(children: _buildIntervalOptions()),
              const Divider(height: 16),
              SwitchListTile(
                title: const Text('Active'),
                value: _isActive,
                onChanged: (value) {
                  setState(() {
                    _isActive = value;
                  });
                },
              ),
              const Divider(height: 32),
              AvesOutlinedButton(
                onPressed: _applyChanges,
                label:
                    context.l10n.settingsForegroundWallpaperConfigApplyChanges,
              ),
            ],
          ),
        ),
      ),
    );
  }

  int _generateUniqueId() {
    int id = 1;
    while (wallpaperSchedules.all.any((item) => item.id == id)) {
      id++;
    }
    return id;
  }

  int _generateNewNum() {
    // final activeItems = widget.allItems.where((item) => item?.isActive ?? false).toList();
    final int maxNow = widget.allItems
        .where((item) => widget.activeItems.contains(item))
        .length;
    return maxNow + 1;
  }

  void _applyChanges() async {
    // if (_formKey.currentState?.validate() ?? false) {
    //  final updatedItem = WallpaperScheduleRow(
    //    id: _currentItem!.id,
    //    scheduleNum: _currentItem!.scheduleNum,
    //    aliasName: _aliasNameController.text,
    //    isActive: _isActive,
    //  );
      //
      // await wallpaperSchedules.setRows({updatedItem});
      //
      // //generate details for each privacy level
      // await wallpaperScheduleDetails.removeEntries(wallpaperScheduleDetails.all
      //     .where((row) => row.wallpaperScheduleId == updatedItem.id)
      //     .toSet());
      // if(!_useInterval)(_curInterval = 0);
      // for (var privacyGuardLevelRow in _selectedPrivacyGuardLevels) {
      //   final detailRow = WallpaperScheduleDetailRow(
      //     wallpaperScheduleDetailId: _generateDetailUniqueId(),
      //     wallpaperScheduleId: updatedItem.id,
      //     id: _selectedFilterSet.first.id,
      //     privacyGuardLevelId: privacyGuardLevelRow.privacyGuardLevelID,
      //     updateType: _currentUpdateTypes,
      //     // Simplified for the example
      //     widgetId: _curWidgetID,
      //     intervalTime: _curInterval,
      //   );
      //   await wallpaperScheduleDetails.add({detailRow});
      // }

      Navigator.pop(context, widget.activeItems.first); // Return the updated item
    // }
  }

  void _toggleUpdateType(WallpaperUpdateType type) {
    setState(() {
      // if (_currentUpdateTypes.contains(type)) {
      //   if (_currentUpdateTypes.length > 1) {
      //     _currentUpdateTypes.remove(type);
      //   }else{
      //     showFeedback(context, FeedbackType.warn,context.l10n.settingsWallpaperScheduleUpdateTypeAtLeastOneFeedback );
      //   }
      // } else {
      //   _currentUpdateTypes.add(type);
      // }
    });
  }

  Widget _buildUpdateTypeButton(WallpaperUpdateType type, String label) {
    final isSelected = _currentUpdateTypes.contains(type);
    return ElevatedButton(
      onPressed: () {
        _toggleUpdateType(type);
      },
      style: ElevatedButton.styleFrom(
        foregroundColor: isSelected ? Colors.white : Colors.black,
        backgroundColor: isSelected ? Colors.blue : Colors.grey[300],
        side:
            BorderSide(color: isSelected ? Colors.blue : Colors.grey, width: 2),
        elevation: isSelected ? 5 : 0,
      ),
      child: Text(
        label,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  String _makeIntervalString(int inInterval) {
    final int _hours = inInterval ~/ Duration.secondsPerHour;
    final int _minutes = (inInterval - _hours * Duration.secondsPerHour) ~/
        Duration.secondsPerMinute;
    final int _seconds = inInterval % Duration.secondsPerMinute;

    List<String> parts = [];
    if (_hours > 0) {
      parts.add('$_hours ${context.l10n.durationDialogHours}');
    }
    if (_minutes > 0) {
      parts.add('$_minutes ${context.l10n.durationDialogMinutes}');
    }
    if (_seconds > 0) {
      parts.add('$_seconds ${context.l10n.durationDialogSeconds}');
    }
    return parts.join('\n');
  }

  Future<void> _buildInterval() async {
    final v = await showDialog<int>(
      context: context,
      builder: (context) => HmsDurationDialog(initialSeconds: _curInterval),
    );
    if (v != null) {
      setState(() {
        _curInterval = v;
        _useInterval = true;
        _curIntervalString = _makeIntervalString(_curInterval);
      });
    }
  }

  List<Widget> _buildIntervalOptions() {
    final l10n = context.l10n;
    _curIntervalString = _makeIntervalString(_curInterval);
    return [false, true].map(
      (isCustom) {
        final title = Text(
          isCustom
              ? l10n.settingsWallpaperUpdateFixedInterval
              : l10n.settingsWallpaperUpdateEveryTimeUnlock,
          softWrap: true,
          overflow: TextOverflow.fade,
          maxLines: 3, // Adjust as needed
        );
        return RadioListTile<bool>(
          value: isCustom,
          groupValue: _useInterval,
          onChanged: (v) {
            if (v == null) return;
            if (v) {
              _buildInterval();
              return;
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
                            onTap: _buildInterval,
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

  List<Widget> _buildUpdateType() {
    if (!_currentUpdateTypes.contains(WallpaperUpdateType.widget)) {
      return [
        const Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Update Types:',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildUpdateTypeButton(WallpaperUpdateType.home, 'HOME'),
            _buildUpdateTypeButton(WallpaperUpdateType.lock, 'LOCK'),
          ],
        ),
      ];
    } else {
      return [
        const Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Update Types: Widget',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ];
    }
  }

  Widget _buildPrivacyGuardLevelSelectTile() {
    return ListTile(
      title: Text(
          'Privacy Guard Levels: ${_selectedPrivacyGuardLevels.map((e) => e.guardLevel).join(', ')}'),
      trailing: ElevatedButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PrivacyGuardLevelSelectionPage(
                selectedPrivacyGuardLevels: _selectedPrivacyGuardLevels,
              ),
            ),
          );
          if (result != null) {
            setState(() {
              _selectedPrivacyGuardLevels = result;
            });
          }
        },
        child: const Text('Select'),
      ),
    );
  }

  Widget _buildFilterSetListTile() {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final hasSubtitle = _selectedFilterSet.first.filters!.isEmpty;

    return ConstrainedBox(
      constraints: BoxConstraints(
        minHeight: (hasSubtitle ? 72.0 : 56.0) +
            Theme.of(context).visualDensity.baseSizeAdjustment.dy,
      ),
      child: Center(
        child: Column(
          children: [
            ListTile(
              title: Text(
                  'Filter Set: ${_selectedFilterSet.first.id ?? 'None'}'),
              trailing: ElevatedButton(
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => FilterSetSelectionPage(
                        selectedFilterSet: _selectedFilterSet,
                      ),
                    ),
                  );
                  if (result != null) {
                    setState(() {
                      _selectedFilterSet.clear();
                      _selectedFilterSet.addAll(result);
                    });
                  }
                },
                child: const Text('Select'),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.settingsCollectionTile,
                        style: textTheme.titleMedium!,
                      ),
                      if (hasSubtitle)
                        Text(
                          l10n.drawerCollectionAll,
                          style: textTheme.bodyMedium!.copyWith(
                              color: theme.colorScheme.onSurfaceVariant),
                        ),
                    ],
                  ),
                  const Spacer(),
                ],
              ),
            ),
            if (hasSubtitle) const Divider(height: 36),
            //TODO: t4y. why the FilterBar will be overlay ?
            FilterBar(
              filters: _selectedFilterSet.first.filters!,
              interactive: false,
            ),
          ],
        ),
      ),
    );
  }
}
