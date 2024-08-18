import 'package:aves/model/scenario/scenario_step.dart';
import 'package:aves/widgets/common/extensions/build_context.dart';
import 'package:aves/widgets/filter_grids/common/section_keys.dart';
import 'package:flutter/cupertino.dart';

import '../../../theme/icons.dart';
import '../scenario.dart';

enum ScenarioChipGroupFactor { unionBeforeIntersect, intersectBeforeUnion }

extension ExtraScenarioChipGroupFactorView on ScenarioChipGroupFactor {
  String getName(BuildContext context) {
    final l10n = context.l10n;
    return switch (this) {
      // ScenarioChipGroupFactor.importance => l10n.scenarioGroupImportance,
      ScenarioChipGroupFactor.unionBeforeIntersect => l10n.scenarioGroupUnionBeforeIntersect,
      ScenarioChipGroupFactor.intersectBeforeUnion => l10n.scenarioGroupIntersectBeforeUnion,
      // ScenarioChipGroupFactor.none => l10n.scenarioGroupNone,
    };
  }

  IconData get icon {
    return switch (this) {
      // ScenarioChipGroupFactor.importance => AIcons.important,
      ScenarioChipGroupFactor.unionBeforeIntersect => AIcons.mimeType,
      ScenarioChipGroupFactor.intersectBeforeUnion => AIcons.storageCard,
      // ScenarioChipGroupFactor.none => AIcons.clear,
    };
  }
}

enum ScenarioChipSortFactor { date, name, count, size }

//
enum ScenarioLoadType { excludeEach, unionOr, intersectAnd }

extension ExtraScenarioLoadTypeView on ScenarioLoadType {
  String getName(BuildContext context) {
    final l10n = context.l10n;
    return switch (this) {
      ScenarioLoadType.excludeEach => l10n.scenarioLoadTypeExclude,
      ScenarioLoadType.unionOr => l10n.scenarioLoadTypeUnion,
      ScenarioLoadType.intersectAnd => l10n.scenarioLoadTypeIntersect,
    };
  }
}

enum ScenarioStepLoadType { unionOr, intersectAnd }

enum ScenarioImportance { funcPinned, activePinned, excludeUnique, intersectAnd, unionOr }

extension ExtraScenarioImportance on ScenarioImportance {
  String getText(BuildContext context) {
    final l10n = context.l10n;
    return switch (this) {
      ScenarioImportance.funcPinned => l10n.scenarioTierFuncPinned,
      ScenarioImportance.activePinned => l10n.scenarioTierActivePinned,
      ScenarioImportance.excludeUnique => l10n.scenarioTierExcludeUnique,
      ScenarioImportance.intersectAnd => l10n.scenarioTierIntersectAnd,
      ScenarioImportance.unionOr => l10n.scenarioTierUnionOr,
    };
  }

  IconData getIcon() {
    return switch (this) {
      ScenarioImportance.funcPinned => AIcons.settings,
      ScenarioImportance.activePinned => AIcons.active,
      ScenarioImportance.excludeUnique => AIcons.scenarioExcludeUnique,
      ScenarioImportance.intersectAnd => AIcons.scenarioInjectAnd,
      ScenarioImportance.unionOr => AIcons.scenarioUnionOr,
    };
  }
}

class ScenarioImportanceSectionKey extends ChipSectionKey {
  final ScenarioImportance importance;

  ScenarioImportanceSectionKey._private(BuildContext context, this.importance)
      : super(title: importance.getText(context));

  factory ScenarioImportanceSectionKey.funcPinned(BuildContext context) =>
      ScenarioImportanceSectionKey._private(context, ScenarioImportance.funcPinned);

  factory ScenarioImportanceSectionKey.activePinned(BuildContext context) =>
      ScenarioImportanceSectionKey._private(context, ScenarioImportance.activePinned);

  factory ScenarioImportanceSectionKey.excludeUnique(BuildContext context) =>
      ScenarioImportanceSectionKey._private(context, ScenarioImportance.excludeUnique);

  factory ScenarioImportanceSectionKey.intersectAnd(BuildContext context) =>
      ScenarioImportanceSectionKey._private(context, ScenarioImportance.intersectAnd);

  factory ScenarioImportanceSectionKey.unionOr(BuildContext context) =>
      ScenarioImportanceSectionKey._private(context, ScenarioImportance.unionOr);
  @override
  Widget get leading => Icon(importance.getIcon());
}

// export and import
enum ScenarioExportItem { scenario, step }

extension ExtraScenarioExportItem on ScenarioExportItem {
  dynamic export() {
    return switch (this) {
      ScenarioExportItem.scenario => scenarios.export(),
      ScenarioExportItem.step => scenarioSteps.export(),
    };
  }

  Future<void> import(dynamic jsonMap) async {
    switch (this) {
      case ScenarioExportItem.scenario:
        await scenarios.import(jsonMap);
      case ScenarioExportItem.step:
        await scenarioSteps.import(jsonMap);
    }
  }
}
