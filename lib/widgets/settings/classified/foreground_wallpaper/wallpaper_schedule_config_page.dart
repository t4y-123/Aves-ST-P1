import 'package:aves/widgets/common/basic/scaffold.dart';
import 'package:aves/widgets/common/extensions/build_context.dart';
import 'package:flutter/material.dart';
import '../../../../model/foreground_wallpaper/privacyGuardLevel.dart';
import '../../../../model/foreground_wallpaper/wallpaperSchedule.dart';
import '../../../common/identity/buttons/outlined_button.dart';

class WallpaperScheduleConfigPage extends StatefulWidget {
  static const routeName = '/settings/classified/privacy_guard_level_config';
  final WallpaperScheduleRow? item;
  final List<WallpaperScheduleRow?> allItems;
  final Set<WallpaperScheduleRow?> activeItems;

  const WallpaperScheduleConfigPage({
    super.key,
    required this.item,
    required this.allItems,
    required this.activeItems,
  });

  @override
  State<WallpaperScheduleConfigPage> createState() => _WallpaperScheduleConfigPageState();
}
class _WallpaperScheduleConfigPageState extends State<WallpaperScheduleConfigPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _aliasNameController;
  Color? _selectedColor;
  bool _isActive = false;
  late WallpaperScheduleRow? _currentItem;

  @override
  void initState() {
    super.initState();
    final int newNum = _generateNewNum();
    final int newId = _generateUniqueId();
    _currentItem = widget.item ?? WallpaperScheduleRow(
      id: newId,
      scheduleNum: newNum,
      scheduleName: 'S$newNum Id:$newId',
      isActive: true,
    );
    _aliasNameController = TextEditingController(text: _currentItem!.scheduleName);
    _isActive = _currentItem!.isActive;
  }

  int _generateUniqueId() {
    int id = 1;
    while (privacyGuardLevels.all.any((item) => item.privacyGuardLevelID == id)) {
      id++;
    }
    return id;
  }

  int _generateNewNum() {
    // final activeItems = widget.allItems.where((item) => item?.isActive ?? false).toList();
    final int maxNow = widget.allItems.where((item) => widget.activeItems.contains(item)).length;
    return maxNow + 1;
  }

  void _applyChanges() {
    if (_formKey.currentState?.validate() ?? false) {
      final updatedItem = WallpaperScheduleRow(
        id: _currentItem!.id,
        scheduleNum: _currentItem!.scheduleNum,
        scheduleName: _aliasNameController.text,
        isActive: _isActive,
      );
      Navigator.pop(context, updatedItem); // Return the updated item
    }
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
              Text('ID: ${_currentItem?.id ?? ''}'),
              const SizedBox(height: 8),
              Text('Sequence Number: ${_currentItem?.scheduleNum ?? ''}'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _aliasNameController,
                decoration: const InputDecoration(labelText: 'Alias Name'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an alias name';
                  }
                  return null;
                },
              ),
              SwitchListTile(
                title: const Text('Active'),
                value: _isActive,
                onChanged: (bool value) {
                  setState(() {
                    _isActive = value;
                  });
                },
              ),
              const SizedBox(height: 20),
              AvesOutlinedButton(
                onPressed: _applyChanges,
                label: context.l10n.settingsForegroundWallpaperConfigApplyChanges,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
