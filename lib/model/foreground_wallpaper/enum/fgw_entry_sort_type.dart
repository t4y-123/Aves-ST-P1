import 'package:aves/widgets/common/extensions/build_context.dart';
import 'package:flutter/widgets.dart';

enum FgwDisplayedType { random, mostRecent }

extension ExtraFgwDisplayedTypeView on FgwDisplayedType {
  String getName(BuildContext context) {
    final l10n = context.l10n;
    return switch (this) {
      FgwDisplayedType.random => l10n.fgwDisplayRandom,
      FgwDisplayedType.mostRecent => l10n.fgwDisplayMostRecentNotUsed,
    };
  }
}
