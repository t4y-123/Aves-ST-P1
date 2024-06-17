import 'package:flutter/material.dart';
import '../../../../../model/foreground_wallpaper/filterSet.dart';
import '../../../../../theme/icons.dart';
import '../../../../collection/filter_bar.dart';
import '../../../../common/action_mixins/feedback.dart';
import '../filter_set/filter_set_config_page.dart';
import 'generic_selection_page.dart';

class ScheduleCollectionTile extends StatefulWidget {
  final Set<FilterSetRow> selectedFilterSet;
  final void Function(Set<FilterSetRow>) onSelection;

  const ScheduleCollectionTile({
    super.key,
    required this.selectedFilterSet,
    required this.onSelection,
  });

  @override
  State<ScheduleCollectionTile> createState() => _ScheduleCollectionTileState();
}

class _ScheduleCollectionTileState  extends State<ScheduleCollectionTile>
    with FeedbackMixin  {
  late Set<FilterSetRow> _selectedFilterSet;

  @override
  void initState() {
    super.initState();
    _selectedFilterSet = widget.selectedFilterSet;
  }

  @override
  void didUpdateWidget(covariant ScheduleCollectionTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedFilterSet != oldWidget.selectedFilterSet) {
      setState(() {
        _selectedFilterSet = widget.selectedFilterSet;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    debugPrint('$runtimeType ScheduleCollectionTile FilterSetRow: $_selectedFilterSet');
    return ConstrainedBox(
      constraints: BoxConstraints(
        minHeight: (56.0) + theme.visualDensity.baseSizeAdjustment.dy,
      ),
      child: Center(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ' ${_selectedFilterSet.isEmpty ? 'None' : _selectedFilterSet.first.aliasName}',
                          style: textTheme.titleMedium!,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => GenericForegroundWallpaperItemsSelectionPage<FilterSetRow>(
                            selectedItems: _selectedFilterSet,
                            maxSelection: 1,
                            allItems: filterSet.all.where((e) => e.isActive).toList(),
                            displayString: (item) => 'ID: ${item.filterSetId}-Num: ${item.filterSetNum}: ${item.aliasName}',
                            itemId: (item) => item.filterSetNum,
                          ),
                        ),
                      );
                      if (result != null) {
                        setState(() {
                          _selectedFilterSet = result;
                          widget.onSelection(result);
                          showFeedback(context, FeedbackType.info, 'copied ${result.first}');
                        });
                      }
                    },
                    icon: const Icon(AIcons.settings),
                  ),
                  IconButton(
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => FilterSetConfigPage(
                            item: null, // Pass null to create a new item
                            allItems: filterSet.all.toList(),
                            activeItems: filterSet.all.where((e) => e.isActive).toSet(),
                          ),
                        ),
                      ).then((newItem) {
                        if (newItem != null) {
                          //final newRow = newItem as FilterSetRow;
                          setState(() {
                            filterSet.add({newItem});
                            filterSet.all.add(newItem);
                            _selectedFilterSet = {newItem};
                            widget.onSelection({newItem});
                          });
                        }
                      });
                    },
                    icon: const Icon(AIcons.add),
                  ),
                ],
              ),
            ),
            if (_selectedFilterSet.isNotEmpty)
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


