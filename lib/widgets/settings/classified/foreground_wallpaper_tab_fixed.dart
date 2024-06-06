import 'package:aves/model/settings/settings.dart';
import 'package:aves/theme/icons.dart';
import 'package:aves/widgets/common/extensions/build_context.dart';
import 'package:aves/widgets/settings/navigation/drawer_editor_banner.dart';
import 'package:flutter/material.dart';

import '../../common/identity/buttons/outlined_button.dart';

typedef ItemWidgetBuilder<T> = Widget Function(T item);

typedef ItemActionWidgetBuilder<T> = Widget Function(BuildContext context, T item);

class ForegroundWallpaperFixedListTab<T> extends StatefulWidget {
  final List<T> items;
  final Set<T> visibleItems;
  final ItemWidgetBuilder<T> title;
  final ItemActionWidgetBuilder<T>? editAction;
  final ItemActionWidgetBuilder<T>? deleteAction;

  const ForegroundWallpaperFixedListTab({
    super.key,
    required this.items,
    required this.visibleItems,
    required this.title,
    this.editAction,
    this.deleteAction,
  });

  @override
  State<ForegroundWallpaperFixedListTab<T>> createState() => _ForegroundWallpaperFixedListTabState<T>();
}

class _ForegroundWallpaperFixedListTabState<T> extends State<ForegroundWallpaperFixedListTab<T>> {
  Set<T> get visibleItems => widget.visibleItems;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (!settings.useTvLayout) ...[
          const DrawerEditorBanner(),
          const Divider(height: 0),
        ],
        Flexible(
          child: ReorderableListView.builder(
            itemBuilder: (context, index) {
              final filter = widget.items[index];
              final visible = visibleItems.contains(filter);
              void onToggleVisibility() {
                setState(() {
                  if (visible) {
                    visibleItems.remove(filter);
                  } else {
                    visibleItems.add(filter);
                  }
                });
              }

              void showDefaultAlert(String action) {
                showDialog(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      title: Text('$action Action'),
                      content: Text('Widget not defined for $action action'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: Text('OK'),
                        ),
                      ],
                    );
                  },
                );
              }

              return Opacity(
                key: ValueKey(filter),
                opacity: visible ? 1 : .4,
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text((index + 1).toString()),
                  ),
                  title: widget.title(filter),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(AIcons.edit),
                        onPressed: () {
                          if (widget.editAction != null) {
                            widget.editAction!(context, filter);
                          } else {
                            showDefaultAlert('Edit');
                          }
                        },
                        tooltip: 'Edit',
                      ),
                      IconButton(
                        icon: const Icon(AIcons.clear),
                        onPressed: () async {
                          if (widget.deleteAction != null) {
                            widget.deleteAction!(context, filter);
                          } else {
                            showDefaultAlert('Delete');
                          }
                        },
                        tooltip: 'Delete',
                      ),
                      IconButton(
                        icon: Icon(visible ? AIcons.hide : AIcons.show),
                        onPressed: onToggleVisibility,
                        tooltip: visible ? 'Hide' : 'Show',
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
                widget.items.insert(newIndex, widget.items.removeAt(oldIndex));
              });
            },
          ),
        ),
        const Divider(height: 0),
        const SizedBox(height: 8),
        AvesOutlinedButton(
          icon: const Icon(AIcons.add),
          label: context.l10n.settingsNavigationDrawerAddAlbum,
          onPressed: () async {
            // TODO:
          },
        ),
      ],
    );
  }
}