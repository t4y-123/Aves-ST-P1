import 'package:aves/model/settings/settings.dart';
import 'package:aves/theme/icons.dart';
import 'package:aves/widgets/common/extensions/build_context.dart';
import 'package:flutter/material.dart';

import '../../../common/action_mixins/feedback.dart';
import '../../../common/identity/buttons/outlined_button.dart';
import 'foreground_wallpaper_config_banner.dart';

typedef ItemWidgetBuilder<T> = Widget Function(T item);

typedef ItemActionWidgetBuilder<T> = void Function(
    BuildContext context, T item, List<T> items, Set<T> activeItems);
typedef ItemsActionWidgetBuilder<T> = void Function(
    BuildContext context, List<T> items, Set<T> activeItems);
typedef ItemsColorWidgetBuilder<T> = Color Function(T item);

class ForegroundWallpaperFixedListTab<T> extends StatefulWidget  {
  final List<T> items;
  final Set<T> activeItems;
  final ItemWidgetBuilder<T> title;
  final ItemsColorWidgetBuilder<T>? avatarColor;
  final ItemActionWidgetBuilder<T>? editAction;
  final ItemsActionWidgetBuilder<T>? applyChangesAction;
  final ItemsActionWidgetBuilder<T>? addItemAction;
  final bool useActiveButton;

  const ForegroundWallpaperFixedListTab({
    super.key,
    required this.items,
    required this.activeItems,
    required this.title,
    this.avatarColor,
    this.editAction,
    this.applyChangesAction,
    this.addItemAction,
    this.useActiveButton = true,
  });

  @override
  State<ForegroundWallpaperFixedListTab<T>> createState() =>
      _ForegroundWallpaperFixedListTabState<T>();
}

class _ForegroundWallpaperFixedListTabState<T>
    extends State<ForegroundWallpaperFixedListTab<T>>  with FeedbackMixin {
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
          const ForegroundWallpaperConfigBanner(),
          const Divider(height: 0),
        ],
        Flexible(
          child: ReorderableListView.builder(
            itemBuilder: (context, index) {
              final item = widget.items[index];
              final isActive = _activeItems.contains(item);
              debugPrint('$runtimeType ReorderableListView.builder localItems ${widget.items} load');
              void onToggleVisibility() {
                if (isActive && _activeItems.length <= 1) {
                  // Show a message that at least one item must remain active
                  showFeedback(context, FeedbackType.info, 'At least one item must remain or active.');
                  return;
                }
                setState(() {
                  if (isActive) {
                    _activeItems.remove(item);
                  } else {
                    _activeItems.add(item);
                  }
                  _isModified = true;
                });
              }

              void onRemoveItem() {
                if (_activeItems.length <= 1 || widget.items.length <= 1) {
                  // Show a message that at least one item must remain
                  showFeedback(context, FeedbackType.info, 'At least one item must remain or active.');
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
                      widget.items.where((i) => !_activeItems.contains(i))
                          .toList()
                          .indexOf(item) +
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
                      IconButton(
                        icon: const Icon(AIcons.edit),
                        onPressed: () {
                          if (widget.editAction != null) {
                            widget.editAction!(context, item,widget.items,_activeItems);
                          } else {
                            _showDefaultAlert('Edit');
                          }
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
                _isModified = true; // Reset after applying changes
              });
            },
            shrinkWrap: true,
          ),
        ),
        const Divider(height: 0),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if(_isModified) AvesOutlinedButton(
              icon: const Icon(AIcons.apply),
              label: context.l10n.settingsForegroundWallpaperConfigApplyChanges,
              onPressed: () async {
                if (widget.applyChangesAction != null) {
                  setState(() {
                    List<T> tmpItems = [];
                    tmpItems.addAll(widget.items);
                    final Set<T> tmpActiveItems = {} ;
                    tmpActiveItems.addAll(_activeItems );
                    widget.applyChangesAction!(context, tmpItems, tmpActiveItems);
                    _isModified = false;
                  });
                } else {
                  _showDefaultAlert('applyReorderAction');
                }
              },
            ),
            const SizedBox(width: 8),
            AvesOutlinedButton(
              icon: const Icon(AIcons.add),
              label: context.l10n.settingsForegroundWallpaperConfigAddItem,
              onPressed: () async {
                if (widget.addItemAction != null) {
                  widget.addItemAction!(context, widget.items, _activeItems);
                  setState(() {
                    _isModified = true; // Mark as modified
                  });
                } else {
                  _showDefaultAlert('addItemAction');
                }
              },
            )
          ],
        ),
      ],
    );
  }
}
