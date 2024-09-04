import 'package:aves/model/assign/assign_entries.dart';
import 'package:aves/model/assign/assign_record.dart';
import 'package:aves/widgets/settings/presentation/assign/section/assign_sections.dart';
import 'package:aves/widgets/settings/presentation/common/item_page.dart';
import 'package:aves/widgets/settings/presentation/common/section.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AssignRecordItemPage extends StatelessWidget {
  static const routeName = '/settings/presentation/record_edit_settings_page/assignRecord_item_page';

  final AssignRecordRow item;

  const AssignRecordItemPage({
    super.key,
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AssignRecord>.value(value: assignRecords),
        ChangeNotifierProvider<AssignEntries>.value(value: assignEntries),
      ],
      child: Builder(
        builder: (context) {
          return PresentRowItemPage<AssignRecordRow>(
            item: item,
            buildTiles: (item) {
              return [
                PresentInfoTile<AssignRecordRow, AssignRecord>(item: item, items: assignRecords),
                PresentLabelNameTile<AssignRecordRow, AssignRecord>(item: item, items: assignRecords),
                ...context
                    .watch<AssignEntries>()
                    .bridgeAll
                    .where((e) => e.assignId == item.id)
                    .map((e) => AssignEntryItemPageTile(item: e)),
                AssignRecordEditTile(item: item),
                PresentActiveListTile<AssignRecordRow, AssignRecord>(item: item, items: assignRecords),
              ];
            },
          );
        },
      ),
    );
  }
}
