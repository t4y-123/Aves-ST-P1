import 'dart:async';

import 'package:aves/app_flavor.dart';
import 'package:aves/model/entry/entry.dart';
import 'package:aves/model/entry/sort.dart';
import 'package:aves/model/fgw/enum/fgw_schedule_item.dart';
import 'package:aves/model/fgw/fgw_used_entry_record.dart';
import 'package:aves/model/fgw/filters_set.dart';
import 'package:aves/model/fgw/guard_level.dart';
import 'package:aves/model/fgw/wallpaper_schedule.dart';
import 'package:aves/model/settings/enums/widget_outline.dart';
import 'package:aves/model/settings/settings.dart';
import 'package:aves/model/source/collection_lens.dart';
import 'package:aves/model/source/collection_source.dart';
import 'package:aves/model/source/media_store_source.dart';
import 'package:aves/services/common/services.dart';
import 'package:aves/utils/android_file_utils.dart';
import 'package:aves/widgets/home_widget.dart';
import 'package:aves_model/aves_model.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const _foregroundWallpaperWidgetDrawChannel = MethodChannel('deckers.thibault/aves/foreground_wallpaper_widget_draw');

void foregroundWallpaperWidgetMainCommon(AppFlavor flavor) async {
  WidgetsFlutterBinding.ensureInitialized();
  initPlatformServices();
  await settings.init(monitorPlatformSettings: false);
  await reportService.init();
  _foregroundWallpaperWidgetDrawChannel.setMethodCallHandler((call) async {
    // widget settings may be modified in a different process after channel setup
    await settings.reload();

    switch (call.method) {
      case 'drawWidget':
        return _drawWidget(call.arguments);
      default:
        throw PlatformException(code: 'not-implemented', message: 'failed to handle method=${call.method}');
    }
  });
  //await ForegroundWallpaperService.startService( );
}

Future<Map<String, dynamic>> _drawWidget(dynamic args) async {
  debugPrint('_drawWidget in foregroundWallpaperWidgetMainCommon $args');
  //await ForegroundWallpaperService.startService( );
  final widgetId = args['widgetId'] as int;
  final sizesDip = (args['sizesDip'] as List).cast<Map>().map((kv) {
    return Size(kv['widthDip'] as double, kv['heightDip'] as double);
  }).toList();
  final cornerRadiusPx = args['cornerRadiusPx'] as double?;
  final devicePixelRatio = args['devicePixelRatio'] as double;
  final drawEntryImage = args['drawEntryImage'] as bool;
  final reuseEntry = args['reuseEntry'] as bool;
  final isSystemThemeDark = args['isSystemThemeDark'] as bool;

  final brightness = isSystemThemeDark ? Brightness.dark : Brightness.light;
  final outline = await settings.getWidgetOutline(widgetId).color(brightness);

  final entry = drawEntryImage ? await _getWidgetEntry(widgetId, reuseEntry) : null;
  final painter = HomeWidgetPainter(
    entry: entry,
    devicePixelRatio: devicePixelRatio,
  );
  final bytesBySizeDip = <Map<String, dynamic>>[];
  await Future.forEach(sizesDip, (sizeDip) async {
    final bytes = await painter.drawWidget(
      sizeDip: sizeDip,
      cornerRadiusPx: cornerRadiusPx,
      outline: outline,
      shape: settings.getWidgetShape(widgetId),
    );
    bytesBySizeDip.add({
      'widthDip': sizeDip.width,
      'heightDip': sizeDip.height,
      'bytes': bytes,
    });
  });
  return {
    'bytesBySizeDip': bytesBySizeDip,
    'updateOnTap': settings.getWidgetOpenPage(widgetId) == WidgetOpenPage.updateWidget,
  };
}

Future<AvesEntry?> _getWidgetEntry(int widgetId, bool reuseEntry) async {
  final uri = reuseEntry ? settings.getWidgetUri(widgetId) : null;
  debugPrint('widgetId $widgetId foregroundWallpaperWidgetMainCommon _getWidgetEntry $uri');
  if (uri != null) {
    final entry = await mediaFetchService.getEntry(uri, null);
    if (entry != null) return entry;
  }

  await androidFileUtils.init();

  final source = MediaStoreSource();
  final readyCompleter = Completer();
  source.stateNotifier.addListener(() {
    if (source.isReady) {
      readyCompleter.complete();
    }
  });
  source.canAnalyze = false;
  await source.init(scope: CollectionSource.fullScope);
  await readyCompleter.future;
  try {
    final activeLevelNums = fgwGuardLevels.all.where((e) => e.isActive).map((e) => e.guardLevel);
    AvesEntry? fgwEntry;
    final curLevel = fgwGuardLevels.all.firstWhereOrNull((e) => e.guardLevel == settings.curFgwGuardLevelNum);
    debugPrint('$widgetId foregroundWallpaperWidgetMainCommon curLevel [${curLevel?.toMap()}]');

    if (activeLevelNums.contains(settings.curFgwGuardLevelNum)) {
      final curSchedule =
          fgwSchedules.all.firstWhereOrNull((e) => e.guardLevelId == curLevel?.id && e.widgetId == widgetId);
      if (curSchedule == null) {
        throw 'Failed to get curSchedule for widgetId $widgetId';
      }
      //debugPrint('$widgetId foregroundWallpaperWidgetMainCommon curSchedule [$curSchedule]');

      final curFilterSet = filtersSets.all.firstWhereOrNull((e) => e.id == curSchedule.filtersSetId);
      if (curFilterSet == null) {
        throw 'Failed to get curFilterSet for widgetId $widgetId';
      }
      //debugPrint('$widgetId foregroundWallpaperWidgetMainCommon curFilterSet [$curFilterSet]');

      final curFilters = curFilterSet.filters;
      //debugPrint('$widgetId foregroundWallpaperWidgetMainCommon curFilters [$curFilters]');

      final fgwEntries =
          CollectionLens(source: source, filters: curFilters, useScenario: settings.canScenarioAffectFgw).sortedEntries;
      //debugPrint('$widgetId foregroundWallpaperWidgetMainCommon fgwEntries ${fgwEntries.length}: [$fgwEntries]');

      if (fgwEntries.isNotEmpty) {
        switch (curSchedule.displayType) {
          case FgwDisplayedType.random:
            fgwEntries.shuffle();
            break;
          case FgwDisplayedType.mostRecent:
            fgwEntries.sort(AvesEntrySort.compareByDate);
            break;
        }

        final recentUsedEntryRecord =
            fgwUsedEntryRecord.all.where((e) => e.widgetId == widgetId && e.guardLevelId == curLevel?.id);
        // //debugPrint(
        //     '$widgetId foregroundWallpaperWidgetMainCommon recentUsedEntryRecord entries length [${recentUsedEntryRecord.length}]');

        fgwEntry = fgwEntries.firstWhereOrNull(
          (entry) => !recentUsedEntryRecord.any((usedEntry) => usedEntry.entryId == entry.id),
        );
        fgwEntry ??= fgwEntries.first;

        //debugPrint('$widgetId calling addAvesEntry fgwEntry: $fgwEntry');
        await fgwUsedEntryRecord.addAvesEntry(fgwEntry, WallpaperUpdateType.widget,
            widgetId: widgetId, curLevel: curLevel);

        debugPrint('$widgetId Widget fgwEntry found: $fgwEntry');
        settings.setWidgetUri(widgetId, fgwEntry.uri);
        return fgwEntry;
      }
    } else {
      debugPrint('Error in foregroundWallpaperWidgetMainCommon get active for widgetId $widgetId: $activeLevelNums');
    }
  } catch (e) {
    debugPrint('Error in foregroundWallpaperWidgetMainCommon get active for widgetId $widgetId: $e');
  }

  final filters = settings.getWidgetCollectionFilters(widgetId);

  final entries =
      CollectionLens(source: source, filters: filters, useScenario: settings.canScenarioAffectFgw).sortedEntries;

  switch (settings.getWidgetDisplayedItem(widgetId)) {
    case WidgetDisplayedItem.random:
      entries.shuffle();
      break;
    case WidgetDisplayedItem.mostRecent:
      entries.sort(AvesEntrySort.compareByDate);
      break;
  }

  final entry = entries.firstOrNull;
  if (entry != null) {
    settings.setWidgetUri(widgetId, entry.uri);
  }
  source.dispose();

  debugPrint('Attempting Returning normal entry for widgetId $widgetId: $entry '
      'foregroundWallpaperWidgetMainCommon getWidgetCollectionFilters:\n[ $filters ]');
  return entry;
}
