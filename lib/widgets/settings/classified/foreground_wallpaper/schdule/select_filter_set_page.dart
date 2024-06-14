import 'package:aves/widgets/common/basic/scaffold.dart';
import 'package:aves/widgets/common/extensions/build_context.dart';
import 'package:flutter/material.dart';
import '../../../../../model/foreground_wallpaper/filterSet.dart';



class FilterSetSelectionPage  extends StatefulWidget {
  static const routeName = '/settings/classified/wallpaper_schedule_config/select_filter_set';
  final Set<FilterSetRow> selectedFilterSet;


  const FilterSetSelectionPage ({
    super.key,
    required this.selectedFilterSet,
  });

  @override
  State<FilterSetSelectionPage > createState() => _PrivacyGuardLevelSelectionState();
}
class _PrivacyGuardLevelSelectionState extends State<FilterSetSelectionPage > {
  late Set<int> _selectedFilterSet;
  late int _selectedFilterSetNum;

  @override
  void initState() {
    super.initState();
    _selectedFilterSet = widget.selectedFilterSet.map((item) => item.filterSetNum).toSet();
    _selectedFilterSetNum = _selectedFilterSet.first;
  }

  void _selectFilterSet(int num) {
    setState(() {
      _selectedFilterSet.clear();
      _selectedFilterSet.add(num);
      _selectedFilterSetNum = num;
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
          children: filterSet.all.where((e) => e.isActive).map((filterSet) {
            return ListTile(
              title: Text('ID: ${filterSet.filterSetId}-Num: ${filterSet.filterSetNum}: ${filterSet.aliasName}'),
              trailing: Radio(
                value: filterSet.filterSetNum,
                groupValue: _selectedFilterSetNum,
                onChanged: (value) {
                  _selectFilterSet(value as int);
                },
              ),
            );
          }).toList(),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Set<FilterSetRow> resultFilterSet = filterSet.all.where((item) => _selectedFilterSet.contains(item.filterSetNum)).toSet();

          Navigator.pop(context, resultFilterSet);
        },
        child: const Icon(Icons.check),
      ),
    );
  }
}
