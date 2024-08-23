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
    }
    if (settings.scenarioPinnedExcludeFilters.isEmpty) {
      setExcludeScenarioFilterSetting(ScenarioFilter(scenarios.all.first.id, scenarios.all.first.labelName));
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
    const injNum = exNum + 6;
    const unUum = injNum + 10;
    return {
      //exclude unique
      await scenarios.newRow(exNum + 1, labelName: _l10n.excludeName01),
      await scenarios.newRow(exNum + 2, labelName: _l10n.excludeName02),
      await scenarios.newRow(exNum + 3, labelName: _l10n.excludeName03),
      await scenarios.newRow(exNum + 4, labelName: _l10n.excludeName04),
      await scenarios.newRow(exNum + 5, labelName: _l10n.excludeName05),
      await scenarios.newRow(exNum + 6, labelName: _l10n.excludeName06),
      //interject
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
      //union or
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
    int orderNum = 1;
    List<ScenarioStepRow> groupScenarioSteps = [
      //steps for /exclude unique
      //1/2/3/4 5
      // the 1 is for all entries.
      newScenarioStep(orderNum++, sIds[0], 1, {}),
      // the 2  is for all images without video.
      newScenarioStep(orderNum++, sIds[1], 1, {MimeFilter.image}),
      // the 3 is for all image  without share copied
      newScenarioStep(orderNum++, sIds[2], 1, {MimeFilter.image}),
      newScenarioStep(orderNum++, sIds[2], 2, {PathFilter(androidFileUtils.avesShareByCopyPath, reversed: true)}),
      //recent 3hours DCIM pic
      newScenarioStep(orderNum++, sIds[3], 1, {PathFilter(androidFileUtils.dcimPath)}),
      newScenarioStep(orderNum++, sIds[3], 2, {QueryFilter('TIME2NOW < 3h')}),
      // for share by copy exclude
      newScenarioStep(orderNum++, sIds[4], 1, {PathFilter(androidFileUtils.avesShareByCopyPath)}),
      // for video only exclude
      newScenarioStep(orderNum++, sIds[5], 1, {MimeFilter.video}),
      ////////////////////////////////////
      //steps for time interject and. 5-12 = 6-13,
      ///////////////////////////////////
      newScenarioStep(orderNum++, sIds[6], 1, {AspectRatioFilter.portrait}),
      newScenarioStep(orderNum++, sIds[7], 1, {AspectRatioFilter.landscape}),
      newScenarioStep(orderNum++, sIds[8], 1, {QueryFilter('TIME2NOW < 30mi')}),
      newScenarioStep(orderNum++, sIds[9], 1, {QueryFilter('TIME2NOW < 1h')}),
      newScenarioStep(orderNum++, sIds[10], 1, {QueryFilter('TIME2NOW < 3h')}),
      newScenarioStep(orderNum++, sIds[11], 1, {QueryFilter('TIME2NOW < 6h')}),
      newScenarioStep(orderNum++, sIds[12], 1, {QueryFilter('TIME2NOW < 9h')}),
      newScenarioStep(orderNum++, sIds[13], 1, {QueryFilter('TIME2NOW < 12h')}),
      newScenarioStep(orderNum++, sIds[14], 1, {QueryFilter('TIME2NOW < 1d')}),
      newScenarioStep(orderNum++, sIds[15], 1, {QueryFilter('TIME2NOW < 3d')}),
      ///////////////////////////////////
      //steps for some added dir or path,
      ///////////////////////////////////
      newScenarioStep(orderNum++, sIds[16], 1, {MimeFilter.video}),
      newScenarioStep(orderNum++, sIds[17], 1, {PathFilter(androidFileUtils.avesShareByCopyPath)}),
      newScenarioStep(orderNum++, sIds[18], 1, {PathFilter(androidFileUtils.picturesPath)}),
    ];
    await scenarioSteps.add(groupScenarioSteps.toSet());
  }

  ScenarioStepRow newScenarioStep(int orderOffset, int scenarioId, int stepOffset, Set<CollectionFilter>? filters,
      {ScenarioStepLoadType loadType = ScenarioStepLoadType.intersectAnd,
      bool isActive = true,
      ScenarioStepRowsType type = ScenarioStepRowsType.all}) {
    return scenarioSteps.newRow(
      existMaxOrderNumOffset: orderOffset,
      scenarioId: scenarioId,
      existMaxStepNumOffset: stepOffset,
      filters: filters,
      loadType: loadType,
      isActive: true,
      type: type,
    );
  }

  void setExcludeScenarioFilterSetting(ScenarioFilter filter) {
    final removeFilters = settings.scenarioPinnedExcludeFilters
        .where((e) => e is ScenarioFilter && e.scenario?.loadType == ScenarioLoadType.excludeUnique)
        .toSet();
    settings.scenarioPinnedExcludeFilters = settings.scenarioPinnedExcludeFilters
      ..removeAll(removeFilters)
      ..add(filter);
  }

  Future<List<ScenarioStepRow>> newScenarioStepsGroup(ScenarioRow baseRow,
      {ScenarioStepRowsType rowsType = ScenarioStepRowsType.all}) async {
    debugPrint('$runtimeType newScenarioStepsGroup start:\n$baseRow \n $rowsType ');
    List<ScenarioStepRow> newScenarioSteps = [
      newScenarioStep(1, baseRow.id, 1, {MimeFilter.image}, type: rowsType),
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
