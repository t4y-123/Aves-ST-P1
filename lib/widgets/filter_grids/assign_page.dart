import 'package:aves/model/assign/assign_record.dart';
import 'package:aves/model/filters/assign.dart';
import 'package:aves/model/filters/filters.dart';
import 'package:aves/model/settings/settings.dart';
import 'package:aves/model/source/assign.dart';
import 'package:aves/model/source/collection_source.dart';
import 'package:aves/theme/icons.dart';
import 'package:aves/widgets/common/extensions/build_context.dart';
import 'package:aves/widgets/common/identity/empty.dart';
import 'package:aves/widgets/filter_grids/common/action_delegates/assign_set.dart';
import 'package:aves/widgets/filter_grids/common/filter_nav_page.dart';
import 'package:aves/widgets/filter_grids/common/section_keys.dart';
import 'package:aves_model/aves_model.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AssignListPage extends StatelessWidget {
  static const routeName = '/assign';

  const AssignListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final source = context.read<CollectionSource>();
    return Selector<Settings, (ChipSortFactor, bool, Set<CollectionFilter>)>(
      selector: (context, s) => (s.tagSortFactor, s.tagSortReverse, s.pinnedFilters),
      shouldRebuild: (t1, t2) {
        // `Selector` by default uses `DeepCollectionEquality`, which does not go deep in collections within records
        const eq = DeepCollectionEquality();
        return !(eq.equals(t1.$1, t2.$1) && eq.equals(t1.$2, t2.$2) && eq.equals(t1.$3, t2.$3));
      },
      builder: (context, s, child) {
        return StreamBuilder(
          stream: source.eventBus.on<AssignsChangedEvent>(),
          builder: (context, snapshot) {
            final gridItems = _getGridItems(source);
            return FilterNavigationPage<AssignFilter, AssignChipSetActionDelegate>(
              source: source,
              title: context.l10n.tagPageTitle,
              sortFactor: settings.tagSortFactor,
              actionDelegate: AssignChipSetActionDelegate(gridItems),
              filterSections: _groupToSections(gridItems),
              applyQuery: applyQuery,
              emptyBuilder: () => EmptyContent(
                icon: AIcons.tag,
                text: context.l10n.tagEmpty,
              ),
            );
          },
        );
      },
    );
  }

  List<FilterGridItem<AssignFilter>> applyQuery(
      BuildContext context, List<FilterGridItem<AssignFilter>> filters, String query) {
    return filters.where((item) => item.filter.displayName.toUpperCase().contains(query)).toList();
  }

  List<FilterGridItem<AssignFilter>> _getGridItems(CollectionSource source) {
    final filters =
        assignRecords.all.where((e) => e.isActive).map((item) => AssignFilter(item.id, item.labelName)).toSet();
    return FilterNavigationPage.sort(settings.tagSortFactor, settings.tagSortReverse, source, filters);
  }

  static Map<ChipSectionKey, List<FilterGridItem<AssignFilter>>> _groupToSections(
      Iterable<FilterGridItem<AssignFilter>> sortedMapEntries) {
    final pinned = settings.pinnedFilters.whereType<AssignFilter>();
    final byPin = groupBy<FilterGridItem<AssignFilter>, bool>(sortedMapEntries, (e) => pinned.contains(e.filter));
    final pinnedMapEntries = (byPin[true] ?? []);
    final unpinnedMapEntries = (byPin[false] ?? []);

    return {
      if (pinnedMapEntries.isNotEmpty || unpinnedMapEntries.isNotEmpty)
        const ChipSectionKey(): [
          ...pinnedMapEntries,
          ...unpinnedMapEntries,
        ],
    };
  }
}
