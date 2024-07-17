import 'package:aves/model/foreground_wallpaper/privacy_guard_level.dart';
import 'package:aves/widgets/common/extensions/build_context.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import '../../../../../model/foreground_wallpaper/filtersSet.dart';
import '../../../../../model/foreground_wallpaper/wallpaper_schedule.dart';
import '../../../../../model/settings/settings.dart';
import '../../../../../services/common/services.dart';
import '../../../../../theme/format.dart';
import '../../../../common/action_mixins/feedback.dart';
import '../../../../common/basic/list_tiles/color.dart';
import '../../../../common/identity/buttons/outlined_button.dart';
import '../../../../dialogs/big_duration_dialog.dart';
import '../schedule/generic_selection_page.dart';
import '../schedule/schedule_collection_tile.dart';

class PrivacyGuardLevelWithScheduleConfigPage extends StatefulWidget {
  static const routeName =
      '/settings/classified/privacy_guard_level_with_schedule_config';
  final PrivacyGuardLevelRow? item;
  final List<PrivacyGuardLevelRow?> allItems;
  final Set<PrivacyGuardLevelRow?> activeItems;

  const PrivacyGuardLevelWithScheduleConfigPage({
    super.key,
    required this.item,
    required this.allItems,
    required this.activeItems,
  });

  @override
  State<PrivacyGuardLevelWithScheduleConfigPage> createState() =>
      _PrivacyGuardLevelWithScheduleConfigPageState();
}

class _PrivacyGuardLevelWithScheduleConfigPageState
    extends State<PrivacyGuardLevelWithScheduleConfigPage> with FeedbackMixin {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _aliasNameController;
  Color? _selectedColor;
  bool _isActive = false;
  late PrivacyGuardLevelRow? _currentItem;
  late Set<WallpaperScheduleRow> _templateSchedules;
  late Set<WallpaperScheduleRow> _currentSchedules;
  late Set<WallpaperUpdateType> _currentUpdateTypes;
  late List<Widget> _scheduleSettingTiles;

  @override
  void initState() {
    super.initState();
    final int newLevel = _generateGuardLevel();
    final int newId = metadataDb.nextId;
    // when is not edit but add a new item.
    _currentItem = widget.item ??
        PrivacyGuardLevelRow(
          privacyGuardLevelID: newId,
          guardLevel: newLevel,
          labelName: 'Level $newLevel Id:$newId',
          color: privacyGuardLevels.getRandomColor(),
          // Assign a random color
          isActive: true,
        );
    _aliasNameController = TextEditingController(text: _currentItem!.labelName);
    _selectedColor = _currentItem!.color;
    _isActive = _currentItem!.isActive;

    // Make schedules,
    _scheduleSettingTiles = [];
    // use a template schedule set to store the values when setting,
    // use a current update types to determine which schedule in template schedule will be add to db.
    _templateSchedules = {};
    _currentSchedules = {};
    _currentUpdateTypes = {};
    // If it is an existing item, get all schedules for this guard level
    if (widget.item != null) {
      _setSchedule(_currentItem!);
    } else {
      _templateSchedules.clear();
      _currentUpdateTypes.clear();
      // For a new item, initialize _templateSchedules with default values.
      // widget should be add by default.
      int newScheduleId = 1;
      int newScheduleNum = 1;
      for (var type in WallpaperUpdateType.values) {
        if (type != WallpaperUpdateType.widget) {
          newScheduleId = metadataDb.nextId;
          newScheduleNum = _generateUniqueScheduleNum(newScheduleNum);
          _templateSchedules.add(WallpaperScheduleRow(
            id: newScheduleId++,
            orderNum: newScheduleNum++,
            labelName:
                'L${_currentItem!.guardLevel}_-ID_${_currentItem!.privacyGuardLevelID}-${type.name.toUpperCase()}',
            filtersSetId: filtersSets.all.first.id,
            privacyGuardLevelId: _currentItem!.privacyGuardLevelID,
            updateType: type,
            widgetId: 0,
            interval: type == WallpaperUpdateType.home
                ? settings.defaultNewUpdateInterval
                : 0,
            isActive: _isActive,
          ));
        }
      }
    }
    // If _currentUpdateTypes is empty, do nothing.
  }

  int _generateUniqueScheduleNum(int scheduleNum) {
    while (
        wallpaperSchedules.all.any((row) => row.orderNum == scheduleNum)) {
      scheduleNum++;
    }
    return scheduleNum;
  }

  void _setSchedule(PrivacyGuardLevelRow guardLevel) {
    setState(() {
      _scheduleSettingTiles.clear();
      _currentSchedules.clear();
      _templateSchedules.clear();
      _currentUpdateTypes.clear();

      final int privacyId = guardLevel.privacyGuardLevelID;
      _currentSchedules.addAll(
        wallpaperSchedules.all.where((e) => e.privacyGuardLevelId == privacyId),
      );
      debugPrint(
          '$runtimeType set  WallpaperScheduleRow  _currentSchedules $_currentSchedules');

      int newScheduleId = 1;
      int newScheduleNum = 1;
      // Iterate through all WallpaperUpdateType values
      for (var type in WallpaperUpdateType.values) {
        newScheduleId = metadataDb.nextId;
        newScheduleNum = _generateUniqueScheduleNum(newScheduleNum);
        if (type != WallpaperUpdateType.widget) {
          var existingSchedule = _currentSchedules.firstWhereOrNull(
            (e) => e.updateType == type,
          );
          newScheduleId = metadataDb.nextId;
          newScheduleNum = _generateUniqueScheduleNum(newScheduleNum);
          debugPrint(
              '$runtimeType set $type  WallpaperScheduleRow  existingSchedule $existingSchedule');
          WallpaperScheduleRow scheduleRow;
          if (existingSchedule != null) {
            // If a schedule already exists, create a new one with incremented id and seqnum
            scheduleRow = WallpaperScheduleRow(
              id: (_currentItem!.privacyGuardLevelID == privacyId)
                  ? existingSchedule.id
                  : newScheduleId++,
              // Generate new unique ID
              orderNum: (_currentItem!.privacyGuardLevelID == privacyId)
                  ? existingSchedule.orderNum
                  : newScheduleNum++,
              // Generate new sequence number
              privacyGuardLevelId: _currentItem!.privacyGuardLevelID,
              labelName:
                  'L${_currentItem!.guardLevel}_-ID_${_currentItem!.privacyGuardLevelID}-${type.name.toUpperCase()}',
              filtersSetId: existingSchedule.filtersSetId,
              updateType: existingSchedule.updateType,
              widgetId: existingSchedule.widgetId,
              interval: existingSchedule.interval,
              isActive: _isActive,
            );
            _currentUpdateTypes.add(type); // only exist item need to add type.
          } else {
            newScheduleId = metadataDb.nextId;
            newScheduleNum = _generateUniqueScheduleNum(newScheduleNum);
            // If no existing schedule found, create a completely new one
            scheduleRow = WallpaperScheduleRow(
              id: newScheduleId++,
              // Generate new unique ID
              orderNum: newScheduleNum++,
              // Generate new sequence number
              labelName:
                  'L${_currentItem!.guardLevel}_-ID_${_currentItem!.privacyGuardLevelID}-${type.name.toUpperCase()}',
              filtersSetId: filtersSets.all.first.id,
              privacyGuardLevelId: _currentItem!.privacyGuardLevelID,
              updateType: type,
              widgetId: 0,
              interval: type == WallpaperUpdateType.home
                  ? settings.defaultNewUpdateInterval
                  : 0,
              isActive: _isActive,
            );
          }
          debugPrint(
              '$runtimeType set  WallpaperScheduleRow  scheduleRow $scheduleRow');
          _templateSchedules.add(scheduleRow);
        } else {
          // Handle Widget type schedules
          if (_currentItem!.privacyGuardLevelID == privacyId) {
            _templateSchedules.addAll(_currentSchedules
                .where((e) => e.updateType == WallpaperUpdateType.widget));
            debugPrint('$runtimeType: templateSchedules.addAll  scheduleRow');
          } else {
            //add all widget schdule with new scheduleId and sequence num.
            var widgetSchedules = _currentSchedules
                .where((e) => e.updateType == WallpaperUpdateType.widget)
                .toList();
            for (var widgetSchedule in widgetSchedules) {
              newScheduleId = metadataDb.nextId;
              newScheduleNum = _generateUniqueScheduleNum(newScheduleNum);
              _templateSchedules.add(WallpaperScheduleRow(
                id: newScheduleId++,
                orderNum: newScheduleNum++,
                labelName:
                    'L${_currentItem!.guardLevel}_-ID_${_currentItem!.privacyGuardLevelID}-${WallpaperUpdateType.widget.name.toUpperCase()}',
                filtersSetId: widgetSchedule.filtersSetId,
                privacyGuardLevelId: _currentItem!.privacyGuardLevelID,
                updateType: WallpaperUpdateType.widget,
                widgetId: widgetSchedule.widgetId,
                interval: widgetSchedule.interval,
                isActive: _isActive,
              ));
            }
          }
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settingsPrivacyGuardLevelTabTypes),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              Text('ID: ${widget.item?.privacyGuardLevelID ?? ''}'),
              const SizedBox(height: 8),
              Text('Guard Level: ${widget.item?.guardLevel ?? ''}'),
              const SizedBox(height: 8),
              _buildAliasNameTextFormFieldTile(),
              const SizedBox(height: 8),
              _buildColorTile(),
              const Divider(height: 20),
              _buildPrivacyGuardLevelSelectTile(),
              const SizedBox(height: 8),
              _buildUpdateTypeButtons(),
              const Divider(height: 16),
              _buildScheduleSettings(),
              const SizedBox(height: 16),
              _buildActiveSwitchTile(),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  AvesOutlinedButton(
                    onPressed: _applyChanges,
                    label: context
                        .l10n.settingsForegroundWallpaperConfigApplyChanges,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPrivacyGuardLevelSelectTile() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Text(
          'Schedule:',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const Spacer(),
        AvesOutlinedButton(
          onPressed: () async {
            final Set<PrivacyGuardLevelRow> result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    GenericForegroundWallpaperItemsSelectionPage<
                        PrivacyGuardLevelRow>(
                  selectedItems: {privacyGuardLevels.all.first},
                  maxSelection: 1,
                  allItems:
                      privacyGuardLevels.all.where((e) => e.isActive).toList(),
                  displayString: (item) =>
                      'L${item.guardLevel}: ${item.labelName}',
                  itemId: (item) => item.guardLevel,
                ),
              ),
            );
            setState(() {
              _setSchedule(result.first);
            });
            debugPrint('$runtimeType copied ${result.first}');
                    },
          label: 'Can copy from exist',
        ),
      ],
    );
  }

  int _generateGuardLevel() {
    final int maxLevelNow = widget.allItems
        .where((item) => widget.activeItems.contains(item))
        .length;
    return maxLevelNow + 1;
  }

  void _applyChanges() {
    if (_formKey.currentState?.validate() ?? false) {
      final updatedItem = PrivacyGuardLevelRow(
        privacyGuardLevelID: _currentItem!.privacyGuardLevelID,
        guardLevel: _currentItem!.guardLevel,
        labelName: _aliasNameController.text,
        color: _selectedColor,
        isActive: _isActive,
      );
      Navigator.pop(context, updatedItem); // Return the updated item
    }
    // Add items from _templateSchedules that have WallpaperUpdateType.widget and _currentUpdateTypes to db.
    Set<WallpaperScheduleRow> newRows = {};
    newRows.addAll(_templateSchedules
        .where((row) => row.updateType == WallpaperUpdateType.widget));
    for (var updateType in _currentUpdateTypes) {
      newRows.addAll(
          _templateSchedules.where((row) => row.updateType == updateType));
    }

    wallpaperSchedules.setRows(newRows);
  }

  Widget _buildUpdateTypeButtons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'New Schedule Update Types:',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _buildUpdateTypeButton(WallpaperUpdateType.home, 'Home'),
            _buildUpdateTypeButton(WallpaperUpdateType.lock, 'Lock'),
            _buildUpdateTypeButton(WallpaperUpdateType.both, 'Both'),
          ],
        ),
      ],
    );
  }

  Widget _buildUpdateTypeButton(WallpaperUpdateType type, String label) {
    final isSelected = _currentUpdateTypes.contains(type);
    return ElevatedButton(
      onPressed: () {
        setState(() {
          if (type == WallpaperUpdateType.both) {
            _currentUpdateTypes = {WallpaperUpdateType.both};
          } else {
            if (_currentUpdateTypes.contains(WallpaperUpdateType.both)) {
              _currentUpdateTypes.remove(WallpaperUpdateType.both);
            }
            if (_currentUpdateTypes.contains(type)) {
              _currentUpdateTypes.remove(type);
            } else {
              _currentUpdateTypes.add(type);
            }
            if (_currentUpdateTypes.isEmpty) {
              _currentUpdateTypes.add(type);
              showFeedback(context, FeedbackType.warn,
                  'At least one type should be chosen!');
            }
          }
        });
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

  Widget _buildScheduleSettings() {
    _scheduleSettingTiles.clear();
    for (var schedule in _templateSchedules) {
      if (_currentUpdateTypes.contains(schedule.updateType)) {
        _scheduleSettingTiles.add(_buildSingleScheduleSettingsTile(schedule));
      }
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: _scheduleSettingTiles,
    );
  }

  Widget _buildSingleScheduleSettingsTile(WallpaperScheduleRow schedule) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${schedule.updateType.name} Filter Set: ${schedule.filtersSetId} ',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        _buildFilterSetSelectTile(schedule),
        const SizedBox(height: 8),
        _buildIntervalSelectTile(schedule),
        const Divider(height: 16),
      ],
    );
  }

  Widget _buildFilterSetSelectTile(WallpaperScheduleRow schedule) {
    Set<FiltersSetRow> _selectedFilterSet = {};
    _selectedFilterSet.clear();
    _selectedFilterSet.addAll(
        filtersSets.all.where((e) => (e.id == schedule.filtersSetId)));
    debugPrint(
        '$runtimeType _buildFilterSetSelectTile FilterSetRow: $_selectedFilterSet');
    return ScheduleCollectionTile(
      selectedFilterSet: _selectedFilterSet,
      onSelection: (selectedFilterSet) {
        setState(() {
          _templateSchedules.remove(schedule); // Remove the old schedule
          // Create a new schedule with the updated interval time
          final updatedSchedule = WallpaperScheduleRow(
            id: schedule.id,
            orderNum: schedule.orderNum,
            labelName: schedule.labelName,
            privacyGuardLevelId: schedule.privacyGuardLevelId,
            filtersSetId: selectedFilterSet.first.id,
            updateType: schedule.updateType,
            widgetId: schedule.widgetId,
            interval: schedule.interval,
            isActive: schedule.isActive,
          );
          _templateSchedules.add(updatedSchedule); // Add the new schedule
        });
      },
    );
  }

  Widget _buildIntervalSelectTile(WallpaperScheduleRow schedule) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Interval:',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        Column(children: _buildIntervalOptions(schedule)),
      ],
    );
  }

  List<Widget> _buildIntervalOptions(WallpaperScheduleRow schedule) {
    final l10n = context.l10n;
    String _curIntervalString = formatToLocalDuration(context,Duration(seconds:schedule.interval));
    var _useInterval = schedule.interval == 0 ? false : true;
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
              _buildInterval(schedule);
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

  Future<void> _buildInterval(WallpaperScheduleRow schedule) async {
    final v = await showDialog<int>(
      context: context,
      builder: (context) =>
          HmsDurationDialog(initialSeconds: schedule.interval),
    );
    if (v != null) {
      setState(() {
        _templateSchedules.remove(schedule); // Remove the old schedule
        // Create a new schedule with the updated interval time
        final updatedSchedule = WallpaperScheduleRow(
          id: schedule.id,
          orderNum: schedule.orderNum,
          labelName: schedule.labelName,
          privacyGuardLevelId: schedule.privacyGuardLevelId,
          filtersSetId: schedule.filtersSetId,
          updateType: schedule.updateType,
          widgetId: schedule.widgetId,
          interval: v,
          isActive: schedule.isActive,
        );
        _templateSchedules.add(updatedSchedule); // Add the new schedule
      });
    }
  }

  Widget _buildColorTile() {
    return ListTile(
      title: const Text('Color'),
      trailing: GestureDetector(
        onTap: _pickColor,
        child: Container(
          width: 24,
          height: 24,
          color: _selectedColor ?? Colors.transparent,
        ),
      ),
    );
  }

  Future<void> _pickColor() async {
    final color = await showDialog<Color>(
      context: context,
      builder: (context) => ColorPickerDialog(
        initialValue: _selectedColor ?? const Color(0xff3f51b5),
      ),
      routeSettings: const RouteSettings(name: ColorPickerDialog.routeName),
    );
    if (color != null) {
      setState(() {
        _selectedColor = color;
      });
    }
  }

  Widget _buildActiveSwitchTile() {
    return SwitchListTile(
      title: const Text('Active'),
      value: _isActive,
      onChanged: (value) {
        setState(() {
          _isActive = value;
        });
      },
    );
  }

  Widget _buildAliasNameTextFormFieldTile() {
    return TextFormField(
      controller: _aliasNameController,
      decoration: const InputDecoration(labelText: 'Alias Name'),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter an alias name';
        }
        return null;
      },
    );
  }
}
