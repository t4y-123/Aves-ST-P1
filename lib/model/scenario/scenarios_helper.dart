import 'dart:async';
import 'dart:convert';

import 'package:aves/l10n/l10n.dart';
import 'package:aves/model/assign/assign_entries.dart';
import 'package:aves/model/assign/assign_record.dart';
import 'package:aves/model/assign/enum/assign_item.dart';
import 'package:aves/model/filters/aspect_ratio.dart';
import 'package:aves/model/filters/fgw_used.dart';
import 'package:aves/model/filters/filters.dart';
import 'package:aves/model/filters/mime.dart';
import 'package:aves/model/filters/path.dart';
import 'package:aves/model/filters/query.dart';
import 'package:aves/model/filters/scenario.dart';
import 'package:aves/model/presentation/base_bridge_row.dart';
import 'package:aves/model/scenario/enum/scenario_item.dart';
import 'package:aves/model/scenario/scenario.dart';
import 'package:aves/model/scenario/scenario_step.dart';
import 'package:aves/model/settings/settings.dart';
import 'package:aves/utils/android_file_utils.dart';
import 'package:collection/collection.dart';
import 'package:flutter/cupertino.dart';

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
      setExcludeDefaultFirst();
    }
    await assignRecords.init();
    await assignEntries.init();
    assignRecords.removeExpiredRecord();
  }

  void setExcludeDefaultFirst() {
    setExcludeScenarioFilterSetting(ScenarioFilter(
        scenarios.all.firstWhere((e) => e.loadType == ScenarioLoadType.excludeUnique).id,
        scenarios.all.first.labelName));
  }

  void removeScenarioPinnedFilters(Set<ScenarioRow> rows) {
    final rowsIds = rows.map((e) => e.id);
    final todoExclude =
        settings.scenarioPinnedExcludeFilters.where((e) => e is ScenarioFilter && rowsIds.contains(e.scenarioId));
    final todoInject =
        settings.scenarioPinnedIntersectFilters.where((e) => e is ScenarioFilter && rowsIds.contains(e.scenarioId));
    final todoUnion =
        settings.scenarioPinnedUnionFilters.where((e) => e is ScenarioFilter && rowsIds.contains(e.scenarioId));
    settings.scenarioPinnedExcludeFilters = settings.scenarioPinnedExcludeFilters..removeAll(todoExclude);
    settings.scenarioPinnedIntersectFilters = settings.scenarioPinnedIntersectFilters..removeAll(todoInject);
    settings.scenarioPinnedUnionFilters = settings.scenarioPinnedUnionFilters..removeAll(todoUnion);

    if (settings.scenarioPinnedExcludeFilters.isEmpty) setExcludeDefaultFirst();
  }

  Future<void> clearScenarios() async {
    await scenarios.clear();
    await scenarioSteps.clear();
    clearActivePinnedSettings();
  }

  void clearActivePinnedSettings() {
    settings.scenarioPinnedExcludeFilters = settings.scenarioPinnedExcludeFilters..clear();
    settings.scenarioPinnedIntersectFilters = settings.scenarioPinnedIntersectFilters..clear();
    settings.scenarioPinnedUnionFilters = settings.scenarioPinnedUnionFilters..clear();
  }

  Future<Set<ScenarioRow>> commonScenarios(AppLocalizations _l10n) async {
    const exNum = 0;
    const injNum = exNum + 7;
    const unUum = injNum + 5;
    return {
      //exclude unique
      await scenarios.newRow(exNum + 1, labelName: _l10n.excludeName01),
      await scenarios.newRow(exNum + 2, labelName: _l10n.excludeName02),
      await scenarios.newRow(exNum + 3, labelName: _l10n.excludeName03),
      await scenarios.newRow(exNum + 4, labelName: _l10n.excludeName04),
      await scenarios.newRow(exNum + 5, labelName: _l10n.excludeName05),
      await scenarios.newRow(exNum + 6, labelName: _l10n.excludeName06),
      await scenarios.newRow(exNum + 7, labelName: _l10n.excludeName07),
      //interject
      await scenarios.newRow(injNum + 1, labelName: _l10n.interjectName01, loadType: ScenarioLoadType.intersectAnd),
      await scenarios.newRow(injNum + 2, labelName: _l10n.interjectName02, loadType: ScenarioLoadType.intersectAnd),
      await scenarios.newRow(injNum + 3, labelName: _l10n.interjectName03, loadType: ScenarioLoadType.intersectAnd),
      await scenarios.newRow(injNum + 4, labelName: _l10n.interjectName04, loadType: ScenarioLoadType.intersectAnd),
      await scenarios.newRow(injNum + 5, labelName: _l10n.interjectName05, loadType: ScenarioLoadType.intersectAnd),

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
    const exNum = -1;
    const injNum = exNum + 7;
    const unUum = injNum + 5;
    List<ScenarioStepRow> groupScenarioSteps = [
      //steps for /exclude unique
      //1/2/3/4 5
      // the 1 is for all entries.
      newScenarioStep(orderNum++, sIds[exNum + 1], 1, {}),
      // the 2  is for all images without video.
      newScenarioStep(orderNum++, sIds[exNum + 2], 1, {MimeFilter.image}),
      // the 3 is for all image  without share copied
      newScenarioStep(orderNum++, sIds[exNum + 3], 1, {MimeFilter.image}),
      newScenarioStep(
          orderNum++, sIds[exNum + 3], 2, {PathFilter(androidFileUtils.avesShareByCopyPath, reversed: true)}),
      //recent 3hours DCIM pic
      newScenarioStep(orderNum++, sIds[exNum + 4], 1, {PathFilter(androidFileUtils.dcimPath)}),
      newScenarioStep(orderNum++, sIds[exNum + 4], 2, {QueryFilter('TIME2NOW < 3h')}),
      // for share by copy exclude
      newScenarioStep(orderNum++, sIds[exNum + 5], 1, {PathFilter(androidFileUtils.avesShareByCopyPath)}),
      // for video only exclude
      newScenarioStep(orderNum++, sIds[exNum + 6], 1, {MimeFilter.video}),
      newScenarioStep(orderNum++, sIds[exNum + 7], 1, {FgwUsedFilter()}),
      ////////////////////////////////////
      //steps for time interject and. 5-12 = 6-13,
      ///////////////////////////////////
      newScenarioStep(orderNum++, sIds[injNum + 1], 1, {AspectRatioFilter.portrait}),
      newScenarioStep(orderNum++, sIds[injNum + 2], 1, {AspectRatioFilter.landscape}),
      newScenarioStep(orderNum++, sIds[injNum + 3], 1, {QueryFilter('TIME2NOW < 6h')}),
      newScenarioStep(orderNum++, sIds[injNum + 4], 1, {QueryFilter('TIME2NOW < 12h')}),
      newScenarioStep(orderNum++, sIds[injNum + 5], 1, {QueryFilter('TIME2NOW < 3d')}),
      ///////////////////////////////////
      //steps for some added dir or path,
      ///////////////////////////////////
      newScenarioStep(orderNum++, sIds[unUum + 1], 1, {MimeFilter.video}),
      newScenarioStep(orderNum++, sIds[unUum + 2], 1, {PathFilter(androidFileUtils.avesShareByCopyPath)}),
      newScenarioStep(orderNum++, sIds[unUum + 3], 1, {PathFilter(androidFileUtils.picturesPath)}),
    ];
    await scenarioSteps.add(groupScenarioSteps.toSet());
  }

  ScenarioStepRow newScenarioStep(int orderOffset, int scenarioId, int stepOffset, Set<CollectionFilter>? filters,
      {ScenarioStepLoadType loadType = ScenarioStepLoadType.intersectAnd,
      bool isActive = true,
      PresentationRowType type = PresentationRowType.all}) {
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
      {PresentationRowType rowsType = PresentationRowType.all}) async {
    debugPrint('$runtimeType newScenarioStepsGroup start:\n$baseRow \n $rowsType ');
    List<ScenarioStepRow> newScenarioSteps = [
      newScenarioStep(1, baseRow.id, 1, {MimeFilter.image}, type: rowsType),
    ];
    debugPrint('newSchedulesGroup =\n $newScenarioSteps');
    return newScenarioSteps;
  }

  Future<Set<ScenarioStepRow>> getStepsOfScenario(
      {required ScenarioRow curScenario, PresentationRowType rowsType = PresentationRowType.all}) async {
    final targetSet = scenarioSteps.getAll(rowsType);
    final curSteps = targetSet.where((e) => e.scenarioId == curScenario.id).toSet();
    debugPrint('$runtimeType getStepsOfScenario \n curScenario $curScenario \n curSchedules :$curScenario');
    return curSteps;
  }

  Future<ScenarioRow> newScenarioByFilter(Set<CollectionFilter> filters,
      {PresentationRowType rowsType = PresentationRowType.all}) async {
    final stepRowsType = rowsType == PresentationRowType.all ? PresentationRowType.all : PresentationRowType.bridgeAll;
    final newScenario = await scenarios.newRow(1);
    await scenarios.add({newScenario}, type: rowsType);

    List<ScenarioStepRow> newScenarioSteps = [
      newScenarioStep(1, newScenario.id, 1, filters, type: stepRowsType),
    ];
    await scenarioSteps.add(newScenarioSteps.toSet(), type: stepRowsType);
    return newScenario;
  }

  Future<void> removeTemporaryAssignRows(Set<AssignRecordRow> rows,
      {PresentationRowType type = PresentationRowType.all}) async {
    // remove auto generate scenario of temporary assign.
    if (settings.autoRemoveCorrespondScenarioAsTempAssignRemove) {
      final removeScenarioIds = rows.where((e) => e.assignType == AssignRecordType.temporary).map((e) => e.scenarioId);
      switch (type) {
        case PresentationRowType.all:
          final todoScenarios = scenarios.all.where((e) => removeScenarioIds.contains(e.id)).toSet();
          await scenarios.removeRows(todoScenarios, type: PresentationRowType.all);
        case PresentationRowType.bridgeAll:
          final todoScenarios = scenarios.bridgeAll.where((e) => removeScenarioIds.contains(e.id)).toSet();
          await scenarios.removeRows(todoScenarios, type: PresentationRowType.bridgeAll);
      }
    }
    await assignRecords.removeRows(rows, type: type);
  }

  Future<void> removeTemporaryAssignScenarioRows(Set<ScenarioRow> rows,
      {PresentationRowType type = PresentationRowType.all}) async {
    // remove auto generate scenario of temporary assign.
    if (settings.autoRemoveTempAssignAsCorrespondScenarioRemove) {
      final candidateScenarioIds = rows.map((e) => e.id);

      switch (type) {
        case PresentationRowType.all:
          final toDoItems = assignRecords.all
              .where((e) => e.assignType == AssignRecordType.temporary && candidateScenarioIds.contains(e.scenarioId))
              .toSet();
          await assignRecords.removeRows(toDoItems, type: PresentationRowType.all);
        case PresentationRowType.bridgeAll:
          final toDoItems = assignRecords.bridgeAll
              .where((e) => e.assignType == AssignRecordType.temporary && candidateScenarioIds.contains(e.scenarioId))
              .toSet();
          await assignRecords.removeRows(toDoItems, type: PresentationRowType.bridgeAll);
      }
    }
    await scenarios.removeRows(rows, type: type);
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
