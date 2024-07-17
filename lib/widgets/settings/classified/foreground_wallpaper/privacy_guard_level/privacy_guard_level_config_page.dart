import 'dart:math';

import 'package:aves/model/foreground_wallpaper/privacy_guard_level.dart';
import 'package:aves/widgets/common/basic/scaffold.dart';
import 'package:aves/widgets/common/extensions/build_context.dart';
import 'package:flutter/material.dart';

import '../../../../common/basic/list_tiles/color.dart';
import '../../../../common/identity/buttons/outlined_button.dart';

class PrivacyGuardLevelConfigPage extends StatefulWidget {
  static const routeName = '/settings/classified/privacy_guard_level_config';
  final PrivacyGuardLevelRow? item;
  final List<PrivacyGuardLevelRow?> allItems;
  final Set<PrivacyGuardLevelRow?> activeItems;

  const PrivacyGuardLevelConfigPage({
    super.key,
    required this.item,
    required this.allItems,
    required this.activeItems,
  });

  @override
  State<PrivacyGuardLevelConfigPage> createState() => _PrivacyGuardLevelConfigPageState();
}
class _PrivacyGuardLevelConfigPageState extends State<PrivacyGuardLevelConfigPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _aliasNameController;
  Color? _selectedColor;
  bool _isActive = false;
  late PrivacyGuardLevelRow? _currentItem;

  @override
  void initState() {
    super.initState();
    final int newLevel = _generateGuardLevel();
    final int newId = _generateUniqueId();
    _currentItem = widget.item ?? PrivacyGuardLevelRow(
      privacyGuardLevelID: newId,
      guardLevel: newLevel,
      labelName: 'Level $newLevel Id:$newId',
      color: _getRandomColor(), // Assign a random color
      isActive: true,
    );
    _aliasNameController = TextEditingController(text: _currentItem!.labelName);
    _selectedColor = _currentItem!.color;
    _isActive = _currentItem!.isActive;
  }
  Color _getRandomColor() {
    final Random random = Random();
    return Color.fromARGB(
      255,
      random.nextInt(256),
      random.nextInt(256),
      random.nextInt(256),
    );
  }

  int _generateUniqueId() {
    int id = 1;
    while (privacyGuardLevels.all.any((item) => item.privacyGuardLevelID == id)) {
      id++;
    }
    return id;
  }

  int _generateGuardLevel() {
    // final activeItems = widget.allItems.where((item) => item?.isActive ?? false).toList();
    final int maxLevelNow = widget.allItems.where((item) => widget.activeItems.contains(item)).length;
    return maxLevelNow + 1;
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
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AvesScaffold(
      appBar: AppBar(
        title: Text(l10n.settingsPrivacyGuardLevelTabTypes),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              Text('ID: ${_currentItem?.privacyGuardLevelID ?? ''}'),
              const SizedBox(height: 8),
              Text('Guard Level: ${_currentItem?.guardLevel ?? ''}'),
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
              ListTile(
                title: const Text('Color'),
                trailing: GestureDetector(
                  onTap: _pickColor,
                  child: Container(
                    width: 24,
                    height: 24,
                    color: _selectedColor ?? Colors.transparent,
                    child: Container(
                      color: _selectedColor ?? Colors.grey,
                      width: 24,
                      height: 24,
                    ),
                  ),
                ),
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
