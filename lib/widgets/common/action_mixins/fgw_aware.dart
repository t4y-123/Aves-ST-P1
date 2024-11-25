import 'package:aves/model/scenario/enum/scenario_item.dart';
import 'package:aves/model/settings/modules/foreground_wallpaer.dart';
import 'package:aves/model/settings/settings.dart';
import 'package:aves/widgets/common/action_mixins/feedback.dart';
import 'package:aves/widgets/common/action_mixins/lock_service.dart';
import 'package:aves/widgets/common/extensions/build_context.dart';
import 'package:flutter/material.dart';

mixin FgwAwareMixin on FeedbackMixin {
  Future<bool> _tryUnlock(BuildContext context) async {
    final success = await lockService.tryUnlock(
      context: context,
      key: ForegroundWallpaperSettings.guardLevelLockPassKey,
      type: settings.guardLevelLockType,
      systemLocalizedReason: context.l10n.authenticateToUnlockVault,
    );

    if (success != true) {
      showFeedback(context, FeedbackType.warn, context.l10n.genericFailureFeedback);
      return false;
    }

    settings.guardLevelLock = false;
    return true;
  }

  Future<bool> unlockFgw(BuildContext context) => _tryUnlock(context);

  void lockFgw() => settings.scenarioLock = true;

  Future<bool> setFgwLockPass(BuildContext context, CommonLockType lockType) {
    settings.guardLevelLockType = lockType;
    return lockService.setLockPass(
      context: context,
      lockType: lockType,
      key: ForegroundWallpaperSettings.guardLevelLockPassKey,
      systemLocalizedReason: context.l10n.authenticateToUnlockVault,
    );
  }
}
