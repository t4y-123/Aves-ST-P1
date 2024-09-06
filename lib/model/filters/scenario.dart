import 'package:aves/model/covers.dart';
import 'package:aves/model/filters/filters.dart';
import 'package:aves/model/scenario/enum/scenario_item.dart';
import 'package:aves/model/scenario/scenario.dart';
import 'package:aves/model/scenario/scenario_step.dart';
import 'package:aves/model/settings/settings.dart';
import 'package:aves/theme/icons.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

class ScenarioFilter extends CoveredCollectionFilter {
  static const type = 'scenario';
  static const scenarioOpId = -1;
  static const scenarioAddNewItemId = -2;
  static const scenarioSettingId = -3;
  static const scenarioLockUnlockId = -4;

  final int scenarioId;
  final String displayName;
  late final EntryFilter _test;
  late final ScenarioRow? scenario;
  late final List<ScenarioStepRow>? steps;

  @override
  List<Object?> get props => [scenarioId, displayName, reversed];

  ScenarioFilter(this.scenarioId, this.displayName, {super.reversed = false}) {
    if (scenarioId >= 0) {
      scenario = scenarios.all.firstWhere((e) => e.id == scenarioId);
      steps = scenarioSteps.all.where((e) => e.scenarioId == scenarioId && e.isActive).toList();
      steps?.sort();

      _test = (entry) {
        if (steps == null && steps!.isEmpty) return true;

        bool result = true;
        bool isUnionOrTrue = false;
        bool isIntersectAndFalse = false;
        // t4y:
        // I want to make it more effective to skip test in step may not need.
        // if a entry is test true in a pre unionOr step, it should not need to test after unionOr step for it is already in.
        // unless it is make false by a intersectAnd step, it may be added by a after unionOr step.
        //
        // if a entry is test false in a pre intersectAnd step ,
        // it should not need test in after intersectAnd step for it is already get rid,
        // unless it is made true added by a unionOr step.

        for (var step in steps!) {
          bool needStepTest = false;
          bool stepResult = false;

          switch (step.loadType) {
            case ScenarioStepLoadType.unionOr:
              // Even if isUnionOrTrue is already true, we still need to evaluate further unionOr steps
              // isUnionOrTrue == false, means it is not add in pre union.
              //  isIntersectAndFalse == true mean it may be added in follow union.
              needStepTest = !isUnionOrTrue || isIntersectAndFalse;
              break;
            case ScenarioStepLoadType.intersectAnd:
              // Even if isIntersectAndFalse is true, we still need to evaluate further intersectAnd steps
              // isUnionOrTrue == true, means it is added in pre union.
              //  isIntersectAndFalse == false mean it is not be rid of in pre intersect.
              // if the same it need to test if need to remove in intersectAnd
              needStepTest = !isIntersectAndFalse || isUnionOrTrue;
              break;
          }

          if (needStepTest) {
            // Evaluate the filters for this step
            stepResult = step.filters!.isEmpty ? true : step.filters!.every((filter) => filter.test(entry));

            switch (step.loadType) {
              case ScenarioStepLoadType.unionOr:
                if (stepResult) isUnionOrTrue = true; // Track if unionOr condition was met
                result = stepResult || result; // Union: entry remains in if any unionOr is true
                break;

              case ScenarioStepLoadType.intersectAnd:
                if (!stepResult) isIntersectAndFalse = true; // Track if intersectAnd condition failed
                result = result && stepResult; // Intersection: entry is removed if any intersectAnd is false
                break;
            }
          }
        }
        return result;
      };
    } else {
      scenario = null;
      _test = (entry) => true;
    }
  }

  factory ScenarioFilter.fromMap(Map<String, dynamic> json) {
    return ScenarioFilter(
      json['scenario'],
      json['uniqueName'],
      reversed: json['reversed'] ?? false,
    );
  }

  @override
  Map<String, dynamic> toMap() => {
        'type': type,
        'scenario': scenarioId,
        'uniqueName': displayName,
        'reversed': reversed,
      };

  @override
  EntryFilter get positiveTest => _test;

  @override
  bool get exclusiveProp => false;

  @override
  String get universalLabel => displayName;

  @override
  String getTooltip(BuildContext context) => displayName;

  @override
  Widget? iconBuilder(BuildContext context, double size, {bool allowGenericIcon = true}) {
    if (scenarioId == scenarioSettingId) {
      return Icon(AIcons.settingScenario, size: size);
    } else if (scenarioId == scenarioAddNewItemId) {
      return Icon(AIcons.add, size: size);
    } else if (scenarioId == scenarioOpId) {
      return Icon(AIcons.opScenario, size: size);
    } else if (scenarioId == scenarioLockUnlockId) {
      return settings.scenarioLock ? Icon(AIcons.unlockScenario, size: size) : Icon(AIcons.lockScenario, size: size);
    }
    return switch (settings.scenarioPinnedExcludeFilters.contains(this) ||
        settings.scenarioPinnedIntersectFilters.contains(this) ||
        settings.scenarioPinnedUnionFilters.contains(this)) {
      true => Icon(AIcons.scenarioActive, size: size),
      false => Icon(AIcons.scenarioInactive, size: size),
    };
  }

  @override
  Future<Color> color(BuildContext context) {
    // custom color has precedence over others, even custom app color
    final customColor = covers.of(this)?.$3;
    if (customColor != null) return SynchronousFuture(customColor);
    // do not use async/await and rely on `SynchronousFuture`
    // to prevent rebuilding of the `FutureBuilder` listening on this future
    return super.color(context);
  }

  @override
  String get category => type;

  // key `scenario-{path}` is expected by test driver
  @override
  String get key => '$type-$reversed-$scenarioId';
}
