// export and import
import 'package:aves/widgets/common/extensions/build_context.dart';
import 'package:flutter/cupertino.dart';

enum ShareByCopySetDateType {
  onlyThisTimeCopiedEntries,
  allCopiedEntries,
}

extension ExtraShareByCopySetDateType on ShareByCopySetDateType {
  String getName(BuildContext context) {
    final l10n = context.l10n;
    return switch (this) {
      ShareByCopySetDateType.onlyThisTimeCopiedEntries => l10n.shareByCopySetDateTypeOnlyThisTime,
      ShareByCopySetDateType.allCopiedEntries => l10n.shareByCopySetDateTypeAllCopiedEntries,
    };
  }
}

enum ShareByCopyRemoveSequence {
  removeBeforeCopy,
  removeAfterCopy,
}

extension ExtraShareByCopyRemoveSequence on ShareByCopyRemoveSequence {
  String getName(BuildContext context) {
    final l10n = context.l10n;
    return switch (this) {
      ShareByCopyRemoveSequence.removeBeforeCopy => l10n.shareByCopyRemoveBeforeCopy,
      ShareByCopyRemoveSequence.removeAfterCopy => l10n.shareByCopyRemoveAfterCopy,
    };
  }
}
