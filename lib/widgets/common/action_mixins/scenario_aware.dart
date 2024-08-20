import 'package:aves/model/scenario/enum/scenario_item.dart';
import 'package:aves/model/settings/defaults.dart';
import 'package:aves/model/settings/modules/scenario.dart';
import 'package:aves/model/settings/settings.dart';
import 'package:aves/services/common/services.dart';
import 'package:aves/widgets/common/action_mixins/feedback.dart';
import 'package:aves/widgets/common/extensions/build_context.dart';
import 'package:aves/widgets/dialogs/aves_dialog.dart';
import 'package:aves/widgets/dialogs/filter_editors/password_dialog.dart';
import 'package:aves/widgets/dialogs/filter_editors/pattern_dialog.dart';
import 'package:aves/widgets/dialogs/filter_editors/pin_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/error_codes.dart' as auth_error;
import 'package:local_auth/local_auth.dart';

mixin ScenarioAwareMixin on FeedbackMixin {
  Future<bool> _tryUnlock(BuildContext context) async {
    bool? confirmed;
    switch (settings.scenarioLockType) {
      case ScenarioLockType.system:
        try {
          confirmed = await LocalAuthentication().authenticate(
            localizedReason: context.l10n.authenticateToUnlockVault,
          );
        } on PlatformException catch (e, stack) {
          if (!{'auth_in_progress', 'NotAvailable'}.contains(e.code)) {
            // `auth_in_progress`: `Authentication in progress`
            // `NotAvailable`: `Required security features not enabled`
            await reportService.recordError(e, stack);
          }
        }
      case ScenarioLockType.pattern:
        final pattern = await showDialog<String>(
          context: context,
          builder: (context) => const PatternDialog(needConfirmation: false),
          routeSettings: const RouteSettings(name: PatternDialog.routeName),
        );
        if (pattern != null) {
          confirmed = pattern == await securityService.readValue(ScenarioSettings.scenarioLockPassKey);
        }
      case ScenarioLockType.pin:
        final pin = await showDialog<String>(
          context: context,
          builder: (context) => PinDialog(
            needConfirmation: false,
            titleTxt: context.l10n.pinDialogEnterDefault1234,
          ),
          routeSettings: const RouteSettings(name: PinDialog.routeName),
        );
        if (pin != null) {
          final storedPin = await securityService.readValue(ScenarioSettings.scenarioLockPassKey);
          if (storedPin != null) {
            confirmed = pin == storedPin;
          } else {
            confirmed = pin == SettingsDefaults.scenarioLockDefaultPass;
          }
        }
      case ScenarioLockType.password:
        final password = await showDialog<String>(
          context: context,
          builder: (context) => const PasswordDialog(needConfirmation: false),
          routeSettings: const RouteSettings(name: PasswordDialog.routeName),
        );
        if (password != null) {
          confirmed = password == await securityService.readValue(ScenarioSettings.scenarioLockPassKey);
        }
    }

    if (confirmed == null || !confirmed) return false;
    settings.scenarioLock = false;
    return true;
  }

  Future<bool> unlockScenarios(BuildContext context) async {
    final success = await _tryUnlock(context);
    if (!success) {
      showFeedback(context, FeedbackType.warn, context.l10n.genericFailureFeedback);
    }
    return success;
  }

  void lockScenarios() => settings.scenarioLock = true;

  Future<bool> setScenarioLockPass(BuildContext context, ScenarioLockType lockType) async {
    switch (lockType) {
      case ScenarioLockType.system:
        final l10n = context.l10n;
        try {
          return await LocalAuthentication().authenticate(
            localizedReason: l10n.authenticateToConfigureVault,
          );
        } on PlatformException catch (e, stack) {
          await showDialog(
            context: context,
            builder: (context) => AvesDialog(
              content: Text(e.message ?? l10n.genericFailureFeedback),
              actions: const [OkButton()],
            ),
            routeSettings: const RouteSettings(name: AvesDialog.warningRouteName),
          );
          if (e.code != auth_error.notAvailable) {
            await reportService.recordError(e, stack);
          }
        }
      case ScenarioLockType.pattern:
        final pattern = await showDialog<String>(
          context: context,
          builder: (context) => const PatternDialog(needConfirmation: true),
          routeSettings: const RouteSettings(name: PatternDialog.routeName),
        );
        if (pattern != null) {
          return await securityService.writeValue(ScenarioSettings.scenarioLockPassKey, pattern);
        }
      case ScenarioLockType.pin:
        final pin = await showDialog<String>(
          context: context,
          builder: (context) => const PinDialog(needConfirmation: true),
          routeSettings: const RouteSettings(name: PinDialog.routeName),
        );
        if (pin != null) {
          return await securityService.writeValue(ScenarioSettings.scenarioLockPassKey, pin);
        }
      case ScenarioLockType.password:
        final password = await showDialog<String>(
          context: context,
          builder: (context) => const PasswordDialog(needConfirmation: true),
          routeSettings: const RouteSettings(name: PasswordDialog.routeName),
        );
        if (password != null) {
          return await securityService.writeValue(ScenarioSettings.scenarioLockPassKey, password);
        }
    }
    return false;
  }
}
