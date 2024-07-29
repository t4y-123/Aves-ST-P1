import 'package:aves/widgets/common/basic/scaffold.dart';
import 'package:aves/widgets/common/extensions/build_context.dart';
import 'package:flutter/material.dart';
import '../../../../../model/foreground_wallpaper/privacy_guard_level.dart';
import 'dart:collection';

class PrivacyGuardLevelSelectionPage extends StatefulWidget {
  static const routeName = '/settings/classified/wallpaper_schedule_config/select_guard_level';
  final Set<PrivacyGuardLevelRow> selectedPrivacyGuardLevels;
  final int? maxSelection;

  const PrivacyGuardLevelSelectionPage({
    super.key,
    required this.selectedPrivacyGuardLevels,
    this.maxSelection,
  });

  @override
  State<PrivacyGuardLevelSelectionPage> createState() => _PrivacyGuardLevelSelectionState();
}

class _PrivacyGuardLevelSelectionState extends State<PrivacyGuardLevelSelectionPage> {
  late Set<int> _selectedIntLevels;
  // to make it auto unselect it oldest item when reach the maxSelection.
  final Queue<int> _selectionOrder = Queue<int>();

  @override
  void initState() {
    super.initState();
    _selectedIntLevels = widget.selectedPrivacyGuardLevels.map((item) => item.guardLevel).toSet();
    _selectionOrder.addAll(_selectedIntLevels);
  }

  void _toggleSelection(int level) {
    setState(() {
      if (_selectedIntLevels.contains(level)) {
        _selectedIntLevels.remove(level);
        _selectionOrder.remove(level);
      } else if (widget.maxSelection == null || widget.maxSelection! <= 0 || _selectedIntLevels.length < widget.maxSelection!) {
        _selectedIntLevels.add(level);
        _selectionOrder.addLast(level);
      } else {
        final int earliestSelected = _selectionOrder.removeFirst();
        _selectedIntLevels.remove(earliestSelected);
        _selectedIntLevels.add(level);
        _selectionOrder.addLast(level);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AvesScaffold(
      appBar: AppBar(
        title: Text(l10n.settingsConfirmationDialogTitle),
      ),
      body: SafeArea(
        child: ListView(
          children: privacyGuardLevels.all.where((e) => e.isActive).map((privacyGuardLevel) {
            return ListTile(
              title: Text('L${privacyGuardLevel.guardLevel}:  ${privacyGuardLevel.labelName} '),
              trailing: Switch(
                value: _selectedIntLevels.contains(privacyGuardLevel.guardLevel),
                onChanged: (value) {
                  _toggleSelection(privacyGuardLevel.guardLevel);
                },
              ),
            );
          }).toList(),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Set<PrivacyGuardLevelRow> filteredRows = privacyGuardLevels.all.where((row) => _selectedIntLevels.contains(row.guardLevel)).toSet();
          Navigator.pop(context, filteredRows);
        },
        child: const Icon(Icons.check),
      ),
    );
  }
}
