import 'package:flutter/material.dart';
import 'dart:collection';

class GenericForegroundWallpaperItemsSelectionPage<T> extends StatefulWidget {
  static const routeName = '/settings/select_generic_item';
  final Set<T> selectedItems;
  final int? maxSelection;
  final List<T> allItems;
  final String Function(T) displayString;
  final int Function(T) itemId;

  const GenericForegroundWallpaperItemsSelectionPage({
    super.key,
    required this.selectedItems,
    this.maxSelection,
    required this.allItems,
    required this.displayString,
    required this.itemId,
  });

  @override
  State<GenericForegroundWallpaperItemsSelectionPage<T>> createState() => _GenericForegroundWallpaperItemsSelectionPageState<T>();
}

class _GenericForegroundWallpaperItemsSelectionPageState<T> extends State<GenericForegroundWallpaperItemsSelectionPage<T>> {
  late Set<int> _selectedIds;
  final Queue<int> _selectionOrder = Queue<int>();

  @override
  void initState() {
    super.initState();
    _selectedIds = widget.selectedItems.map((item) => widget.itemId(item)).toSet();
    _selectionOrder.addAll(_selectedIds);
  }

  void _toggleSelection(int id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
        _selectionOrder.remove(id);
      } else if (widget.maxSelection == null || widget.maxSelection! <= 0 || _selectedIds.length < widget.maxSelection!) {
        _selectedIds.add(id);
        _selectionOrder.addLast(id);
      } else {
        final int earliestSelected = _selectionOrder.removeFirst();
        _selectedIds.remove(earliestSelected);
        _selectedIds.add(id);
        _selectionOrder.addLast(id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Select Items'),
      ),
      body: SafeArea(
        child: ListView(
          children: widget.allItems.map((item) {
            final id = widget.itemId(item);
            return ListTile(
              title: Text(widget.displayString(item)),
              trailing: Switch(
                value: _selectedIds.contains(id),
                onChanged: (value) {
                  _toggleSelection(id);
                },
              ),
            );
          }).toList(),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Set<T> filteredItems = widget.allItems.where((item) => _selectedIds.contains(widget.itemId(item))).toSet();
          Navigator.pop(context, filteredItems);
        },
        child: const Icon(Icons.check),
      ),
    );
  }
}