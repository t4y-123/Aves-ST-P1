import 'dart:async';

import 'package:aves/model/device.dart';
import 'package:aves/model/fgw/enum/fgw_schedule_item.dart';
import 'package:aves/model/fgw/filters_set.dart';
import 'package:aves/model/fgw/guard_level.dart';
import 'package:aves/model/fgw/wallpaper_schedule.dart';
import 'package:aves/model/filters/filters.dart';
import 'package:aves/model/presentation/base_bridge_row.dart';
import 'package:aves/model/settings/enums/widget_outline.dart';
import 'package:aves/model/settings/enums/widget_shape.dart';
import 'package:aves/model/settings/settings.dart';
import 'package:aves/model/source/collection_source.dart';
import 'package:aves/services/analysis_service.dart';
import 'package:aves/services/fgw_widget_service.dart';
import 'package:aves/theme/durations.dart';
import 'package:aves/theme/icons.dart';
import 'package:aves/view/view.dart';
import 'package:aves/widgets/common/basic/color_indicator.dart';
import 'package:aves/widgets/common/basic/scaffold.dart';
import 'package:aves/widgets/common/extensions/build_context.dart';
import 'package:aves/widgets/common/identity/buttons/outlined_button.dart';
import 'package:aves/widgets/home_widget.dart';
import 'package:aves/widgets/settings/common/collection_tile.dart';
import 'package:aves/widgets/settings/common/tiles.dart';
import 'package:aves/widgets/settings/presentation/foreground_wallpaper/sections/guard_level_section.dart';
import 'package:aves_model/aves_model.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class FgwWidgetSettings extends StatefulWidget {
  static const routeName = '/settings/foreground_wallpaper_widget';

  final int widgetId;
  final bool fromSettingsPage;

  const FgwWidgetSettings({
    super.key,
    required this.widgetId,
    this.fromSettingsPage = false,
  });

  @override
  State<FgwWidgetSettings> createState() => _FgwWidgetSettingsState();
}

class _FgwWidgetSettingsState extends State<FgwWidgetSettings> {
  late WidgetShape _shape;
  late WidgetOutline _outline;
  late WidgetOpenPage _openPage;
  late WidgetDisplayedItem _displayedItem;
  late Set<CollectionFilter> _collectionFilters;
  late Future<void> _initializationFuture;

  Future<Map<Brightness, Map<WidgetOutline, Color?>>> _outlineColorsByBrightness = Future.value({});

  int get widgetId => widget.widgetId;

  static const gradient = HomeWidgetPainter.backgroundGradient;
  static final deselectedGradient = LinearGradient(
    begin: gradient.begin,
    end: gradient.end,
    colors: gradient.colors.map((v) {
      final l = (v.computeLuminance() * 0xFF).toInt();
      return Color.fromARGB(0xFF, l, l, l);
    }).toList(),
    stops: gradient.stops,
    tileMode: gradient.tileMode,
    transform: gradient.transform,
  );

  @override
  void initState() {
    super.initState();
    _shape = settings.getWidgetShape(widgetId);
    _outline = settings.getWidgetOutline(widgetId);
    _openPage = settings.getWidgetOpenPage(widgetId);
    _displayedItem = settings.getWidgetDisplayedItem(widgetId);
    _collectionFilters = settings.getWidgetCollectionFilters(widgetId);
    _initializationFuture = _initializeAsyncDependencies();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateOutlineColors();
    });
  }

  void _updateOutlineColors() {
    _outlineColorsByBrightness = _loadOutlineColors();
    setState(() {});
  }

  Future<Map<Brightness, Map<WidgetOutline, Color?>>> _loadOutlineColors() async {
    final byBrightness = <Brightness, Map<WidgetOutline, Color?>>{};
    await Future.forEach(Brightness.values, (brightness) async {
      final byOutline = <WidgetOutline, Color?>{};
      await Future.forEach(WidgetOutline.values, (outline) async {
        byOutline[outline] = await outline.color(brightness);
      });
      byBrightness[brightness] = byOutline;
    });
    return byBrightness;
  }

  Future<void> _initializeAsyncDependencies() async {
    if (!widget.fromSettingsPage) {
      //unawaited(reportService.setCustomKey('app_mode', 'fgw_widget_setting'));
      // unawaited(GlobalSearch.registerCallback());
      unawaited(AnalysisService.registerCallback());
      final source = context.read<CollectionSource>();
      final readyCompleter = Completer();
      source.stateNotifier.addListener(() {
        if (source.isReady && !readyCompleter.isCompleted) {
          readyCompleter.complete();
        }
      });
      await source.init(canAnalyze: false);
      await readyCompleter.future;
    }
    await fgwGuardLevels.syncRowsToBridge();
    await fgwSchedules.syncRowsToBridge();
    await filtersSets.syncRowsToBridge();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return FutureBuilder<void>(
        future: _initializationFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          return MultiProvider(
            providers: [
              ChangeNotifierProvider<GuardLevel>.value(value: fgwGuardLevels),
              ChangeNotifierProvider<FgwSchedule>.value(value: fgwSchedules),
              ChangeNotifierProvider<FiltersSet>.value(value: filtersSets),
            ],
            child: AvesScaffold(
              appBar: AppBar(
                title: Text(l10n.settingsForegroundWallpaperWidgetPageTitle),
              ),
              body: SafeArea(
                child: FutureBuilder<Map<Brightness, Map<WidgetOutline, Color?>>>(
                  future: _outlineColorsByBrightness,
                  builder: (context, snapshot) {
                    final outlineColorsByBrightness = snapshot.data;
                    if (outlineColorsByBrightness == null) return const SizedBox();

                    final effectiveOutlineColors = outlineColorsByBrightness[Theme.of(context).brightness];
                    if (effectiveOutlineColors == null) return const SizedBox();

                    // Get active levels
                    final activeLevels = fgwGuardLevels.bridgeAll.where((level) => level.isActive);
                    // Create a new widget wallpaper schedule for each active level
                    int orderNumOffset = 1;
                    final newSchedules = activeLevels.map((level) {
                      FgwScheduleRow? todoRow = fgwSchedules.bridgeAll
                          .firstWhereOrNull((e) => e.guardLevelId == level.id && e.widgetId == widgetId);
                      debugPrint('activeLevels =${activeLevels.map((e) => e.toMap())} todoRow ${todoRow?.toMap()}');
                      if (todoRow == null) {
                        final newWidgetFilterSet = filtersSets.newRow(1, type: PresentationRowType.bridgeAll);
                        filtersSets.add({newWidgetFilterSet}, type: PresentationRowType.bridgeAll);
                        todoRow = fgwSchedules.newRow(
                          existMaxOrderNumOffset: orderNumOffset++,
                          guardLevelId: level.id,
                          filtersSetId: newWidgetFilterSet.id,
                          updateType: WallpaperUpdateType.widget,
                          widgetId: widgetId,
                        );
                      }
                      return todoRow;
                    }).toList();

                    // Add new schedules to the existing schedules list
                    fgwSchedules.add(newSchedules.toSet(), type: PresentationRowType.bridgeAll);
                    final newSchedulesIds = newSchedules.map((e) => e.id);
                    return Column(
                      children: [
                        Expanded(
                          child: ListView(
                            children: [
                              _buildShapeSelector(effectiveOutlineColors),
                              ListTile(
                                title: Text(l10n.settingsWidgetShowOutline),
                                trailing: HomeWidgetOutlineSelector(
                                  getter: () => _outline,
                                  setter: (v) => setState(() => _outline = v),
                                  outlineColorsByBrightness: outlineColorsByBrightness,
                                ),
                              ),
                              SettingsSelectionListTile<WidgetOpenPage>(
                                values: WidgetOpenPage.values,
                                getName: (context, v) => v.getName(context),
                                selector: (context, s) => _openPage,
                                onSelection: (v) => setState(() => _openPage = v),
                                tileTitle: l10n.settingsWidgetOpenPage,
                              ),
                              SettingsSelectionListTile<WidgetDisplayedItem>(
                                values: WidgetDisplayedItem.values,
                                getName: (context, v) => v.getName(context),
                                selector: (context, s) => _displayedItem,
                                onSelection: (v) => setState(() => _displayedItem = v),
                                tileTitle: l10n.settingsWidgetDisplayedItem,
                              ),
                              SettingsCollectionTile(
                                filters: _collectionFilters,
                                onSelection: (v) => setState(() => _collectionFilters = v),
                              ),
                              Selector<FgwSchedule, Set<FgwScheduleRow>>(
                                selector: (_, schedules) => schedules.bridgeAll,
                                builder: (_, bridgeAll, __) {
                                  return Column(
                                    children: bridgeAll
                                        .where((e) => newSchedulesIds.contains(e.id))
                                        .toList()
                                        .sorted()
                                        .map((e) => ScheduleItemPageTile(item: e).build(context))
                                        .toList(),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                        const Divider(height: 0),
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: AvesOutlinedButton(
                            label: l10n.saveTooltip,
                            onPressed: () async {
                              await _saveSettings();
                              await ForegroundWallpaperWidgetService.configure();
                            },
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          );
        });
  }

  Widget _buildShapeSelector(Map<WidgetOutline, Color?> outlineColors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      child: Wrap(
        spacing: 16,
        runSpacing: 16,
        children: WidgetShape.values.map((shape) {
          final selected = shape == _shape;
          final duration = context.read<DurationsData>().formTransition;
          return GestureDetector(
            onTap: () => setState(() => _shape = shape),
            child: AnimatedOpacity(
              duration: duration,
              // as of Flutter beta v3.3.0-0.0.pre, decoration rendering is at the wrong position if opacity is > .998
              opacity: selected ? .998 : .4,
              child: AnimatedContainer(
                duration: duration,
                width: 96,
                height: 124,
                decoration: ShapeDecoration(
                  gradient: selected ? gradient : deselectedGradient,
                  shape: _WidgetShapeBorder(_outline, shape, outlineColors),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Future<void> _saveSettings() async {
    final invalidateUri = _displayedItem != settings.getWidgetDisplayedItem(widgetId) ||
        !const SetEquality().equals(_collectionFilters, settings.getWidgetCollectionFilters(widgetId));

    settings.setWidgetShape(widgetId, _shape);
    settings.setWidgetOutline(widgetId, _outline);
    settings.setWidgetOpenPage(widgetId, _openPage);
    settings.setWidgetDisplayedItem(widgetId, _displayedItem);
    settings.setWidgetCollectionFilters(widgetId, _collectionFilters);

    // t4y: sync bridge to all to save settings.
    await filtersSets.syncBridgeToRows(notify: false);
    await fgwSchedules.syncBridgeToRows(notify: false);

    if (invalidateUri) {
      settings.setWidgetUri(widgetId, null);
    }
    debugPrint('$runtimeType _saveSettings syncBridgeToRows finish');
    //await ForegroundWallpaperService.syncFgwScheduleChanges();
    // Conditionally pop the page based on the source
    if (widget.fromSettingsPage) {
      Navigator.of(context).pop();
    }
  }
}

class _WidgetShapeBorder extends ShapeBorder {
  final WidgetOutline outline;
  final WidgetShape shape;
  final Map<WidgetOutline, Color?> outlineColors;

  static const _devicePixelRatio = 1.0;

  const _WidgetShapeBorder(this.outline, this.shape, this.outlineColors);

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.zero;

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) {
    return getOuterPath(rect, textDirection: textDirection);
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    return shape.path(rect.size, _devicePixelRatio);
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    final outlineColor = outlineColors[outline];
    if (outlineColor != null) {
      final path = shape.path(rect.size, _devicePixelRatio);
      canvas.clipPath(path);
      HomeWidgetPainter.drawOutline(canvas, path, _devicePixelRatio, outlineColor);
    }
  }

  @override
  ShapeBorder scale(double t) => this;
}

class HomeWidgetOutlineSelector extends StatefulWidget {
  final ValueGetter<WidgetOutline> getter;
  final ValueSetter<WidgetOutline> setter;
  final Map<Brightness, Map<WidgetOutline, Color?>> outlineColorsByBrightness;

  const HomeWidgetOutlineSelector({
    super.key,
    required this.getter,
    required this.setter,
    required this.outlineColorsByBrightness,
  });

  @override
  State<HomeWidgetOutlineSelector> createState() => _HomeWidgetOutlineSelectorState();
}

class _HomeWidgetOutlineSelectorState extends State<HomeWidgetOutlineSelector> {
  @override
  Widget build(BuildContext context) {
    return DropdownButtonHideUnderline(
      child: DropdownButton<WidgetOutline>(
        items: _buildItems(context),
        value: widget.getter(),
        onChanged: (selected) {
          widget.setter(selected ?? WidgetOutline.none);
          setState(() {});
        },
      ),
    );
  }

  List<DropdownMenuItem<WidgetOutline>> _buildItems(BuildContext context) {
    return supportedWidgetOutlines.map((selected) {
      final lightColors = widget.outlineColorsByBrightness[Brightness.light];
      final darkColors = widget.outlineColorsByBrightness[Brightness.dark];
      return DropdownMenuItem<WidgetOutline>(
        value: selected,
        child: ColorIndicator(
          value: lightColors?[selected],
          alternate: darkColors?[selected],
          child: lightColors?[selected] == null ? const Icon(AIcons.clear) : null,
        ),
      );
    }).toList();
  }

  List<WidgetOutline> get supportedWidgetOutlines => [
        WidgetOutline.none,
        WidgetOutline.black,
        WidgetOutline.white,
        WidgetOutline.systemBlackAndWhite,
        if (device.isDynamicColorAvailable) WidgetOutline.systemDynamic,
      ];
}
