
import 'package:aves/widgets/common/action_mixins/feedback.dart';
import 'package:aves/widgets/common/app_bar/app_bar_title.dart';
import 'package:aves/widgets/common/basic/insets.dart';
import 'package:aves/widgets/common/basic/scaffold.dart';
import 'package:aves/widgets/common/extensions/build_context.dart';
import 'package:aves/widgets/settings/settings_definition.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

import '../common/item_settings_definition.dart';
import 'guard_level_setting_page.dart';


class ExpandableSettingsPage extends StatefulWidget {
   // SettingsMobilePage({super.key});

  final List<ItemSettingsSection> pageSections;
  final List<Widget> preWidgets;
  final List<Widget> postWidgets;
  final List<SettingsTile> preTiles;

   const ExpandableSettingsPage({
     super.key,
     this.pageSections =const [],
     this.preWidgets = const [],
     this.postWidgets = const [],
     this.preTiles = const [],
   });

  @override
  State<ExpandableSettingsPage> createState() => _ExpandableSettingsMobilePageState();
}

class _ExpandableSettingsMobilePageState extends State<ExpandableSettingsPage> with FeedbackMixin {
  final ValueNotifier<String?> _expandedNotifier = ValueNotifier(null);

  @override
  void dispose() {
    _expandedNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AvesScaffold(
      appBar: AppBar(
        title: InteractiveAppBarTitle(
          child: Text(context.l10n.settingsPageTitle),
        ),
        // //t4y: todo: achieve the search function if have time in future, or never.
      ),
      body: GestureAreaProtectorStack(
        child: SafeArea(
          bottom: false,
          child: AnimationLimiter(
            child: FgwSettingsListView(
              // children: SettingsPage.sections.map((v) => v.build(context, _expandedNotifier)).toList(),
              children:[
                ...widget.preTiles.map((v) => v.build(context)),
                ...widget.preWidgets,
                ...widget.pageSections.map((v) => v.build(context, _expandedNotifier)),
                ...widget.postWidgets,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
