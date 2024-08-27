import 'package:aves/model/foreground_wallpaper/filtersSet.dart';
import 'package:aves/model/foreground_wallpaper/wallpaper_schedule.dart';
import 'package:aves/model/scenario/enum/scenario_item.dart';
import 'package:aves/model/scenario/scenario.dart';
import 'package:aves/model/settings/settings.dart';
import 'package:aves/theme/icons.dart';
import 'package:aves/widgets/common/extensions/build_context.dart';
import 'package:flutter/material.dart';

import '../../../../model/foreground_wallpaper/enum/fgw_schedule_item.dart';
import '../../../../services/fgw_service_handler.dart';
import '../../../common/action_mixins/feedback.dart';
import '../../../common/identity/buttons/outlined_button.dart';
import 'foreground_wallpaper_config_banner.dart';

typedef ItemWidgetBuilder<T> = Widget Function(T item);

typedef ItemActionWidgetBuilder<T> = void Function(BuildContext context, T item, List<T> items, Set<T> activeItems);
typedef ItemsActionWidgetBuilder<T> = void Function(BuildContext context, List<T> items, Set<T> activeItems);
typedef ItemsColorWidgetBuilder<T> = Color Function(T item);

class MultiOpFixedListTab<T> extends StatefulWidget {
  final List<T> items;
  final Set<T> activeItems;
  final ItemWidgetBuilder<T> title;
  final ItemsColorWidgetBuilder<T>? avatarColor;
  final ItemActionWidgetBuilder<T>? editAction;
  final ItemsActionWidgetBuilder<T>? applyChangesAction;
  final ItemsActionWidgetBuilder<T>? addItemAction;
  final bool useActiveButton;
  final bool canRemove;
  final bool useSyncScheduleButton;
  final bool canBeEmpty, canBeActiveEmpty;
  final bannerString;

  const MultiOpFixedListTab({
    super.key,
    required this.items,
    required this.activeItems,
    required this.title,
    required this.bannerString,
    this.avatarColor,
    this.editAction,
    this.applyChangesAction,
    this.addItemAction,
    this.useActiveButton = true,
    this.canRemove = true,
    this.useSyncScheduleButton = true,
    this.canBeEmpty = false,
    this.canBeActiveEmpty = false,
  });

  @override
  State<MultiOpFixedListTab<T>> createState() => _MultiOpFixedListTabState<T>();
}

class _MultiOpFixedListTabState<T> extends State<MultiOpFixedListTab<T>> with FeedbackMixin {
  Set<T> get _activeItems => widget.useActiveButton ? widget.activeItems : Set.from(widget.items);
  bool _isModified = false;

  @override
  void initState() {
    super.initState();
  }

  void _showDefaultAlert(String action) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('$action Action'),
          content: Text('Widget not defined for $action action'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (!settings.useTvLayout) ...[
          ForegroundWallpaperConfigBanner(bannerString: widget.bannerString),
          const Divider(height: 0),
        ],
        Flexible(
          child: ReorderableListView.builder(
            itemBuilder: (context, index) {
              final item = widget.items[index];
              bool _canRemove = widget.canRemove;
              // only none schedules used filtersSet can be remove.
              if (item is FiltersSetRow) {
                _canRemove = !wallpaperSchedules.bridgeAll.any((e) => e.filtersSetId == item.id) &&
                    !wallpaperSchedules.all.any((e) => e.filtersSetId == item.id);
              }

              final isActive = _activeItems.contains(item);
              debugPrint('$runtimeType ReorderableListView.builder localItems ${widget.items} load');
              void onToggleVisibility() {
                if (isActive && _activeItems.length <= 1 && !widget.canBeActiveEmpty) {
                  // Show a message that at least one item must remain active
                  showFeedback(context, FeedbackType.info, context.l10n.settingsFgwFixedTabAtLeastOneItemLeaveBeActive);
                  return;
                }
                if (item is ScenarioRow) {
                  if (widget.items
                          .where((e) => e is ScenarioRow && e.loadType == ScenarioLoadType.excludeUnique && e.isActive)
                          .toSet()
                          .length <=
                      1) {
                    showFeedback(
                        context, FeedbackType.info, context.l10n.settingsScenarioAtLeastOneExcludeItemLeaveWhenRemove);
                    return;
                  }
                }
                setState(() {
                  if (isActive) {
                    _activeItems.remove(item);
                  } else {
                    if (item is WallpaperScheduleRow) {
                      // Handle WallpaperScheduleRow specific logic
                      final row = item as WallpaperScheduleRow;
                      if (row.updateType == WallpaperUpdateType.home || row.updateType == WallpaperUpdateType.lock) {
                        // Remove items with the same privacyGuardLevelId
                        _activeItems.removeWhere((element) =>
                            element is WallpaperScheduleRow &&
                            element.privacyGuardLevelId == row.privacyGuardLevelId &&
                            (element.updateType == WallpaperUpdateType.both));
                      } else if (row.updateType == WallpaperUpdateType.both) {
                        // Remove items with the same privacyGuardLevelId and updateType is home or lock
                        _activeItems.removeWhere((element) =>
                            element is WallpaperScheduleRow &&
                            element.privacyGuardLevelId == row.privacyGuardLevelId &&
                            (element.updateType == WallpaperUpdateType.home ||
                                element.updateType == WallpaperUpdateType.lock));
                      }
                    }
                    _activeItems.add(item);
                  }
                  _isModified = true;
                });
              }

              void onRemoveItem() {
                if (item is ScenarioRow) {
                  if (widget.items
                          .where((e) => e is ScenarioRow && e.loadType == ScenarioLoadType.excludeUnique)
                          .toSet()
                          .length <=
                      1) {
                    showFeedback(
                        context, FeedbackType.info, context.l10n.settingsScenarioAtLeastOneExcludeItemLeaveWhenRemove);
                    return;
                  }
                }
                if ((!widget.canBeActiveEmpty && _activeItems.length <= 1) ||
                    (!widget.canBeEmpty && widget.items.length <= 1)) {
                  // Show a message that at least one item must remain
                  showFeedback(
                      context, FeedbackType.info, context.l10n.settingsFgwFixedTabAtLeastOneItemLeaveWhenRemove);
                  return;
                }
                setState(() {
                  widget.items.remove(item);
                  _activeItems.remove(item);
                  _isModified = true;
                });
              }

              // t4y: order with the active status: Always make active items before the inactive items.
              final activeItemsList = widget.items.where(_activeItems.contains).toList();
              final avatarNumber = isActive
                  ? activeItemsList.indexOf(item) + 1
                  : activeItemsList.length +
                      widget.items.where((i) => !_activeItems.contains(i)).toList().indexOf(item) +
                      1;

              final avatarColor = widget.avatarColor?.call(item);
              return Opacity(
                key: ValueKey(item),
                opacity: isActive ? 1 : .4,
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: avatarColor ?? Theme.of(context).colorScheme.primary,
                    child: Text(avatarNumber.toString()),
                  ),
                  title: widget.title(item),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.editAction != null)
                        IconButton(
                          icon: const Icon(AIcons.edit),
                          onPressed: () {
                            widget.editAction!(context, item, widget.items, _activeItems);
                            _isModified = true;
                          },
                          tooltip: 'Edit',
                        ),
                      if (widget.useActiveButton) ...[
                        IconButton(
                          icon: Icon(isActive ? AIcons.active : AIcons.inactive),
                          onPressed: onToggleVisibility,
                          tooltip: isActive ? 'Hide' : 'Show',
                        ),
                      ],
                      if (_canRemove)
                        IconButton(
                          icon: const Icon(AIcons.clear),
                          onPressed: onRemoveItem,
                          tooltip: 'Remove',
                        ),
                    ],
                  ),
                  onTap: settings.useTvLayout ? onToggleVisibility : null,
                ),
              );
            },
            itemCount: widget.items.length,
            onReorder: (oldIndex, newIndex) {
              setState(() {
                if (oldIndex < newIndex) newIndex -= 1;
                final item = widget.items.removeAt(oldIndex);
                widget.items.insert(newIndex, item);
                _isModified = true;
              });
            },
            shrinkWrap: true,
          ),
        ),
        if (widget.useSyncScheduleButton) const Divider(height: 8),
        if (widget.useSyncScheduleButton)
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              const SizedBox(width: 8),
              AvesOutlinedButton(
                icon: const Icon(AIcons.refresh),
                label: context.l10n.settingsFgwScheduleSyncButtonText,
                onPressed: () async {
                  await ForegroundWallpaperService.syncFgwScheduleChanges();
                  await showDialog(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        title: Text(context.l10n.settingsFgwScheduleSyncButtonText),
                        content: Text(context.l10n.settingsFgwScheduleSyncButtonAlert),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: Text(context.l10n.applyTooltip),
                          ),
                        ],
                      );
                    },
                  );
                },
              )
            ],
          ),
        const Divider(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            if (_isModified)
              AvesOutlinedButton(
                icon: const Icon(AIcons.apply),
                label: context.l10n.settingsForegroundWallpaperConfigApplyChanges,
                onPressed: () async {
                  if (widget.applyChangesAction != null) {
                    setState(() {
                      List<T> tmpItems = [];
                      tmpItems.addAll(widget.items);
                      final Set<T> tmpActiveItems = {};
                      tmpActiveItems.addAll(_activeItems);
                      widget.applyChangesAction!(context, tmpItems, tmpActiveItems);
                      _isModified = false;
                    });
                  } else {
                    _showDefaultAlert('applyReorderAction');
                  }
                },
              ),
            const SizedBox(width: 8),
            if (widget.addItemAction != null)
              AvesOutlinedButton(
                icon: const Icon(AIcons.add),
                label: context.l10n.settingsForegroundWallpaperConfigAddItem,
                onPressed: () async {
                  widget.addItemAction!(context, widget.items, _activeItems);
                  setState(() {
                    _isModified = true; // Mark as modified
                  });
                },
              ),
          ],
        ),
        const Divider(height: 8),
      ],
    );
  }
}
