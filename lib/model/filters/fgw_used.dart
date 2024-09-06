import 'package:aves/model/fgw/enum/fgw_schedule_item.dart';
import 'package:aves/model/fgw/fgw_used_entry_record.dart';
import 'package:aves/model/filters/filters.dart';
import 'package:aves/theme/icons.dart';
import 'package:aves/utils/collection_utils.dart';
import 'package:aves/widgets/common/extensions/build_context.dart';
import 'package:flutter/widgets.dart';

class FgwUsedFilter extends CoveredCollectionFilter {
  static const type = 'fgw_used';

  final int? guardLevelId;
  final WallpaperUpdateType? updateType;
  final int? widgetId;
  late final Set<int>? containsEntryIds;
  late final EntryFilter _test;

  FgwUsedFilter({this.guardLevelId, this.updateType, this.widgetId, super.reversed = false}) {
    containsEntryIds = fgwUsedEntryRecord.all
        .where((row) {
          if (guardLevelId != null && row.guardLevelId != guardLevelId) return false;
          if (updateType != null && row.updateType != updateType) return false;
          if (widgetId != null && row.widgetId != widgetId) return false;
          return true;
        })
        .map((row) => row.entryId)
        .toSet();
    if (containsEntryIds != null && containsEntryIds!.isNotEmpty) {
      _test = (entry) {
        return containsEntryIds!.contains(entry.id);
      };
    } else {
      _test = (entry) => false;
    }
    //debugPrint('$runtimeType AssignFilter $assignId $displayName');
  }

  factory FgwUsedFilter.fromMap(Map<String, dynamic> json) {
    final guardLevelId = json['guardLevelId'] as int?;
    final updateType = json['updateType'] != null
        ? WallpaperUpdateType.values.safeByName(json['updateType'] as String, WallpaperUpdateType.home)
        : null;
    final widgetId = json['widgetId'] as int?;
    final reversed = json['reversed'] ?? false;

    return FgwUsedFilter(
      guardLevelId: guardLevelId,
      updateType: updateType,
      widgetId: widgetId,
      reversed: reversed,
    );
  }

  @override
  Map<String, dynamic> toMap() => {
        'type': type,
        'guardLevelId': guardLevelId,
        'updateType': updateType?.name,
        'widgetId': widgetId,
        'reversed': reversed,
      };

  @override
  EntryFilter get positiveTest => _test;

  @override
  List<Object?> get props => [guardLevelId, updateType, widgetId, reversed];

  @override
  String get universalLabel => type;

  @override
  String getLabel(BuildContext context) {
    final guardLevelLabel = guardLevelId?.toString() ?? context.l10n.menuActionSelectAll;
    final updateTypeLabel = updateType?.getName(context) ?? context.l10n.menuActionSelectAll;
    final widgetIdLabel = widgetId?.toString() ?? context.l10n.menuActionSelectAll;
    return '${guardLevelLabel}_${updateTypeLabel}_$widgetIdLabel';
  }

  @override
  Widget? iconBuilder(BuildContext context, double size, {bool allowGenericIcon = true}) =>
      Icon(AIcons.fgwUsed, size: size);

  @override
  String get category => type;

  @override
  String get key => '$type-$guardLevelId-$updateType-$widgetId-$reversed';

  @override
  bool get exclusiveProp => false;
}
