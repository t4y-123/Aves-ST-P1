import 'package:aves/model/assign/assign_entries.dart';
import 'package:aves/model/assign/assign_record.dart';
import 'package:aves/model/assign/enum/assign_item.dart';
import 'package:aves/model/filters/filters.dart';
import 'package:aves/theme/icons.dart';
import 'package:aves/widgets/common/extensions/build_context.dart';
import 'package:collection/collection.dart';
import 'package:flutter/widgets.dart';

class AssignFilter extends CoveredCollectionFilter {
  static const type = 'assign';

  final int assignId;
  final String displayName;
  late final EntryFilter _test;
  late final AssignRecordRow? assignRecord;
  late final Set<int>? containsEntryIds;

  @override
  List<Object?> get props => [assignId, displayName, reversed];

  AssignFilter(this.assignId, this.displayName, {super.reversed = false}) {
    //debugPrint('$runtimeType AssignFilter $assignId $displayName');
    final assignRecord = assignRecords.all.firstWhereOrNull((e) => e.id == assignId);
    containsEntryIds =
        assignEntries.all.where((e) => e.isActive && e.assignId == assignId).map((e) => e.entryId).toSet();
    if (containsEntryIds != null && containsEntryIds!.isNotEmpty) {
      this.assignRecord = assignRecord;
      _test = (entry) {
        return containsEntryIds!.contains(entry.id);
      };
    } else {
      this.assignRecord = null;
      _test = (entry) => false;
    }
    //debugPrint('$runtimeType AssignFilter $assignId $displayName');
  }

  factory AssignFilter.fromMap(Map<String, dynamic> json) {
    return AssignFilter(
      json['assignId'],
      json['displayName'],
      reversed: json['reversed'] ?? false,
    );
  }

  @override
  Map<String, dynamic> toMap() => {
        'type': type,
        'assignId': assignId,
        'displayName': displayName,
        'reversed': reversed,
      };

  @override
  EntryFilter get positiveTest => _test;

  @override
  bool get exclusiveProp => false;

  @override
  String get universalLabel => displayName;

  @override
  String getLabel(BuildContext context) => displayName.isEmpty ? context.l10n.filterNoAssignLabel : displayName;

  @override
  Widget? iconBuilder(BuildContext context, double size, {bool allowGenericIcon = true}) {
    return assignRecord != null
        ? Icon(assignRecord?.assignType == AssignRecordType.permanent ? AIcons.assignP : AIcons.assignT, size: size)
        : null;
  }

  @override
  String get category => type;

  @override
  String get key => '$type-$reversed-$assignId';
}
