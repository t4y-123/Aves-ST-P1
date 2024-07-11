import 'package:aves/model/settings/settings.dart';
import 'package:aves/widgets/common/basic/scaffold.dart';
import 'package:aves/widgets/common/extensions/build_context.dart';
import 'package:aves/widgets/settings/common/tiles.dart';
import 'package:flutter/material.dart';

import '../../../model/filters/album.dart';
import '../../../utils/android_file_utils.dart';

class ShareByCopyPage extends StatelessWidget {
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
              selector: (context, s) => !s.hiddenFilters.contains(AlbumFilter(androidFileUtils.avesShareByCopyPath, null)),
              onChanged: (v) => settings.changeFilterVisibility({AlbumFilter(androidFileUtils.avesShareByCopyPath, null)}, v),
              title: l10n.settingsShowAvesShareCopiedItems,
            ),
            SettingsSwitchListTile(
              selector: (context, s) => s.shareByCopyExpiredAutoRemove,
              onChanged: (v) => settings.shareByCopyExpiredAutoRemove = v,
              title: l10n.settingsShareByCopyAutoRemove,
            ),
            if(settings.enableBin) SettingsSwitchListTile(
              selector: (context, s) => s.shareByCopyExpiredRemoveUseBin,
              onChanged: (v) => settings.shareByCopyExpiredRemoveUseBin = v,
              title: l10n.settingsShareByCopyAutoRemoveUseBin,
            ),
            SettingsDurationListTile(
              selector: (context, s) => s.shareByCopyRemoveInterval,
              onChanged: (v) => settings.shareByCopyRemoveInterval = v,
              title: l10n.settingsShareByCopyExpiredInterval,
            ),
          ],
        ),
      ),
    );
  }
}
