import 'package:aves/model/filters/filters.dart';
import 'package:aves/model/foreground_wallpaper/fgw_used_entry_record.dart';
import 'package:aves/theme/icons.dart';
import 'package:aves/widgets/common/extensions/build_context.dart';
import 'package:flutter/widgets.dart';

class FgwUsedFilter extends CollectionFilter {
  static const type = 'fgw_used';

  static late EntryFilter _test;

  static final instance = FgwUsedFilter._private();
  static final instanceReversed = FgwUsedFilter._private(reversed: true);

  static late int nowSecs;

  static void updateNow() {
    Set<int> usedIds = fgwUsedEntryRecord.all.map((item) => (item.entryId)).toSet();
    _test = (entry) =>  (usedIds.any((item) => item == entry.id ));
  }

  @override
  List<Object?> get props => [reversed];

  FgwUsedFilter._private({super.reversed = false}) {
    updateNow();
  }

  factory FgwUsedFilter.fromMap(Map<String, dynamic> json) {
    final reversed = json['reversed'] ?? false;
    return reversed ? instanceReversed : instance;
  }

  @override
  Map<String, dynamic> toMap() => {
        'type': type,
        'reversed': reversed,
      };

  @override
  EntryFilter get positiveTest => _test;

  @override
  bool get exclusiveProp => false;

  @override
  String get universalLabel => type;

  @override
  String getLabel(BuildContext context) => context.l10n.filterFgwUsedLabel;

  @override
  Widget iconBuilder(BuildContext context, double size, {bool showGenericIcon = true}) => Icon(AIcons.fgwUsed, size: size);

  @override
  String get category => type;

  @override
  String get key => '$type-$reversed';
}
