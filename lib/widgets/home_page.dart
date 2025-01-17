import 'dart:async';

import 'package:aves/app_mode.dart';
import 'package:aves/geo/uri.dart';
import 'package:aves/model/app/intent.dart';
import 'package:aves/model/app/permissions.dart';
import 'package:aves/model/app_inventory.dart';
import 'package:aves/model/entry/entry.dart';
import 'package:aves/model/entry/extensions/catalog.dart';
import 'package:aves/model/fgw/enum/fgw_schedule_item.dart';
import 'package:aves/model/fgw/enum/fgw_service_item.dart';
import 'package:aves/model/fgw/fgw_schedule_helper.dart';
import 'package:aves/model/fgw/fgw_used_entry_record.dart';
import 'package:aves/model/fgw/filters_set.dart';
import 'package:aves/model/fgw/guard_level.dart';
import 'package:aves/model/fgw/share_copied_entry.dart';
import 'package:aves/model/fgw/wallpaper_schedule.dart';
import 'package:aves/model/filters/album.dart';
import 'package:aves/model/filters/fgw_used.dart';
import 'package:aves/model/filters/filters.dart';
import 'package:aves/model/filters/location.dart';
import 'package:aves/model/filters/path.dart';
import 'package:aves/model/settings/enums/home_page.dart';
import 'package:aves/model/settings/settings.dart';
import 'package:aves/model/source/collection_lens.dart';
import 'package:aves/model/source/collection_source.dart';
import 'package:aves/services/analysis_service.dart';
import 'package:aves/services/common/services.dart';
import 'package:aves/services/fgw_service_handler.dart';
import 'package:aves/services/fgw_widget_service.dart';
import 'package:aves/services/global_search.dart';
import 'package:aves/services/intent_service.dart';
import 'package:aves/services/widget_service.dart';
import 'package:aves/theme/themes.dart';
import 'package:aves/utils/android_file_utils.dart';
import 'package:aves/widgets/collection/collection_page.dart';
import 'package:aves/widgets/collection/entry_set_action_delegate.dart';
import 'package:aves/widgets/common/action_mixins/feedback.dart';
import 'package:aves/widgets/common/action_mixins/fgw_aware.dart';
import 'package:aves/widgets/common/basic/scaffold.dart';
import 'package:aves/widgets/common/behaviour/routes.dart';
import 'package:aves/widgets/common/extensions/build_context.dart';
import 'package:aves/widgets/common/search/page.dart';
import 'package:aves/widgets/common/search/route.dart';
import 'package:aves/widgets/editor/entry_editor_page.dart';
import 'package:aves/widgets/explorer/explorer_page.dart';
import 'package:aves/widgets/filter_grids/albums_page.dart';
import 'package:aves/widgets/filter_grids/assign_page.dart';
import 'package:aves/widgets/filter_grids/tags_page.dart';
import 'package:aves/widgets/map/map_page.dart';
import 'package:aves/widgets/search/search_delegate.dart';
import 'package:aves/widgets/settings/fgw_widget_settings_page.dart';
import 'package:aves/widgets/settings/home_widget_settings_page.dart';
import 'package:aves/widgets/settings/screen_saver_settings_page.dart';
import 'package:aves/widgets/viewer/entry_viewer_page.dart';
import 'package:aves/widgets/viewer/screen_saver_page.dart';
import 'package:aves/widgets/wallpaper_page.dart';
import 'package:aves_model/aves_model.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

class HomePage extends StatefulWidget {
  static const routeName = '/';

  // untyped map as it is coming from the platform
  final Map? intentData;

  const HomePage({
    super.key,
    this.intentData,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with FeedbackMixin, FgwAwareMixin {
  AvesEntry? _viewerEntry;
  int? _widgetId;
  String? _initialRouteName, _initialSearchQuery;
  Set<CollectionFilter>? _initialFilters;
  String? _initialExplorerPath;
  (LatLng, double?)? _initialLocationZoom;
  List<String>? _secureUris;
  FgwServiceOpenType? _fgwOpenType;

  static const allowedShortcutRoutes = [
    AlbumListPage.routeName,
    CollectionPage.routeName,
    ExplorerPage.routeName,
    MapPage.routeName,
    SearchPage.routeName,
    AssignListPage.routeName,
  ];

  @override
  void initState() {
    super.initState();
    _setup();
    imageCache.maximumSizeBytes = 512 * (1 << 20);
  }

  @override
  Widget build(BuildContext context) => const AvesScaffold();

  Future<void> _setup() async {
    final stopwatch = Stopwatch()..start();
    if (await windowService.isActivity()) {
      // do not check whether permission was granted, because some app stores
      // hide in some countries apps that force quit on permission denial
      await Permissions.mediaAccess.request();
    }

    var appMode = AppMode.main;
    var error = false;
    final intentData = widget.intentData ?? await IntentService.getIntentData();
    final intentAction = intentData[IntentDataKeys.action] as String?;
    _initialFilters = null;
    _initialExplorerPath = null;
    _secureUris = null;

    await availability.onNewIntent();
    await androidFileUtils.init();
    if (!{
          IntentActions.edit,
          IntentActions.screenSaver,
          IntentActions.setWallpaper,
        }.contains(intentAction) &&
        settings.isInstalledAppAccessAllowed) {
      unawaited(appInventory.initAppNames());
    }

    if (intentData.values.nonNulls.isNotEmpty) {
      await reportService.log('Intent data=$intentData');
      var intentUri = intentData[IntentDataKeys.uri] as String?;
      final intentMimeType = intentData[IntentDataKeys.mimeType] as String?;

      switch (intentAction) {
        case IntentActions.view:
          appMode = AppMode.view;
          _secureUris = (intentData[IntentDataKeys.secureUris] as List?)?.cast<String>();
        case IntentActions.viewGeo:
          error = true;
          if (intentUri != null) {
            final locationZoom = parseGeoUri(intentUri);
            if (locationZoom != null) {
              _initialRouteName = MapPage.routeName;
              _initialLocationZoom = locationZoom;
              error = false;
            }
          }
          break;
        case IntentActions.edit:
          appMode = AppMode.edit;
        case IntentActions.setWallpaper:
          appMode = AppMode.setWallpaper;
        case IntentActions.pickItems:
          // TODO TLAD apply pick mimetype(s)
          // some apps define multiple types, separated by a space (maybe other signs too, like `,` `;`?)
          final multiple = (intentData[IntentDataKeys.allowMultiple] as bool?) ?? false;
          debugPrint('pick mimeType=$intentMimeType multiple=$multiple');
          appMode = multiple ? AppMode.pickMultipleMediaExternal : AppMode.pickSingleMediaExternal;
        case IntentActions.pickCollectionFilters:
          appMode = AppMode.pickCollectionFiltersExternal;
        case IntentActions.screenSaver:
          appMode = AppMode.screenSaver;
          _initialRouteName = ScreenSaverPage.routeName;
        case IntentActions.screenSaverSettings:
          _initialRouteName = ScreenSaverSettingsPage.routeName;
        case IntentActions.search:
          _initialRouteName = SearchPage.routeName;
          _initialSearchQuery = intentData[IntentDataKeys.query] as String?;
        case IntentActions.widgetSettings:
          _initialRouteName = HomeWidgetSettingsPage.routeName;
          _widgetId = (intentData[IntentDataKeys.widgetId] as int?) ?? 0;
        case IntentActions.widgetOpen:
        case IntentActions.fgwWidgetOpen:
          final widgetId = intentData[IntentDataKeys.widgetId] as int?;
          if (widgetId == null) {
            error = true;
          } else {
            // widget settings may be modified in a different process after channel setup
            await settings.reload();
            final page = settings.getWidgetOpenPage(widgetId);
            switch (page) {
              case WidgetOpenPage.collection:
                _initialFilters = settings.getWidgetCollectionFilters(widgetId);
              case WidgetOpenPage.viewer:
                appMode = AppMode.view;
                intentUri = settings.getWidgetUri(widgetId);
              case WidgetOpenPage.home:
              case WidgetOpenPage.updateWidget:
                break;
            }
            // t4y: for foreground update diff.
            if (intentAction == IntentActions.widgetOpen) {
              if (page == WidgetOpenPage.updateWidget || settings.widgetUpdateWhenOpen) {
                unawaited(WidgetService.update(widgetId));
              }
            } else if (intentAction == IntentActions.fgwWidgetOpen) {
              if (page == WidgetOpenPage.updateWidget || settings.widgetUpdateWhenOpen) {
                unawaited(ForegroundWallpaperWidgetService.update(widgetId));
              }
            }
          }
        case IntentActions.fgwUsedRecordOpen:
          appMode = AppMode.main;
          _fgwOpenType = FgwServiceOpenType.usedRecord;
          // for it may change in fgw notification.
          await settings.reload();
        case IntentActions.fgwViewOpen:
        case IntentActions.fgwDuplicateOpen:
          await settings.reload();
          debugPrint('$runtimeType get into IntentActions $intentAction');
          _viewerEntry = await _initViewerEntry(
            uri: settings.getFgwCurEntryUri(WallpaperUpdateType.home, 0),
            mimeType: settings.getFgwCurEntryMime(WallpaperUpdateType.home, 0),
          );
          if (_viewerEntry != null) {
            switch (intentAction) {
              case IntentActions.fgwViewOpen:
                appMode = AppMode.view;
                _fgwOpenType = FgwServiceOpenType.curFilters;
              case IntentActions.fgwDuplicateOpen:
                appMode = AppMode.main;
                _fgwOpenType = FgwServiceOpenType.shareByCopy;
                _initialFilters = {PathFilter(androidFileUtils.avesShareByCopyPath)};
                _initialRouteName = CollectionPage.routeName;
              default:
                break;
            }
          }
        //debugPrint('$runtimeType fgw intentActions $intentAction appMode $appMode');

        case IntentActions.fgwWidgetSettings:
          _initialRouteName = FgwWidgetSettings.routeName;
          _widgetId = intentData[IntentDataKeys.widgetId] ?? 0;
        case IntentActions.fgwUnlock:
          await settings.reload();
          //debugPrint('$runtimeType await unlockFgw(context)): ${settings.guardLevelLock}');
          if (!await unlockFgw(context)) {
            settings.guardLevelLock = true;
          } else {
            settings.guardLevelLock = false;
            await ForegroundWallpaperService.setFgwGuardLevelLockState(settings.guardLevelLock);
            // debugPrint( $runtimeType  ForegroundWallpaperService.setFgwGuardLevelLockState; ${settings.guardLevelLock}');
          }
        default:
          // do not use 'route' as extra key, as the Flutter framework acts on it
          final extraRoute = intentData[IntentDataKeys.page] as String?;
          if (allowedShortcutRoutes.contains(extraRoute)) {
            _initialRouteName = extraRoute;
          }
      }
      if (_initialFilters == null) {
        final extraFilters = (intentData[IntentDataKeys.filters] as List?)?.cast<String>();
        _initialFilters = extraFilters?.map(CollectionFilter.fromJson).nonNulls.toSet();
      }
      _initialExplorerPath = intentData[IntentDataKeys.explorerPath] as String?;

      switch (appMode) {
        case AppMode.view:
        case AppMode.edit:
        case AppMode.setWallpaper:
          if (intentUri != null) {
            _viewerEntry = await _initViewerEntry(
              uri: intentUri,
              mimeType: intentMimeType,
            );
          }
          error = _viewerEntry == null;
        default:
          break;
      }
    }

    if (error) {
      debugPrint('Failed to init app mode=$appMode for intent data=$intentData. Fallback to main mode.');
      appMode = AppMode.main;
    }

    context.read<ValueNotifier<AppMode>>().value = appMode;
    unawaited(reportService.setCustomKey('app_mode', appMode.toString()));

    switch (appMode) {
      case AppMode.main:
      case AppMode.pickCollectionFiltersExternal:
      case AppMode.pickSingleMediaExternal:
      case AppMode.pickMultipleMediaExternal:
        unawaited(GlobalSearch.registerCallback());
        unawaited(AnalysisService.registerCallback());
        final source = context.read<CollectionSource>();
        if (source.loadedScope != CollectionSource.fullScope) {
          await reportService
              .log('Initialize source to start app with mode=$appMode, loaded scope=${source.loadedScope}');
          final loadTopEntriesFirst =
              settings.homePage == HomePageSetting.collection && settings.homeCustomCollection.isEmpty;
          source.canAnalyze = true;
          await source.init(scope: CollectionSource.fullScope, loadTopEntriesFirst: loadTopEntriesFirst);
        }
      case AppMode.screenSaver:
        await reportService.log('Initialize source to start screen saver');
        final source = context.read<CollectionSource>();
        source.canAnalyze = false;
        await source.init(scope: settings.screenSaverCollectionFilters);
      case AppMode.view:
        if (_isViewerSourceable(_viewerEntry) && _secureUris == null) {
          final directory = _viewerEntry?.directory;
          if (directory != null) {
            unawaited(AnalysisService.registerCallback());
            await reportService.log('Initialize source to view item in directory $directory');
            final source = context.read<CollectionSource>();
            source.canAnalyze = false;
            await source.init(scope: {AlbumFilter(directory, null)});
          }
        } else {
          await _initViewerEssentials();
        }
      case AppMode.edit:
      case AppMode.setWallpaper:
        await _initViewerEssentials();
      default:
        break;
    }

    debugPrint('Home setup complete in ${stopwatch.elapsed.inMilliseconds}ms');
    if (intentAction == IntentActions.fgwWidgetOpen) {
      final widgetId = intentData[IntentDataKeys.widgetId] as int?;
      final curGuardLevel = fgwGuardLevels.all.firstWhereOrNull((e) => e.guardLevel == settings.curFgwGuardLevelNum);
      //debugPrint('IntentActions.foregroundWallpaperWidgetOpen curGuardLevel $curGuardLevel\n$uri');

      if (curGuardLevel != null) {
        final curWidgetSchedule =
            fgwSchedules.all.firstWhereOrNull((e) => e.guardLevelId == curGuardLevel.id && widgetId == widgetId);
        if (curWidgetSchedule != null) {
          final curFiltersSet = filtersSets.all.firstWhereOrNull((e) => e.id == curWidgetSchedule.filtersSetId);
          if (curFiltersSet != null) {
            _initialFilters = curFiltersSet.filters;
            //debugPrint('IntentActions.foregroundWallpaperWidgetOpen _initialFilters $_initialFilters');
          }
        }
      }
    }
    // `pushReplacement` is not enough in some edge cases
    // e.g. when opening the viewer in `view` mode should replace a viewer in `main` mode
    unawaited(Navigator.maybeOf(context)?.pushAndRemoveUntil(
      await _getRedirectRoute(appMode),
      (route) => false,
    ));
  }

  Future<void> _initViewerEssentials() async {
    // for video playback storage
    await localMediaDb.init();
  }

  bool _isViewerSourceable(AvesEntry? viewerEntry) {
    return viewerEntry != null &&
        viewerEntry.directory != null &&
        !settings.hiddenFilters.any((filter) => filter.test(viewerEntry));
  }

  Future<AvesEntry?> _initViewerEntry({required String uri, required String? mimeType}) async {
    if (uri.startsWith('/')) {
      // convert this file path to a proper URI
      uri = Uri.file(uri).toString();
    }
    final entry = await mediaFetchService.getEntry(uri, mimeType);
    if (entry != null) {
      // cataloguing is essential for coordinates and video rotation
      await entry.catalog(background: false, force: false, persist: false);
    }
    return entry;
  }

  Future<Route> _getRedirectRoute(AppMode appMode) async {
    String routeName;
    Set<CollectionFilter?>? filters;
    switch (appMode) {
      case AppMode.pickSingleMediaExternal:
      case AppMode.pickMultipleMediaExternal:
        routeName = CollectionPage.routeName;
      case AppMode.setWallpaper:
        return DirectMaterialPageRoute(
          settings: const RouteSettings(name: WallpaperPage.routeName),
          builder: (_) {
            return WallpaperPage(
              entry: _viewerEntry,
            );
          },
        );
      case AppMode.view:
        AvesEntry viewerEntry = _viewerEntry!;
        CollectionLens? collection;

        final source = context.read<CollectionSource>();
        final album = viewerEntry.directory;
        if (album != null) {
          // wait for collection to pass the `loading` state
          final loadingCompleter = Completer();
          final stateNotifier = source.stateNotifier;
          void _onSourceStateChanged() {
            if (stateNotifier.value != SourceState.loading) {
              stateNotifier.removeListener(_onSourceStateChanged);
              loadingCompleter.complete();
            }
          }

          stateNotifier.addListener(_onSourceStateChanged);
          _onSourceStateChanged();
          await loadingCompleter.future;

          // collection = CollectionLens(
          //   source: source,
          //   filters: {AlbumFilter(album, source.getAlbumDisplayName(context, album))},
          //   listenToSource: false,
          //   // if we group bursts, opening a burst sub-entry should:
          //   // - identify and select the containing main entry,
          //   // - select the sub-entry in the Viewer page.
          //   stackBursts: false,
          // );

          switch (_fgwOpenType) {
            case null:
            case FgwServiceOpenType.usedRecord:
            case FgwServiceOpenType.shareByCopy:
              final album = viewerEntry.directory;
              if (album != null) {
                collection = CollectionLens(
                  source: source,
                  filters: {AlbumFilter(album, source.getAlbumDisplayName(context, album))},
                  listenToSource: false,
                  // if we group bursts, opening a burst sub-entry should:
                  // - identify and select the containing main entry,
                  // - select the sub-entry in the Viewer page.
                  stackBursts: false,
                );
              }
            case FgwServiceOpenType.curFilters:
              Set<CollectionFilter> filters = {};
              // if (_fgwOpenType == FgwServiceOpenType.usedRecord) {
              //   final curLevel = await fgwScheduleHelper.getCurGuardLevel();
              //   filters = {FgwUsedFilter(guardLevelId: curLevel.guardLevel)};
              // } else {
              filters = await fgwScheduleHelper.getScheduleFilters(WallpaperUpdateType.home);
              // }
              debugPrint('$runtimeType  FgwServiceOpenType [$_fgwOpenType] filters= [$filters]');
              collection = CollectionLens(
                source: source,
                filters: filters,
                listenToSource: false,
                // if we group bursts, opening a burst sub-entry should:
                // - identify and select the containing main entry,
                // - select the sub-entry in the Viewer page.
                stackBursts: false,
              );
              debugPrint('$runtimeType AppMode.fgwViewUsed collection:\n $collection');
          }

          final viewerEntryPath = viewerEntry.path;
          final collectionEntry = collection?.sortedEntries.firstWhereOrNull((entry) => entry.path == viewerEntryPath);
          if (collectionEntry != null) {
            viewerEntry = collectionEntry;
          } else {
            debugPrint('collection does not contain viewerEntry=$viewerEntry');
            collection = null;
          }
        }

        return DirectMaterialPageRoute(
          settings: const RouteSettings(name: EntryViewerPage.routeName),
          builder: (_) {
            return EntryViewerPage(
              collection: collection,
              initialEntry: viewerEntry,
            );
          },
        );
      case AppMode.edit:
        return DirectMaterialPageRoute(
          settings: const RouteSettings(name: EntryViewerPage.routeName),
          builder: (_) {
            return ImageEditorPage(
              entry: _viewerEntry!,
            );
          },
        );
      default:
        routeName = _initialRouteName ?? settings.homePage.routeName;
        filters =
            _initialFilters ?? (settings.homePage == HomePageSetting.collection ? settings.homeCustomCollection : {});
    }
    Route buildRoute(WidgetBuilder builder) => DirectMaterialPageRoute(
          settings: RouteSettings(name: routeName),
          builder: builder,
        );

    final source = context.read<CollectionSource>();
    // t4y: add for fgw.
    debugPrint('$runtimeType ${appMode}) _fgwOpenType $_fgwOpenType');
    switch (_fgwOpenType) {
      case null:
      case FgwServiceOpenType.curFilters:
      case FgwServiceOpenType.usedRecord:
        await fgwUsedEntryRecord.refresh();
        if (_fgwOpenType == FgwServiceOpenType.usedRecord) {
          final curLevel = fgwGuardLevels.all.firstWhereOrNull((e) => e.guardLevel == settings.curFgwGuardLevelNum);
          _initialFilters = {FgwUsedFilter(guardLevelId: curLevel?.id)};
          filters = _initialFilters;
          routeName = CollectionPage.routeName;
        }
        break;
      case FgwServiceOpenType.shareByCopy:
        if (_viewerEntry != null) {
          await shareCopiedEntries.init();
          debugPrint('AppMode.fgwShareByCopy shareCopiedEntries $shareCopiedEntries');
          source.pauseMonitoring();
          final entriesByDestination = <String, Set<AvesEntry>>{};
          final entries = {_viewerEntry!};
          // t4y: for every time only copy one entry,
          // it is more natural not remove pre copied to accumulate more item to share.
          await EntrySetActionDelegate().doMove(context,
              moveType: MoveType.shareByCopy,
              entries: entries,
              shareByCopyNeedRemove:
                  settings.shareByCopyExpiredAutoRemove && settings.shareByCopyAppModeViewAutoRemove);

          entriesByDestination[androidFileUtils.avesShareByCopyPath] = entries;
          debugPrint('AppMode.fgwShareByCopy shareCopiedEntries $shareCopiedEntries');
        }
    }
    // t4y end
    switch (routeName) {
      case AlbumListPage.routeName:
        return buildRoute((context) => const AlbumListPage());
      case TagListPage.routeName:
        return buildRoute((context) => const TagListPage());
      case AssignListPage.routeName:
        return buildRoute((context) => const AssignListPage());
      case MapPage.routeName:
        return buildRoute((context) {
          final mapCollection = CollectionLens(
            source: source,
            filters: {
              LocationFilter.located,
              if (filters != null) ...filters,
            },
          );
          return MapPage(
            collection: mapCollection,
            initialLocation: _initialLocationZoom?.$1,
            initialZoom: _initialLocationZoom?.$2,
          );
        });
      case ExplorerPage.routeName:
        final path = _initialExplorerPath ?? settings.homeCustomExplorerPath;
        return buildRoute((context) => ExplorerPage(path: path));
      case HomeWidgetSettingsPage.routeName:
        return buildRoute((context) => HomeWidgetSettingsPage(widgetId: _widgetId!));
      case FgwWidgetSettings.routeName:
        return buildRoute((context) => FgwWidgetSettings(widgetId: _widgetId!));
      case ScreenSaverPage.routeName:
        return buildRoute((context) => ScreenSaverPage(source: source));
      case ScreenSaverSettingsPage.routeName:
        return buildRoute((context) => const ScreenSaverSettingsPage());
      case SearchPage.routeName:
        return SearchPageRoute(
          delegate: CollectionSearchDelegate(
            searchFieldLabel: context.l10n.searchCollectionFieldHint,
            searchFieldStyle: Themes.searchFieldStyle(context),
            source: source,
            canPop: false,
            initialQuery: _initialSearchQuery,
          ),
        );
      case CollectionPage.routeName:
      default:
        return buildRoute((context) => CollectionPage(source: source, filters: filters));
    }
  }
}
