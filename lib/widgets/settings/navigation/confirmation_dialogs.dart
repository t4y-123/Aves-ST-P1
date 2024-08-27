import 'package:aves/model/settings/settings.dart';
import 'package:aves/widgets/common/basic/scaffold.dart';
import 'package:aves/widgets/common/extensions/build_context.dart';
import 'package:aves/widgets/settings/common/tiles.dart';
import 'package:flutter/material.dart';

class ConfirmationDialogPage extends StatelessWidget {
  static const routeName = '/settings/navigation_confirmation';

  const ConfirmationDialogPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AvesScaffold(
      appBar: AppBar(
        title: Text(l10n.settingsConfirmationDialogTitle),
      ),
      body: SafeArea(
        child: ListView(children: [
          SettingsSwitchListTile(
            selector: (context, s) => s.confirmMoveUndatedItems,
            onChanged: (v) => settings.confirmMoveUndatedItems = v,
            title: l10n.settingsConfirmationBeforeMoveUndatedItems,
          ),
          SettingsSwitchListTile(
            selector: (context, s) => s.confirmMoveToBin,
            onChanged: (v) => settings.confirmMoveToBin = v,
            title: l10n.settingsConfirmationBeforeMoveToBinItems,
          ),
          SettingsSwitchListTile(
            selector: (context, s) => s.confirmDeleteForever,
            onChanged: (v) => settings.confirmDeleteForever = v,
            title: l10n.settingsConfirmationBeforeDeleteItems,
          ),
          const Divider(height: 32),
          SettingsSwitchListTile(
            selector: (context, s) => s.confirmAfterMoveToBin,
            onChanged: (v) => settings.confirmAfterMoveToBin = v,
            title: l10n.settingsConfirmationAfterMoveToBinItems,
          ),
          const Divider(height: 32),
          SettingsSwitchListTile(
            selector: (context, s) => s.confirmCreateVault,
            onChanged: (v) => settings.confirmCreateVault = v,
            title: l10n.settingsConfirmationVaultDataLoss,
          ),
          const Divider(height: 32),
          SettingsSwitchListTile(
            selector: (context, s) => s.confirmSetDateToNow,
            onChanged: (v) => settings.confirmSetDateToNow = v,
            title: l10n.settingsConfirmationSetDateToNowItems,
          ),
          SettingsSwitchListTile(
            selector: (context, s) => s.confirmShareByCopy,
            onChanged: (v) => settings.confirmShareByCopy = v,
            title: l10n.settingsConfirmationShareByCopy,
          ),
          SettingsSwitchListTile(
            selector: (context, s) => s.confirmEditAsCopiedFirst,
            onChanged: (v) => settings.confirmEditAsCopiedFirst = v,
            title: l10n.settingsConfirmationEditAsCopiedFirst,
          ),
          SettingsSwitchListTile(
            selector: (context, s) => s.confirmRemoveScenario,
            onChanged: (v) => settings.confirmRemoveScenario = v,
            title: l10n.settingsConfirmationRemoveScenario,
          ),
          SettingsSwitchListTile(
            selector: (context, s) => s.confirmRemoveAssign,
            onChanged: (v) => settings.confirmRemoveAssign = v,
            title: l10n.settingsConfirmationRemoveAssign,
          ),
        ]),
      ),
    );
  }
}
