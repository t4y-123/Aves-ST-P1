import 'package:aves/widgets/common/basic/scaffold.dart';
import 'package:aves/widgets/common/extensions/build_context.dart';
import 'package:flutter/material.dart';
import '../../../../../model/foreground_wallpaper/filtersSet.dart';


import 'dart:collection';

class FilterSetSelectionPage extends StatefulWidget {
  static const routeName = '/settings/classified/wallpaper_schedule_config/select_filter_set';
  final Set<FiltersSetRow> selectedFilterSet;
  final int? maxSelection;

  const FilterSetSelectionPage({
    super.key,
    required this.selectedFilterSet,
    this.maxSelection,
  });

  @override
  State<FilterSetSelectionPage> createState() => _FilterSetSelectionPageState();
}

class _FilterSetSelectionPageState extends State<FilterSetSelectionPage> {
  late Set<int> _selectedFilterSet;
  late int _selectedFilterSetNum;
  final Queue<int> _selectionOrder = Queue<int>();

  @override
  void initState() {
    super.initState();
    _selectedFilterSet = widget.selectedFilterSet.map((item) => item.orderNum).toSet();
    if (_selectedFilterSet.isNotEmpty) {
      _selectedFilterSetNum = _selectedFilterSet.first;
      _selectionOrder.addAll(_selectedFilterSet);
    }
  }

  void _selectFilterSet(int num) {
    setState(() {
      if (_selectedFilterSet.contains(num)) {
        _selectedFilterSet.remove(num);
        _selectionOrder.remove(num);
      } else if (widget.maxSelection == null || widget.maxSelection! <= 0 || _selectedFilterSet.length < widget.maxSelection!) {
        _selectedFilterSet.add(num);
        _selectionOrder.addLast(num);
      } else {
        final int earliestSelected = _selectionOrder.removeFirst();
        _selectedFilterSet.remove(earliestSelected);
        _selectedFilterSet.add(num);
        _selectionOrder.addLast(num);
      }
      _selectedFilterSetNum = _selectedFilterSet.isEmpty ? -1 : _selectedFilterSet.last;
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
          children: filtersSets.all.where((e) => e.isActive).map((filterSet) {
            return ListTile(
              title: Text('ID: ${filterSet.id}-Num: ${filterSet.orderNum}: ${filterSet.labelName}'),
              trailing: Radio(
                value: filterSet.orderNum,
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
          Set<FiltersSetRow> resultFilterSet = filtersSets.all.where((item) => _selectedFilterSet.contains(item.orderNum)).toSet();
          Navigator.pop(context, resultFilterSet);
        },
        child: const Icon(Icons.check),
      ),
    );
  }
}
