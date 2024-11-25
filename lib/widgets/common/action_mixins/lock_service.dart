import 'package:aves/model/scenario/enum/scenario_item.dart';
import 'package:aves/model/settings/defaults.dart';
import 'package:aves/services/common/services.dart';
import 'package:aves/widgets/common/extensions/build_context.dart';
import 'package:aves/widgets/dialogs/aves_dialog.dart';
import 'package:aves/widgets/dialogs/filter_editors/password_dialog.dart';
import 'package:aves/widgets/dialogs/filter_editors/pattern_dialog.dart';
import 'package:aves/widgets/dialogs/filter_editors/pin_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

final LockService lockService = LockService._private();

class LockService {
  LockService._private();

  Future<bool?> tryUnlock({
    required BuildContext context,
    required String key,
    required CommonLockType type,
    String? systemLocalizedReason,
    String? pinDialogTitle,
  }) async {
    bool? confirmed;

    switch (type) {
      case CommonLockType.system:
        try {
          confirmed = await LocalAuthentication().authenticate(
            localizedReason: systemLocalizedReason ?? 'Authenticate to unlock',
          );
        } on PlatformException catch (e, stack) {
          if (!{'auth_in_progress', 'NotAvailable'}.contains(e.code)) {
            await reportService.recordError(e, stack);
          }
        }
        break;
      case CommonLockType.pattern:
        final pattern = await showDialog<String>(
          context: context,
          builder: (context) => const PatternDialog(needConfirmation: false),
          routeSettings: const RouteSettings(name: PatternDialog.routeName),
        );
        if (pattern != null) {
          confirmed = pattern == await securityService.readValue(key);
        }
        break;
      case CommonLockType.pin:
        final pin = await showDialog<String>(
          context: context,
          builder: (context) => PinDialog(
            needConfirmation: false,
            titleTxt: pinDialogTitle ?? context.l10n.pinDialogEnterDefault1234,
          ),
          routeSettings: const RouteSettings(name: PinDialog.routeName),
        );
        if (pin != null) {
          final storedPin = await securityService.readValue(key);
          confirmed = storedPin != null ? pin == storedPin : pin == SettingsDefaults.pinDefaultPass;
        }
        break;
      case CommonLockType.password:
        final password = await showDialog<String>(
          context: context,
          builder: (context) => const PasswordDialog(needConfirmation: false),
          routeSettings: const RouteSettings(name: PasswordDialog.routeName),
        );
        if (password != null) {
          confirmed = password == await securityService.readValue(key);
        }
        break;
    }

    return confirmed;
  }

  Future<bool> setLockPass({
    required BuildContext context,
    required CommonLockType lockType,
    required String key,
    String? systemLocalizedReason,
  }) async {
    switch (lockType) {
      case CommonLockType.system:
        try {
          return await LocalAuthentication().authenticate(
            localizedReason: systemLocalizedReason ?? 'Authenticate to configure',
          );
        } on PlatformException catch (e, stack) {
          await showDialog(
            context: context,
            builder: (context) => AvesDialog(
              content: Text(e.message ?? 'An error occurred'),
              actions: const [OkButton()],
            ),
            routeSettings: const RouteSettings(name: AvesDialog.warningRouteName),
          );
          await reportService.recordError(e, stack);
        }
        break;
      case CommonLockType.pattern:
        final pattern = await showDialog<String>(
          context: context,
          builder: (context) => const PatternDialog(needConfirmation: true),
          routeSettings: const RouteSettings(name: PatternDialog.routeName),
        );
        if (pattern != null) {
          return await securityService.writeValue(key, pattern);
        }
        break;
      case CommonLockType.pin:
        final pin = await showDialog<String>(
          context: context,
          builder: (context) => const PinDialog(needConfirmation: true),
          routeSettings: const RouteSettings(name: PinDialog.routeName),
        );
        if (pin != null) {
          return await securityService.writeValue(key, pin);
        }
        break;
      case CommonLockType.password:
        final password = await showDialog<String>(
          context: context,
          builder: (context) => const PasswordDialog(needConfirmation: true),
          routeSettings: const RouteSettings(name: PasswordDialog.routeName),
        );
        if (password != null) {
          return await securityService.writeValue(key, password);
        }
        break;
    }
    return false;
  }
}
