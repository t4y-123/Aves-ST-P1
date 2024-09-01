import 'package:aves/model/fgw/filters_set.dart';
import 'package:aves/model/fgw/guard_level.dart';
import 'package:aves/model/fgw/wallpaper_schedule.dart';
import 'package:aves/services/fgw_service_handler.dart';
import 'package:aves/widgets/common/action_mixins/feedback.dart';
import 'package:aves/widgets/common/extensions/build_context.dart';
import 'package:aves/widgets/settings/fgw_widget_settings_page.dart';
import 'package:aves/widgets/settings/home_widget_settings_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class WidgetEditSettingPage extends StatefulWidget {
  static const routeName = '/settings/presentation/widget_edit_setting';

  const WidgetEditSettingPage({super.key});

  @override
  State<WidgetEditSettingPage> createState() => _WidgetEditSettingPageState();
}

class _WidgetEditSettingPageState extends State<WidgetEditSettingPage> with FeedbackMixin {
  Map<String, List<int>> _widgetIds = {};

  @override
  void initState() {
    super.initState();
    // first sync the rows data to the bridge data.
    // then all data shall modify in the bridgeAll data.
    fgwGuardLevels.syncRowsToBridge();
    fgwSchedules.syncRowsToBridge();
    filtersSets.syncRowsToBridge();
    // Add listeners to track modifications
    _loadWidgetIds();
  }

  Future<void> _loadWidgetIds() async {
    // Assuming WidgetIdManager is already set up to get both widget types' IDs
    Map<String, List<int>> widgetIds = await ForegroundWallpaperService.getAllWidgetIds();
    setState(() {
      _widgetIds = widgetIds;
    });
  }

  @override
  Widget build(BuildContext context) {
    final foregroundWallpaperWidgets = _widgetIds['foregroundWallpaperWidgets'];
    final homeWidgets = _widgetIds['homeWidgets'];

    bool isEmpty = (foregroundWallpaperWidgets == null || foregroundWallpaperWidgets.isEmpty) &&
        (homeWidgets == null || homeWidgets.isEmpty);

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<GuardLevel>.value(value: fgwGuardLevels),
        ChangeNotifierProvider<FgwSchedule>.value(value: fgwSchedules),
        ChangeNotifierProvider<FiltersSet>.value(value: filtersSets),
      ],
      child: Scaffold(
        appBar: AppBar(
          title: Text(context.l10n.widgetSettingPageTitle),
        ),
        body: isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.info_outline, size: 100, color: Colors.grey),
                    const SizedBox(height: 20),
                    Text(
                      context.l10n.widgetEmpty,
                      style: const TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                  ],
                ),
              )
            : ListView(
                children: [
                  if (foregroundWallpaperWidgets != null)
                    ...foregroundWallpaperWidgets.map(_buildFgwWidgetSettingsTile),
                  if (homeWidgets != null) ...homeWidgets.map(_buildHomeWidgetSettingsTile),
                ],
              ),
      ),
    );
  }

  Widget _buildFgwWidgetSettingsTile(int widgetId) {
    return ListTile(
      title: Text('Foreground Wallpaper Widget ID: $widgetId'),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => FgwWidgetSettings(widgetId: widgetId),
          ),
        );
      },
    );
  }

  Widget _buildHomeWidgetSettingsTile(int widgetId) {
    return ListTile(
      title: Text('Home Widget ID: $widgetId'),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => HomeWidgetSettingsPage(widgetId: widgetId),
          ),
        );
      },
    );
  }
}
