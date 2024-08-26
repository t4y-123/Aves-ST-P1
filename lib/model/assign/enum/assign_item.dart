import 'package:aves/widgets/common/extensions/build_context.dart';
import 'package:flutter/cupertino.dart';

//
enum AssignRecordType { permanent, temporary }

extension ExtraAssignRecordType on AssignRecordType {
  String getName(BuildContext context) {
    final l10n = context.l10n;
    return switch (this) {
      AssignRecordType.permanent => l10n.assignTypePermanent,
      AssignRecordType.temporary => l10n.assignTypeTemporary,
    };
  }
}

enum AssignTemporaryFollowAction { none, makeExclude, activeExclude, activeExcludeAndLock }

extension ExtraAssignTemporaryFollowAction on AssignTemporaryFollowAction {
  String getName(BuildContext context) {
    final l10n = context.l10n;
    return switch (this) {
      AssignTemporaryFollowAction.none => l10n.assignTemporaryFollowActionNone,
      AssignTemporaryFollowAction.makeExclude => l10n.assignTemporaryFollowActionMakeExclude,
      AssignTemporaryFollowAction.activeExclude => l10n.assignTemporaryFollowActionActiveExclude,
      AssignTemporaryFollowAction.activeExcludeAndLock => l10n.assignTemporaryFollowActionActiveAndLock,
    };
  }
}
