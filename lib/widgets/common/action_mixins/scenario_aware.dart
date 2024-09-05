import 'package:aves/model/scenario/enum/scenario_item.dart';
import 'package:aves/model/settings/modules/scenario.dart';
import 'package:aves/model/settings/settings.dart';
import 'package:aves/widgets/common/action_mixins/feedback.dart';
import 'package:aves/widgets/common/action_mixins/lock_service.dart';
import 'package:aves/widgets/common/extensions/build_context.dart';
import 'package:flutter/material.dart';

mixin ScenarioAwareMixin on FeedbackMixin {
  Future<bool> _tryUnlock(BuildContext context) async {
    final success = await lockService.tryUnlock(
      context: context,
      key: ScenarioSettings.scenarioLockPassKey,
      type: settings.scenarioLockType,
      systemLocalizedReason: context.l10n.authenticateToUnlockVault,
    );

    if (success != true) {
      showFeedback(context, FeedbackType.warn, context.l10n.genericFailureFeedback);
      return false;
    }

    settings.scenarioLock = false;
    return true;
  }

  Future<bool> unlockScenarios(BuildContext context) => _tryUnlock(context);

  void lockScenarios() => settings.scenarioLock = true;

  Future<bool> setScenarioLockPass(BuildContext context, CommonLockType lockType) {
    settings.scenarioLockType = lockType;
    return lockService.setLockPass(
      context: context,
      lockType: lockType,
      key: ScenarioSettings.scenarioLockPassKey,
      systemLocalizedReason: context.l10n.authenticateToConfigureVault,
    );
  }
}
