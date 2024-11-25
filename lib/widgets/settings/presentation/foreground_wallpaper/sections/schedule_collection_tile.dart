import 'package:aves/model/fgw/filters_set.dart';
import 'package:aves/model/fgw/wallpaper_schedule.dart';
import 'package:aves/model/presentation/base_bridge_row.dart';
import 'package:aves/services/intent_service.dart';
import 'package:aves/theme/icons.dart';
import 'package:aves/widgets/collection/filter_bar.dart';
import 'package:aves/widgets/common/action_mixins/feedback.dart';
import 'package:aves/widgets/common/extensions/build_context.dart';
import 'package:aves/widgets/settings/presentation/common/generic_selection_page.dart';
import 'package:aves/widgets/settings/presentation/foreground_wallpaper/sub_page/filter_set_item_page.dart';
import 'package:flutter/material.dart';

class ScheduleFilterSetTile extends StatefulWidget {
  final FgwScheduleRow item;

  final String? title;
  const ScheduleFilterSetTile({
    super.key,
    required this.item,
    this.title,
  });

  @override
  State<ScheduleFilterSetTile> createState() => _ScheduleFilterSetTileState();
}

class _ScheduleFilterSetTileState extends State<ScheduleFilterSetTile> with FeedbackMixin {
  FgwScheduleRow get _item => widget.item;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    debugPrint('$runtimeType ScheduleFilterSetCollectionTile FgwScheduleRow: ${widget.item}');

    FiltersSetRow curFilterSet = filtersSets.bridgeAll.firstWhere((e) => e.id == _item.filtersSetId);
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
                    '${context.l10n.settingsFilterSetTile}:  (id:${_item.filtersSetId})',
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
                          ' ${curFilterSet.labelName}',
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
                            selectedItems: {curFilterSet},
                            maxSelection: 1,
                            allItems: filtersSets.bridgeAll.where((e) => e.isActive).toList(),
                            displayString: (item) => 'ID: ${item.id}-Num: ${item.orderNum}: ${item.labelName}',
                            itemId: (item) => item.orderNum,
                          ),
                        ),
                      );
                      if (result != null && result is Set<FiltersSetRow>) {
                        setState(() {
                          final newFilterSetId = result.first.id;
                          final newScheduleRow = _item.copyWith(filtersSetId: newFilterSetId);
                          fgwSchedules
                              .setWithDealConflictUpdateType({newScheduleRow}, type: PresentationRowType.bridgeAll);
                          //showFeedback(context, FeedbackType.info, 'select exist ${result.first}');
                        });
                      }
                    },
                    icon: const Icon(AIcons.settings),
                  ),
                  IconButton(
                    onPressed: () async {
                      final curFilterSetRow = curFilterSet;
                      final curFilters = curFilterSet.filters;
                      debugPrint('$runtimeType:  curFilterSet.filters $curFilters');
                      debugPrint(
                          '$runtimeType: final selection = await IntentService.pickCollectionFilters(curFilters);');
                      final selection = await IntentService.pickCollectionFilters(curFilters);
                      debugPrint('$runtimeType: selection: $selection');
                      if (selection != null) {
                        final newRow = filtersSets.bridgeAll
                            .firstWhere((e) => e.id == curFilterSetRow.id)
                            .copyWith(filters: selection);
                        await filtersSets.setRows({newRow}, type: PresentationRowType.bridgeAll);
                        final newScheduleRow = _item.copyWith(filtersSetId: newRow.id);
                        await fgwSchedules
                            .setWithDealConflictUpdateType({newScheduleRow}, type: PresentationRowType.bridgeAll);
                        setState(() {});
                      }
                    },
                    icon: const Icon(AIcons.edit),
                  ),
                  IconButton(
                    onPressed: () async {
                      final newFilterSet = filtersSets.newRow(1, type: PresentationRowType.bridgeAll);
                      await filtersSets.add({newFilterSet}, type: PresentationRowType.bridgeAll);
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => FiltersSetItemPage(
                            item: newFilterSet, // Pass null to create a new item
                          ),
                        ),
                      );
                      if (result == true) {
                        final newScheduleRow = _item.copyWith(filtersSetId: newFilterSet.id);
                        await fgwSchedules
                            .setWithDealConflictUpdateType({newScheduleRow}, type: PresentationRowType.bridgeAll);
                      } else {
                        // to make it can cancel added.
                        await filtersSets.removeRows({newFilterSet}, type: PresentationRowType.bridgeAll);
                      }
                      setState(() {});
                    },
                    icon: const Icon(AIcons.add),
                  ),
                ],
              ),
            ),
            FilterBar(
              filters: curFilterSet.filters!,
              interactive: false,
            ),
          ],
        ),
      ),
    );
  }
}
