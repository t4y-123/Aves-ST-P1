import 'dart:async';
import 'dart:convert';

import 'package:aves/model/filters/aspect_ratio.dart';
import 'package:aves/model/filters/path.dart';
import 'package:aves/model/filters/query.dart';
import 'package:aves/model/filters/scenario.dart';
import 'package:aves/model/scenario/scenario.dart';
import 'package:aves/model/scenario/scenario_step.dart';
import 'package:aves/utils/android_file_utils.dart';
import 'package:collection/collection.dart';
import 'package:flutter/cupertino.dart';

import '../../l10n/l10n.dart';
import '../filters/filters.dart';
import '../filters/mime.dart';
import '../filters/recent.dart';
import '../settings/settings.dart';
import 'enum/scenario_item.dart';

final ScenariosHelper scenariosHelper = ScenariosHelper._private();

class ScenariosHelper {
  ScenariosHelper._private();
  late AppLocalizations? _l10n;

  Future<void> initScenarios() async {
    _l10n = await AppLocalizations.delegate.load(settings.appliedLocale);
    await scenarios.init();
    await scenarioSteps.init();
    if (scenarioSteps.all.isEmpty || scenarios.all.isEmpty) {
      await addDefaultScenarios();
      settings.scenarioPinnedExcludeFilters = settings.scenarioPinnedExcludeFilters
        ..add(ScenarioFilter(scenarios.all.first.id, scenarios.all.first.labelName));
    }
  }

  Future<void> clearScenarios() async {
    await scenarios.clear();
    await scenarioSteps.clear();
    settings.scenarioPinnedExcludeFilters = settings.scenarioPinnedExcludeFilters..clear();
    settings.scenarioPinnedIntersectFilters = settings.scenarioPinnedIntersectFilters..clear();
    settings.scenarioPinnedUnionFilters = settings.scenarioPinnedUnionFilters..clear();
  }

  Future<Set<ScenarioRow>> commonScenarios(AppLocalizations _l10n) async {
    const exNum = 0;
    const injNum = 4;
    const unUum = 12;
    return {
      //exclude unique 1-4
      await scenarios.newRow(exNum + 1, labelName: _l10n.excludeName01),
      await scenarios.newRow(exNum + 2, labelName: _l10n.excludeName02),
      await scenarios.newRow(exNum + 3, labelName: _l10n.excludeName03),
      await scenarios.newRow(exNum + 4, labelName: _l10n.excludeName04),
      await scenarios.newRow(exNum + 4, labelName: _l10n.excludeName05),
      //interject and 5-12
      await scenarios.newRow(injNum + 1, labelName: _l10n.interjectName01, loadType: ScenarioLoadType.intersectAnd),
      await scenarios.newRow(injNum + 2, labelName: _l10n.interjectName02, loadType: ScenarioLoadType.intersectAnd),
      await scenarios.newRow(injNum + 3, labelName: _l10n.interjectName03, loadType: ScenarioLoadType.intersectAnd),
      await scenarios.newRow(injNum + 4, labelName: _l10n.interjectName04, loadType: ScenarioLoadType.intersectAnd),
      await scenarios.newRow(injNum + 5, labelName: _l10n.interjectName05, loadType: ScenarioLoadType.intersectAnd),
      await scenarios.newRow(injNum + 6, labelName: _l10n.interjectName06, loadType: ScenarioLoadType.intersectAnd),
      await scenarios.newRow(injNum + 7, labelName: _l10n.interjectName07, loadType: ScenarioLoadType.intersectAnd),
      await scenarios.newRow(injNum + 8, labelName: _l10n.interjectName08, loadType: ScenarioLoadType.intersectAnd),
      await scenarios.newRow(injNum + 9, labelName: _l10n.interjectName09, loadType: ScenarioLoadType.intersectAnd),
      await scenarios.newRow(injNum + 10, labelName: _l10n.interjectName10, loadType: ScenarioLoadType.intersectAnd),
      //union or 13-14
      await scenarios.newRow(unUum + 1, labelName: _l10n.unionName01, loadType: ScenarioLoadType.unionOr),
      await scenarios.newRow(unUum + 2, labelName: _l10n.unionName02, loadType: ScenarioLoadType.unionOr),
      await scenarios.newRow(unUum + 3, labelName: _l10n.unionName03, loadType: ScenarioLoadType.unionOr),
    };
  }

  Future<void> addDefaultScenarios() async {
    _l10n = await AppLocalizations.delegate.load(settings.appliedLocale);
    final newScenarios = await commonScenarios(_l10n!);

    // must add first, for wallpaperSchedules.newRow will try to get item form them.
    await scenarios.add(newScenarios);

    final sIds = scenarios.all.map((e) => e.id).toList();
    //TODO: only make a group useless scenario and steps for go through the func.
    int stepNum = 1;
    List<ScenarioStepRow> groupScenarioSteps = [
      //steps for /exclude unique
      //1/2/3/4 5
      newScenarioStep(stepNum++, sIds[0], 1, {}),
      newScenarioStep(stepNum++, sIds[1], 1, {MimeFilter.image}),
      newScenarioStep(stepNum++, sIds[2], 1, {PathFilter(androidFileUtils.dcimPath)}),
      //
      newScenarioStep(stepNum++, sIds[3], 1, {PathFilter(androidFileUtils.dcimPath)}),
      newScenarioStep(stepNum++, sIds[3], 2, {QueryFilter('TIME2NOW < 30MM')}),
      //
      newScenarioStep(stepNum++, sIds[4], 1, {PathFilter(androidFileUtils.avesShareByCopyPath)}),
      ////////////////////////////////////
      //steps for time interject and. 5-12 = 6-13,
      ///////////////////////////////////
      newScenarioStep(stepNum++, sIds[5], 1, {AspectRatioFilter.portrait}),
      newScenarioStep(stepNum++, sIds[6], 1, {AspectRatioFilter.landscape}),
      newScenarioStep(stepNum++, sIds[7], 1, {QueryFilter('TIME2NOW < 30MM')}),
      newScenarioStep(stepNum++, sIds[8], 1, {QueryFilter('TIME2NOW < 1HH')}),
      newScenarioStep(stepNum++, sIds[9], 1, {QueryFilter('TIME2NOW < 3HH')}),
      newScenarioStep(stepNum++, sIds[10], 1, {QueryFilter('TIME2NOW < 6HH')}),
      newScenarioStep(stepNum++, sIds[11], 1, {QueryFilter('TIME2NOW < 9HH')}),
      newScenarioStep(stepNum++, sIds[12], 1, {QueryFilter('TIME2NOW < 12HH')}),
      newScenarioStep(stepNum++, sIds[13], 1, {QueryFilter('TIME2NOW < 1D')}),
      newScenarioStep(stepNum++, sIds[14], 1, {QueryFilter('TIME2NOW < 3D')}),
      ///////////////////////////////////
      //steps for some added dir or path,
      ///////////////////////////////////
      newScenarioStep(stepNum++, sIds[15], 1, {MimeFilter.video}),
      newScenarioStep(stepNum++, sIds[16], 1, {PathFilter(androidFileUtils.avesShareByCopyPath)}),
      newScenarioStep(stepNum++, sIds[17], 1, {PathFilter(androidFileUtils.picturesPath)}),
    ];
    await scenarioSteps.add(groupScenarioSteps.toSet());
  }

  ScenarioStepRow newScenarioStep(int orderOffset, int scenarioId, int stepOffset, Set<CollectionFilter>? filters,
      [int? interval, bool isActive = true, ScenarioStepRowsType type = ScenarioStepRowsType.all]) {
    return scenarioSteps.newRow(
      existMaxOrderNumOffset: orderOffset,
      scenarioId: scenarioId,
      existMaxStepNumOffset: stepOffset,
      filters: filters,
      isActive: true,
      type: type,
    );
  }

  Future<List<ScenarioStepRow>> newScenarioStepsGroup(ScenarioRow baseRow,
      {ScenarioStepRowsType rowsType = ScenarioStepRowsType.all}) async {
    debugPrint('$runtimeType newScenarioStepsGroup start:\n$baseRow \n $rowsType ');
    List<ScenarioStepRow> newScenarioSteps = [
      newScenarioStep(1, baseRow.id, 1, {RecentlyAddedFilter.instance}),
    ];
    debugPrint('newSchedulesGroup =\n $newScenarioSteps');
    return newScenarioSteps;
  }

  Future<Set<ScenarioStepRow>> getStepsOfScenario(
      {required ScenarioRow curScenario, ScenarioStepRowsType rowsType = ScenarioStepRowsType.all}) async {
    final targetSet = scenarioSteps.getAll(rowsType);
    final curSteps = targetSet.where((e) => e.scenarioId == curScenario.id).toSet();
    debugPrint('$runtimeType getStepsOfScenario \n curScenario $curScenario \n curSchedules :$curScenario');
    return curSteps;
  }

  // import/export
  Map<String, List<String>>? export() {
    final resultMap = Map.fromEntries(ScenarioExportItem.values.map((v) {
      final jsonMap = [jsonEncode(v.export())];
      return jsonMap != null ? MapEntry(v.name, jsonMap) : null;
    }).whereNotNull());
    return resultMap;
  }

  Future<void> import(dynamic jsonMap) async {
    debugPrint('scenario import json Map $jsonMap');
    if (jsonMap is! Map) {
      debugPrint('failed to import scenario for jsonMap=$jsonMap');
      return;
    }
    await Future.forEach<ScenarioExportItem>(ScenarioExportItem.values, (item) async {
      debugPrint('\n ScenarioExportItem item $item ${jsonMap[item.name]}');
      return item.import(jsonDecode(jsonMap[item.name].toList().first));
    });
  }
}
