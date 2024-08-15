import 'dart:async';
import 'dart:convert';

import 'package:aves/model/scenario/scenario.dart';
import 'package:aves/model/scenario/scenario_step.dart';
import 'package:collection/collection.dart';
import 'package:flutter/cupertino.dart';

import '../../l10n/l10n.dart';
import '../filters/aspect_ratio.dart';
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
    }
  }

  Future<void> clearScenarios() async {
    await scenarios.clear();
    await scenarioSteps.clear();
  }

  Future<Set<ScenarioRow>> commonScenarios(AppLocalizations _l10n) async {
    return {
      //exclude unique
      await scenarios.newRow(1,
          labelName: _l10n.initScenarioName01, color: scenarios.all.isEmpty ? const Color(0xFF808080) : null),
      await scenarios.newRow(2,
          labelName: _l10n.initScenarioName02, color: scenarios.all.isEmpty ? const Color(0xFF8D4FF8) : null),
      await scenarios.newRow(3,
          labelName: _l10n.initScenarioName03, color: scenarios.all.isEmpty ? const Color(0xFF2986cc) : null),
      //interject and
      await scenarios.newRow(4, labelName: _l10n.initScenarioName04, loadType: ScenarioLoadType.intersectAnd),
      await scenarios.newRow(5, labelName: _l10n.initScenarioName05, loadType: ScenarioLoadType.intersectAnd),
      await scenarios.newRow(6, labelName: _l10n.initScenarioName06, loadType: ScenarioLoadType.intersectAnd),
      //union or
      await scenarios.newRow(7, labelName: _l10n.initScenarioName07, loadType: ScenarioLoadType.unionOr),
      await scenarios.newRow(8, labelName: _l10n.initScenarioName08, loadType: ScenarioLoadType.unionOr),
      await scenarios.newRow(9, labelName: _l10n.initScenarioName09, loadType: ScenarioLoadType.unionOr),
    };
  }

  Future<void> addDefaultScenarios() async {
    _l10n = await AppLocalizations.delegate.load(settings.appliedLocale);
    final newScenarios = await commonScenarios(_l10n!);

    // must add first, for wallpaperSchedules.newRow will try to get item form them.
    await scenarios.add(newScenarios);

    final sIds = scenarios.all.map((e) => e.id).toList();
    //TODO: only make a group useless scenario and steps for go through the func.
    List<ScenarioStepRow> groupScenarioSteps = [
      newScenarioStep(1, sIds[0], 1, {MimeFilter.image}),
      // newScenarioStep(2, sIds[0], 2, {AspectRatioFilter.portrait}),
      // newScenarioStep(3, sIds[0], 3, {RecentlyAddedFilter.instance}),
      //
      newScenarioStep(4, sIds[1], 1, {MimeFilter.image}),
      newScenarioStep(5, sIds[1], 2, {AspectRatioFilter.portrait}),
      // newScenarioStep(6, sIds[1], 3, {RecentlyAddedFilter.instance}),
      //
      newScenarioStep(7, sIds[2], 1, {MimeFilter.image}),
      newScenarioStep(8, sIds[2], 2, {AspectRatioFilter.portrait}),
      newScenarioStep(9, sIds[2], 3, {RecentlyAddedFilter.instance}),
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

  // import/export
  Map<String, List<String>>? export() {
    final resultMap = Map.fromEntries(ScenarioExportItem.values.map((v) {
      final jsonMap = [jsonEncode(v.export())];
      return jsonMap != null ? MapEntry(v.name, jsonMap) : null;
    }).whereNotNull());
    return resultMap;
  }

  Future<void> import(dynamic jsonMap) async {
    debugPrint('foregroundWallpaperHelper import json Map $jsonMap');
    if (jsonMap is! Map) {
      debugPrint('failed to import privacy guard levels for jsonMap=$jsonMap');
      return;
    }
    await Future.forEach<ScenarioExportItem>(ScenarioExportItem.values, (item) async {
      debugPrint('\nFgwExportItem item $item ${jsonMap[item.name]}');
      return item.import(jsonDecode(jsonMap[item.name].toList().first));
    });
  }
}
