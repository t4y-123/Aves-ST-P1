import 'package:aves/model/privacyGuardLevel.dart';
import 'package:aves/model/settings/settings.dart';
import 'package:aves/widgets/common/basic/scaffold.dart';
import 'package:aves/widgets/common/extensions/build_context.dart';
import 'package:aves/widgets/settings/classified/privacy_guard_level_config.dart';

import 'package:flutter/material.dart';
import '../../common/action_mixins/feedback.dart';
import 'foreground_wallpaper_tab_fixed.dart';

class ForegroundWallpaperConfigPage extends StatefulWidget  {
  static const routeName = '/settings/classified_foreground_wallpaper_config';

  const ForegroundWallpaperConfigPage({super.key});

  @override
  State<ForegroundWallpaperConfigPage> createState() => _ForegroundWallpaperConfigPageState();
}

class _ForegroundWallpaperConfigPageState extends State<ForegroundWallpaperConfigPage> with FeedbackMixin{
  final List<PrivacyGuardLevelRow?> _privacyGuardLevels = [];
  final Set<PrivacyGuardLevelRow?> _activePrivacyGuardLevelsTypes = {};

  @override
  void initState() {
    super.initState();
    _privacyGuardLevels.addAll(privacyGuardLevels.all);
    _privacyGuardLevels.sort();// to sort make it show active item first.
    _activePrivacyGuardLevelsTypes.addAll(_privacyGuardLevels.where((v) => v?.isActive ?? false));
  }


  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final tabs = <(Tab, Widget)>[
      (
      Tab(text: l10n.settingsPrivacyGuardLevelTabTypes),
      ForegroundWallpaperFixedListTab<PrivacyGuardLevelRow?>(
        items: _privacyGuardLevels,
        activeItems: _activePrivacyGuardLevelsTypes,
        title: (item) => Text(item?.aliasName ?? 'Empty'),
        editAction:_editPrivacyGuardLevel,
        applyChangesAction: _applyPrivacyGuardLevelReorder,
        addItemAction: _addPrivacyGuardLevel,
        avatarColor: _privacyItemColor,
      ),
      ),
    ];

    return DefaultTabController(
      length: tabs.length,
      child: AvesScaffold(
        appBar: AppBar(
          automaticallyImplyLeading: !settings.useTvLayout,
          title: Text(l10n.settingsClassifiedForegroundWallpaperConfigTile),
          bottom: TabBar(
            tabs: tabs.map((t) => t.$1).toList(),
          ),
        ),
        body: PopScope(
          canPop: true,
          onPopInvoked: (didPop) {},
          child: SafeArea(
            child: TabBarView(
              children: tabs.map((t) => t.$2).toList(),
            ),
          ),
        ),
      ),
    );
  }

  Color _privacyItemColor(PrivacyGuardLevelRow? item){
    return item?.color ?? Theme.of(context).primaryColor;
  }
  // PrivacyGuardLevelConfig
  void _applyPrivacyGuardLevelReorder(BuildContext context, List<PrivacyGuardLevelRow?> allItems, Set<PrivacyGuardLevelRow?> activeItems) {
    setState(() {
      // First, remove items not exist.
      final currentItems = privacyGuardLevels.all;
      final itemsToRemove = currentItems.where((item) => !allItems.contains(item)).toSet();
      privacyGuardLevels.removeEntries(itemsToRemove);

      // Second, should use allItems to keep the reorder level.
      int guardLevelIndex = 1;
      allItems.where((item) => activeItems.contains(item)).forEach((item) {
          privacyGuardLevels.set(
            privacyGuardLevelID: item!.privacyGuardLevelID,
            guardLevel: guardLevelIndex++,
            aliasName: item.aliasName,
            color: item.color!,
            isActive: true,
          );
      });

      // Process reordered items that are not in active items
      allItems.where((item) => !activeItems.contains(item)).forEach((item) {
        privacyGuardLevels.set(
          privacyGuardLevelID: item!.privacyGuardLevelID,
          guardLevel: ++guardLevelIndex,
          aliasName: item.aliasName,
          color: item.color!,
          isActive: false,
        );
      });
      //
      showFeedback(context, FeedbackType.info, 'Apply Change completely');
    });
  }


  void _addPrivacyGuardLevel(BuildContext context, List<PrivacyGuardLevelRow?> allItems, Set<PrivacyGuardLevelRow?> activeItems) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PrivacyGuardLevelConfigPage(
          item: null, // Pass null to create a new item
          allItems: allItems,
          activeItems: activeItems,
        ),
      ),
    ).then((newItem) {
      if (newItem != null) {
        //final newRow = newItem as PrivacyGuardLevelRow;
        setState(() {
          privacyGuardLevels.add({newItem});
          allItems.add(newItem);
          if (newItem.isActive) {
            activeItems.add(newItem);
          }
          allItems.sort();
        });
      }
    });
  }

  void _editPrivacyGuardLevel(
      BuildContext context,
      PrivacyGuardLevelRow? item,
      List<PrivacyGuardLevelRow?> allItems,
      Set<PrivacyGuardLevelRow?> activeItems) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PrivacyGuardLevelConfigPage(
          item: item,
          allItems: allItems,
          activeItems: activeItems,
        ),
      ),
    ).then((updatedItem) {
      if (updatedItem != null) {
        setState(() {
          final index = allItems.indexWhere(
              (i) => i?.privacyGuardLevelID == updatedItem.privacyGuardLevelID);
          if (index != -1) {
            allItems[index] = updatedItem;
          } else {
            allItems.add(updatedItem);
          }
          if (updatedItem.isActive) {
            activeItems.add(updatedItem);
          }else{
            activeItems.remove(updatedItem);
          }
          privacyGuardLevels.setRows({updatedItem});
        });
      }
    });
  }
}
