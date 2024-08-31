import 'package:aves/model/fgw/filters_set.dart';
import 'package:aves/model/presentation/base_bridge_row.dart';
import 'package:aves/services/intent_service.dart';
import 'package:aves/theme/icons.dart';
import 'package:aves/widgets/collection/filter_bar.dart';
import 'package:aves/widgets/common/action_mixins/feedback.dart';
import 'package:aves/widgets/common/extensions/build_context.dart';
import 'package:aves/widgets/settings/presentation/foreground_wallpaper/filter_set/filter_set_config_page.dart';
import 'package:aves/widgets/settings/presentation/foreground_wallpaper/schedule/generic_selection_page.dart';
import 'package:flutter/material.dart';

class ScheduleCollectionTile extends StatefulWidget {
  final Set<FiltersSetRow> selectedFilterSet;
  final void Function(Set<FiltersSetRow>) onSelection;
  final String? title;
  const ScheduleCollectionTile({
    super.key,
    required this.selectedFilterSet,
    required this.onSelection,
    this.title,
  });

  @override
  State<ScheduleCollectionTile> createState() => _ScheduleCollectionTileState();
}

class _ScheduleCollectionTileState extends State<ScheduleCollectionTile> with FeedbackMixin {
  late Set<FiltersSetRow> _selectedFilterSet;

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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.title != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${context.l10n.settingsFilterSetTile}:  (id:${_selectedFilterSet.first.id})',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ' ${_selectedFilterSet.isEmpty ? 'None' : _selectedFilterSet.first.labelName}',
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
                          builder: (context) => GenericForegroundWallpaperItemsSelectionPage<FiltersSetRow>(
                            selectedItems: _selectedFilterSet,
                            maxSelection: 1,
                            allItems: filtersSets.bridgeAll.where((e) => e.isActive).toList(),
                            displayString: (item) => 'ID: ${item.id}-Num: ${item.orderNum}: ${item.labelName}',
                            itemId: (item) => item.orderNum,
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
                      final curFilterSetRow = _selectedFilterSet.first;
                      final curFilters = _selectedFilterSet.first.filters;
                      debugPrint('$runtimeType:  _selectedFilterSet.first.filters $curFilters');
                      debugPrint(
                          '$runtimeType: final selection = await IntentService.pickCollectionFilters(curFilters);');
                      final selection = await IntentService.pickCollectionFilters(curFilters);
                      debugPrint('$runtimeType: selection: $selection');
                      if (selection != null) {
                        final newFilterSetRow = FiltersSetRow(
                          id: curFilterSetRow.id,
                          orderNum: curFilterSetRow.orderNum,
                          labelName: curFilterSetRow.labelName,
                          filters: selection,
                          isActive: curFilterSetRow.isActive,
                        );
                        await filtersSets.setRows({newFilterSetRow}, type: PresentationRowType.bridgeAll);
                        setState(() {
                          widget.selectedFilterSet.removeWhere((item) => item.id == newFilterSetRow.id);
                          widget.selectedFilterSet.add(newFilterSetRow);
                        });
                      }
                    },
                    icon: const Icon(AIcons.edit),
                  ),
                  IconButton(
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => FilterSetConfigPage(
                            item: null, // Pass null to create a new item
                            allItems: filtersSets.bridgeAll.toList(),
                            activeItems: filtersSets.bridgeAll.where((e) => e.isActive).toSet(),
                          ),
                        ),
                      ).then((newItem) {
                        if (newItem != null) {
                          //final newRow = newItem as FilterSetRow;
                          setState(() {
                            filtersSets.add({newItem}, type: PresentationRowType.bridgeAll);
                            _selectedFilterSet = {newItem};
                            widget.onSelection({newItem});
                          });
                        } else {
                          filtersSets.removeRows({newItem}, type: PresentationRowType.bridgeAll);
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
