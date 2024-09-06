import 'package:aves/model/fgw/enum/fgw_schedule_item.dart';
import 'package:aves/model/fgw/fgw_used_entry_record.dart';
import 'package:aves/model/filters/fgw_used.dart';
import 'package:aves/widgets/common/extensions/build_context.dart';
import 'package:flutter/material.dart';

class FgwUsedFilterDialog extends StatefulWidget {
  const FgwUsedFilterDialog({super.key});

  @override
  State<FgwUsedFilterDialog> createState() => _FgwUsedFilterDialogState();
}

class _FgwUsedFilterDialogState extends State<FgwUsedFilterDialog> {
  int? selectedGuardLevelId;
  WallpaperUpdateType? selectedUpdateType;
  int? selectedWidgetId;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: fgwUsedEntryRecord.refresh(notify: false),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const CircularProgressIndicator(); // Show loading indicator while waiting
          } else if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}');
          }

          // Refresh is complete, proceed to extract the available data
          final availableGuardLevelIds = fgwUsedEntryRecord.all.map((r) => r.guardLevelId).toSet();
          final availableUpdateTypes = fgwUsedEntryRecord.all.map((r) => r.updateType).toSet();
          final availableWidgetIds = fgwUsedEntryRecord.all.map((r) => r.widgetId).toSet();

          return AlertDialog(
            title: Text(context.l10n.queryHelperTypeFgwUsed),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<int?>(
                  value: selectedGuardLevelId,
                  items: [
                    DropdownMenuItem(value: null, child: Text(context.l10n.menuActionSelectAll)),
                    ...availableGuardLevelIds.map((id) => DropdownMenuItem(value: id, child: Text('$id'))),
                  ],
                  onChanged: (value) {
                    setState(() {
                      selectedGuardLevelId = value;
                    });
                  },
                  decoration: InputDecoration(labelText: context.l10n.guardLevelId),
                ),
                DropdownButtonFormField<WallpaperUpdateType?>(
                  value: selectedUpdateType,
                  items: [
                    DropdownMenuItem(value: null, child: Text(context.l10n.menuActionSelectAll)),
                    ...availableUpdateTypes.map((type) => DropdownMenuItem(value: type, child: Text(type.toString()))),
                  ],
                  onChanged: (value) {
                    setState(() {
                      selectedUpdateType = value;
                    });
                  },
                  decoration: InputDecoration(labelText: context.l10n.updateType),
                ),
                DropdownButtonFormField<int?>(
                  value: selectedWidgetId,
                  items: [
                    DropdownMenuItem(value: null, child: Text(context.l10n.menuActionSelectAll)),
                    ...availableWidgetIds.map((id) => DropdownMenuItem(value: id, child: Text('$id'))),
                  ],
                  onChanged: (value) {
                    setState(() {
                      selectedWidgetId = value;
                    });
                  },
                  decoration: InputDecoration(labelText: context.l10n.widgetId),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(null),
                child: Text(context.l10n.cancelTooltip),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(FgwUsedFilter(
                    guardLevelId: selectedGuardLevelId,
                    updateType: selectedUpdateType,
                    widgetId: selectedWidgetId,
                  ));
                },
                child: Text(context.l10n.applyButtonLabel),
              ),
            ],
          );
        });
  }
}
