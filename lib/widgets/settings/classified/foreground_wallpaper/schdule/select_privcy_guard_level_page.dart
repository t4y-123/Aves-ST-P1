import 'package:aves/widgets/common/basic/scaffold.dart';
import 'package:aves/widgets/common/extensions/build_context.dart';
import 'package:flutter/material.dart';
import '../../../../../model/foreground_wallpaper/privacyGuardLevel.dart';

class PrivacyGuardLevelSelectionPage extends StatefulWidget {
  static const routeName = '/settings/classified/wallpaper_schedule_config/select_guard_level';
  final Set<PrivacyGuardLevelRow> selectedPrivacyGuardLevels;


  const PrivacyGuardLevelSelectionPage({
    super.key,
    required this.selectedPrivacyGuardLevels,
  });

  @override
  State<PrivacyGuardLevelSelectionPage> createState() => _PrivacyGuardLevelSelectionState();
}
class _PrivacyGuardLevelSelectionState extends State<PrivacyGuardLevelSelectionPage> {
  late Set<int> _selectedIntLevels;

  @override
  void initState() {
    super.initState();
    _selectedIntLevels = widget.selectedPrivacyGuardLevels.map((item) => item.guardLevel).toSet();
  }

  void _toggleSelection(int level) {
    setState(() {
      if (_selectedIntLevels.contains(level)) {
        _selectedIntLevels.remove(level);
      } else {
        _selectedIntLevels.add(level);
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
        child:  ListView(
          children: privacyGuardLevels.all.where((e) => e.isActive).map((privacyGuardLevel) {
            return ListTile(
              title: Text('L${privacyGuardLevel.guardLevel}:  ${privacyGuardLevel.aliasName} '),
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
