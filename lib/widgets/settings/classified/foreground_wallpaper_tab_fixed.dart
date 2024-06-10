import 'package:aves/model/settings/settings.dart';
import 'package:aves/theme/icons.dart';
import 'package:aves/widgets/common/extensions/build_context.dart';
import 'package:flutter/material.dart';

import '../../common/identity/buttons/outlined_button.dart';
import 'foreground_wallpaper_config_banner.dart';

typedef ItemWidgetBuilder<T> = Widget Function(T item);

typedef ItemActionWidgetBuilder<T> = void Function(
    BuildContext context, T item, List<T> items, Set<T> activeItems);
typedef ItemsActionWidgetBuilder<T> = void Function(
    BuildContext context, List<T> items, Set<T> activeItems);
typedef ItemsColorWidgetBuilder<T> = Color Function(T item);

class ForegroundWallpaperFixedListTab<T> extends StatefulWidget {
  final List<T> items;
  final Set<T> activeItems;
  final ItemWidgetBuilder<T> title;
  final ItemsColorWidgetBuilder<T>? avatarColor;
  final ItemActionWidgetBuilder<T>? editAction;
  final ItemsActionWidgetBuilder<T>? applyChangesAction;
  final ItemsActionWidgetBuilder<T>? addItemAction;


  const ForegroundWallpaperFixedListTab({
    super.key,
    required this.items,
    required this.activeItems,
    required this.title,
    this.avatarColor,
    this.editAction,
    this.applyChangesAction,
    this.addItemAction,
  });

  @override
  State<ForegroundWallpaperFixedListTab<T>> createState() =>
      _ForegroundWallpaperFixedListTabState<T>();
}

class _ForegroundWallpaperFixedListTabState<T>
    extends State<ForegroundWallpaperFixedListTab<T>> {
  late List<T> _items;

  @override
  void initState() {
    super.initState();
    _items = List.from(widget.items);
  }

  Set<T> get activeItems => widget.activeItems;

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
              final item = _items[index];
              final isActive = activeItems.contains(item);

              void onToggleVisibility() {
                setState(() {
                  if (isActive) {
                    activeItems.remove(item);
                  } else {
                    activeItems.add(item);
                  }
                });
              }

              // t4y: order with the active status: Always make active items before the inactive items.
              final activeItemsList = _items.where(activeItems.contains).toList();
              final avatarNumber = isActive
                  ? activeItemsList.indexOf(item) + 1
                  : activeItemsList.length +
                      _items.where((i) => !activeItems.contains(i))
                          .toList()
                          .indexOf(item) +
                      1;

              final avatarColor = widget.avatarColor?.call(item);
              return Opacity(
                key: ValueKey(item),
                opacity: isActive ? 1 : .4,
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: avatarColor ?? Theme.of(context).primaryColor,
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
                            widget.editAction!(context, item,_items,activeItems);
                          } else {
                            _showDefaultAlert('Edit');
                          }
                        },
                        tooltip: 'Edit',
                      ),
                      IconButton(
                        icon: Icon(isActive ? AIcons.hide : AIcons.show),
                        onPressed: onToggleVisibility,
                        tooltip: isActive ? 'Hide' : 'Show',
                      ),
                      IconButton(
                        icon: const Icon(AIcons.clear),
                        onPressed: () async {
                          setState(() {
                            _items.remove(item);
                            activeItems.remove(item);
                          }
                          );
                        },
                        tooltip: 'Delete',
                      ),
                    ],
                  ),
                  onTap: settings.useTvLayout ? onToggleVisibility : null,
                ),
              );
            },
            itemCount: _items.length,
            onReorder: (oldIndex, newIndex) {
              setState(() {
                if (oldIndex < newIndex) newIndex -= 1;
                final item = _items.removeAt(oldIndex);
                _items.insert(newIndex, item);
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
            AvesOutlinedButton(
              icon: const Icon(AIcons.apply),
              label: context.l10n.settingsForegroundWallpaperConfigApplyChanges,
              onPressed: () async {
                if (widget.applyChangesAction != null) {
                  widget.applyChangesAction!(context, _items, activeItems);
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
                  widget.addItemAction!(context, _items, activeItems);
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
