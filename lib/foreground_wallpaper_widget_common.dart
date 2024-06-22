import 'dart:async';

import 'package:aves/app_flavor.dart';
import 'package:aves/model/entry/entry.dart';
import 'package:aves/model/entry/sort.dart';
import 'package:aves/model/settings/enums/widget_outline.dart';
import 'package:aves/model/settings/settings.dart';
import 'package:aves/model/source/collection_lens.dart';
import 'package:aves/model/source/media_store_source.dart';
import 'package:aves/services/common/services.dart';
import 'package:aves/services/foreground_wallpaper_service.dart';
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
  await ForegroundWallpaperService.startService( );
  final widgetId = args['widgetId'] as int;
  final widthPx = args['widthPx'] as int;
  final heightPx = args['heightPx'] as int;
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
  final bytes = await painter.drawWidget(
    widthPx: widthPx,
    heightPx: heightPx,
    outline: outline,
    shape: settings.getWidgetShape(widgetId),
  );
  return {
    'bytes': bytes,
    'updateOnTap': settings.getWidgetOpenPage(widgetId) == WidgetOpenPage.updateWidget,
  };
}

Future<AvesEntry?> _getWidgetEntry(int widgetId, bool reuseEntry) async {
  final uri = reuseEntry ? settings.getWidgetUri(widgetId) : null;
  debugPrint('uri in foregroundWallpaperWidgetMainCommon _getWidgetEntry $uri');
  if (uri != null) {
    final entry = await mediaFetchService.getEntry(uri, null);
    if (entry != null) return entry;
  }

  await androidFileUtils.init();
  final filters = settings.getWidgetCollectionFilters(widgetId);
  final source = MediaStoreSource();
  final readyCompleter = Completer();
  source.stateNotifier.addListener(() {
    if (source.isReady) {
      readyCompleter.complete();
    }
  });
  await source.init(canAnalyze: false);
  await readyCompleter.future;

  final entries = CollectionLens(source: source, filters: filters).sortedEntries;

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
  return entry;
}
