import 'dart:async';

import 'package:aves/app_flavor.dart';
import 'package:aves/model/entry/entry.dart';
import 'package:aves/model/entry/sort.dart';
import 'package:aves/model/fgw/enum/fgw_schedule_item.dart';
import 'package:aves/model/fgw/fgw_schedule_helper.dart';
import 'package:aves/model/fgw/fgw_used_entry_record.dart';
import 'package:aves/model/fgw/guard_level.dart';
import 'package:aves/model/fgw/wallpaper_schedule.dart';
import 'package:aves/model/settings/enums/widget_outline.dart';
import 'package:aves/model/settings/settings.dart';
import 'package:aves/model/source/collection_lens.dart';
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
  final filters = settings.getWidgetCollectionFilters(widgetId);
  debugPrint('foregroundWallpaperWidgetMainCommon filters ${filters}');
  debugPrint(
      'foregroundWallpaperWidgetMainCommon widgetId $widgetId settings.getWidgetCollectionFilters(widgetId) ${settings.getWidgetOpenPage(widgetId)}');
  final source = MediaStoreSource();
  final readyCompleter = Completer();
  source.stateNotifier.addListener(() {
    if (source.isReady) {
      readyCompleter.complete();
    }
  });
  await source.init(canAnalyze: false);
  await readyCompleter.future;

  final activeLevelIds = fgwGuardLevels.all.where((e) => e.isActive).map((e) => e.id);
  AvesEntry? fgwEntry;
  List<AvesEntry>? fgwEntries;
  if (activeLevelIds.contains(settings.curPrivacyGuardLevel)) {
    final curLevel = await fgwScheduleHelper.getCurGuardLevel();

    fgwEntries = await fgwScheduleHelper.getScheduleEntries(source, WallpaperUpdateType.widget,
        widgetId: widgetId, curPrivacyGuardLevel: curLevel);
  }

  if (fgwEntries != null && fgwEntries.isNotEmpty) {
    debugPrint(' foregroundWallpaperWidgetMainCommon Widget $widgetId entries length [${fgwEntries?.length}]\n');
    final recentUsedEntryRecord =
        await fgwScheduleHelper.getRecentEntryRecord(WallpaperUpdateType.widget, widgetId: widgetId);
    final curDisplayType = fgwSchedules.all
        .firstWhereOrNull((e) =>
            e.guardLevelId == settings.curPrivacyGuardLevel &&
            e.updateType == WallpaperUpdateType.widget &&
            e.widgetId == widgetId)
        ?.displayType;
    if (curDisplayType != null) {
      switch (curDisplayType) {
        case FgwDisplayedType.random:
          fgwEntries.shuffle();
        case FgwDisplayedType.mostRecent:
          fgwEntries.sort(AvesEntrySort.compareByDate);
      }
    }
    fgwEntry = fgwEntries.firstWhereOrNull(
      (entry) => !recentUsedEntryRecord.any((usedEntry) => usedEntry.entryId == entry.id),
    );
    debugPrint('Widget $widgetId recentUsedEntryRecord  fgwEntry length [${recentUsedEntryRecord.length}]\n');
    if (fgwEntry != null) {
      await fgwUsedEntryRecord.addAvesEntry(fgwEntry, WallpaperUpdateType.widget, widgetId: widgetId);
    }

    debugPrint('Widget $widgetId fgwEntry entries length [${fgwEntries.length}]\n'
        'fgwEntry: $fgwEntry');
  }
  if (fgwEntry == null) {
    final entries = CollectionLens(source: source, filters: filters).sortedEntries;
    debugPrint('fgwEntry == null in foregroundWallpaperWidgetMainCommon entries ${entries.length} '
        'settings.getWidgetDisplayedItem(widgetId) ${settings.getWidgetDisplayedItem(widgetId)}');
    switch (settings.getWidgetDisplayedItem(widgetId)) {
      case WidgetDisplayedItem.random:
        entries.shuffle();
      case WidgetDisplayedItem.mostRecent:
        entries.sort(AvesEntrySort.compareByDate);
    }
    final entry = entries.firstOrNull;
    if (entry != null) {
      settings.setWidgetUri(widgetId, entry.uri);
    }
    source.dispose();
    debugPrint('return in foregroundWallpaperWidgetMainCommon entry $entry');
    return entry;
  } else {
    debugPrint('return in foregroundWallpaperWidgetMainCommon entry $fgwEntry');
    return fgwEntry;
  }
}
