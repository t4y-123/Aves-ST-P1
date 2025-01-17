import 'package:aves/model/fgw/share_copied_entry.dart';
import 'package:aves/model/filters/path.dart';
import 'package:aves/model/settings/enums/presentation.dart';
import 'package:aves/model/settings/settings.dart';
import 'package:aves/utils/android_file_utils.dart';
import 'package:aves/widgets/common/action_mixins/feedback.dart';
import 'package:aves/widgets/common/basic/scaffold.dart';
import 'package:aves/widgets/common/extensions/build_context.dart';
import 'package:aves/widgets/settings/common/tiles.dart';
import 'package:flutter/material.dart';

class ShareByCopyPage extends StatelessWidget with FeedbackMixin {
  static const routeName = '/settings/classify/share_by_copy';

  const ShareByCopyPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AvesScaffold(
      appBar: AppBar(
        automaticallyImplyLeading: !settings.useTvLayout,
        title: Text(l10n.settingsShareByCopyPageTitle),
      ),
      body: SafeArea(
        child: ListView(
          children: [
            SettingsSwitchListTile(
              selector: (context, s) => !s.hiddenFilters.contains(PathFilter(androidFileUtils.avesShareByCopyPath)),
              onChanged: (v) => settings.changeFilterVisibility({PathFilter(androidFileUtils.avesShareByCopyPath)}, v),
              title: l10n.settingsShowAvesShareCopiedItems,
            ),
            SettingsSwitchListTile(
              selector: (context, s) => s.shareByCopyExpiredAutoRemove,
              onChanged: (v) => settings.shareByCopyExpiredAutoRemove = v,
              title: l10n.settingsShareByCopyAutoRemove,
            ),
            SettingsSwitchListTile(
              selector: (context, s) => s.shareByCopyCollectionPageAutoRemove,
              onChanged: (v) => settings.shareByCopyCollectionPageAutoRemove = v,
              title: l10n.settingsShareByCopyCollectionPageAutoRemove,
            ),
            SettingsSwitchListTile(
              selector: (context, s) => s.shareByCopyViewerPageAutoRemove,
              onChanged: (v) => settings.shareByCopyViewerPageAutoRemove = v,
              title: l10n.settingsShareByCopyViewerPageAutoRemove,
            ),
            SettingsSwitchListTile(
              selector: (context, s) => s.shareByCopyAppModeViewAutoRemove,
              onChanged: (v) => settings.shareByCopyAppModeViewAutoRemove = v,
              title: l10n.settingsShareByCopyAppModeViewAutoRemove,
            ),
            if (settings.enableBin)
              SettingsSwitchListTile(
                selector: (context, s) => s.shareByCopyExpiredRemoveUseBin,
                onChanged: (v) => settings.shareByCopyExpiredRemoveUseBin = v,
                title: l10n.settingsShareByCopyAutoRemoveUseBin,
              ),
            SettingsDurationListTile(
              selector: (context, s) => s.shareByCopyRemoveInterval,
              onChanged: (v) => settings.shareByCopyRemoveInterval = v,
              title: l10n.settingsExpiredInterval,
            ),
            SettingsNumberEditTile(
              selector: (context, s) => s.shareByCopyObsoleteRecordRemoveInterval,
              onChanged: (v) => settings.shareByCopyObsoleteRecordRemoveInterval = v,
              title: l10n.settingsShareByCopyRecordExpiredInterval,
              minValue: 1,
            ),
            SettingsSelectionListTile<ShareByCopySetDateType>(
              values: ShareByCopySetDateType.values,
              getName: (context, v) => v.getName(context),
              selector: (context, s) => s.shareByCopySetDateType,
              onSelection: (v) => settings.shareByCopySetDateType = v,
              tileTitle: context.l10n.settingsShareByCopySetDateTypeTileTitle,
              dialogTitle: context.l10n.settingsShareByCopySetDateTypeTileTitle,
            ),
            SettingsSelectionListTile<ShareByCopyRemoveSequence>(
              values: ShareByCopyRemoveSequence.values,
              getName: (context, v) => v.getName(context),
              selector: (context, s) => s.shareByCopyRemoveSequence,
              onSelection: (v) => settings.shareByCopyRemoveSequence = v,
              tileTitle: context.l10n.shareByCopyRemoveSequenceTileTitle,
              dialogTitle: context.l10n.shareByCopyRemoveSequenceTileTitle,
            ),
            ListTile(
              title: Text('${l10n.settingsClearShareCopiedItemsRecord} '),
              trailing: ElevatedButton(
                onPressed: () => _showConfirmationDialog(
                  context,
                  l10n.settingsClearShareCopiedItemsRecord,
                  l10n.confirmClearShareCopiedItemsRecord(shareCopiedEntries.all.length),
                  () {
                    _clearAllShareByCopyRecord(context);
                  },
                ),
                child: Text(l10n.applyButtonLabel),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showConfirmationDialog(BuildContext context, String title, String content, VoidCallback onConfirm) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                onConfirm();
              },
              child: Text(MaterialLocalizations.of(context).okButtonLabel),
            ),
          ],
        );
      },
    );
  }

  Future<void> _clearAllShareByCopyRecord(BuildContext context) async {
    await shareCopiedEntries.clear();
    showFeedback(context, FeedbackType.info, context.l10n.clearCompletedFeedback);
  }
}
