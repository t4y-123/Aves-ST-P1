import 'package:aves/model/fgw/enum/fgw_schedule_item.dart';
import 'package:aves/model/fgw/filters_set.dart';
import 'package:aves/model/fgw/wallpaper_schedule.dart';
import 'package:aves/model/settings/settings.dart';
import 'package:aves/services/fgw_service_handler.dart';
import 'package:aves/theme/icons.dart';
import 'package:aves/widgets/common/action_mixins/feedback.dart';
import 'package:aves/widgets/common/extensions/build_context.dart';
import 'package:aves/widgets/common/identity/buttons/outlined_button.dart';
import 'package:aves/widgets/settings/presentation/common/multi_tab_edit_page_banner.dart';
import 'package:flutter/material.dart';

typedef ItemWidgetBuilder<T> = Widget Function(T item);
typedef ItemActionBuilder<T> = void Function(BuildContext context, [T item]);
typedef ItemsActionBuilder<T> = void Function(BuildContext context, List<T> items, Set<T> activeItems);
typedef ItemColorActionBuilder<T> = Color Function(BuildContext context, T item);

class MultiEditBridgeListTab<T> extends StatefulWidget {
  final List<T> items;
  final Set<T> activeItems;
  final ItemWidgetBuilder<T> title;
  final ItemColorActionBuilder<T>? avatarColor;
  final ItemActionBuilder<T>? editAction;
  final ItemActionBuilder<T>? addItemAction;
  final ItemActionBuilder<T>? activeChangeAction;
  final ItemActionBuilder<T>? removeItemAction;
  final ItemsActionBuilder<T>? applyAction;
  final ItemsActionBuilder<T>? resetAction;
  final bool useActiveButton;
  final bool canRemove;
  final bool useSyncScheduleButton;
  final bool canBeEmpty;
  final bool canBeActiveEmpty;
  final String bannerString;

  const MultiEditBridgeListTab({
    super.key,
    required this.items,
    required this.activeItems,
    required this.title,
    required this.bannerString,
    this.avatarColor,
    this.editAction,
    this.addItemAction,
    this.activeChangeAction,
    this.removeItemAction,
    this.useActiveButton = true,
    this.canRemove = true,
    this.useSyncScheduleButton = true,
    this.canBeEmpty = false,
    this.canBeActiveEmpty = false,
    this.applyAction,
    this.resetAction,
  });

  @override
  State<MultiEditBridgeListTab<T>> createState() => _MultiEditBridgeListTabState<T>();
}

class _MultiEditBridgeListTabState<T> extends State<MultiEditBridgeListTab<T>> with FeedbackMixin {
  late Set<T> _activeItems;

  @override
  void initState() {
    super.initState();
    _initializeActiveItems();
  }

  void _initializeActiveItems() {
    _activeItems = widget.useActiveButton ? widget.activeItems : widget.items.toSet();
  }

  @override
  void didUpdateWidget(covariant MultiEditBridgeListTab<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.activeItems != widget.activeItems) {
      _initializeActiveItems();
    }
  }

  void _toggleItemVisibility(T item) {
    setState(() {
      if (_activeItems.contains(item)) {
        if (_activeItems.length <= 1 && !widget.canBeActiveEmpty) {
          showFeedback(context, FeedbackType.info, context.l10n.settingsFgwFixedTabAtLeastOneItemLeaveBeActive);
          return;
        }
        _activeItems.remove(item);
      } else {
        _activeItems.add(item);
      }

      widget.activeChangeAction?.call(context, item);
    });
  }

  void _removeItem(T item) {
    if (_isLastItemInList()) {
      showFeedback(context, FeedbackType.info, context.l10n.settingsFgwFixedTabAtLeastOneItemLeaveWhenRemove);
      return;
    }
    setState(() {
      widget.items.remove(item);
      _activeItems.remove(item);
    });

    widget.removeItemAction?.call(context, item);
  }

  bool _isLastItemInList() {
    return (!widget.canBeActiveEmpty && _activeItems.length <= 1) || (!widget.canBeEmpty && widget.items.length <= 1);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (!settings.useTvLayout) ...[
          MultiTabEditPageBanner(bannerString: widget.bannerString),
          const Divider(height: 0),
        ],
        Flexible(
          child: ReorderableListView.builder(
            itemBuilder: (context, index) => _buildListItem(widget.items[index], index),
            itemCount: widget.items.length,
            onReorder: _onReorder,
            shrinkWrap: true,
          ),
        ),
        const Divider(height: 8),
        _buildActionButtons(context),
        if (widget.resetAction != null || widget.applyAction != null) const Divider(height: 8),
        if (widget.resetAction != null || widget.applyAction != null) _buildResetApplyButtons(context),
        const Divider(height: 8),
      ],
    );
  }

  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      if (oldIndex < newIndex) newIndex -= 1;
      final item = widget.items.removeAt(oldIndex);
      widget.items.insert(newIndex, item);
    });
  }

  Widget _buildListItem(T item, int index) {
    final isActive = _activeItems.contains(item);
    final avatarColor = widget.avatarColor?.call(context, item);

    return Opacity(
      key: ValueKey(item),
      opacity: isActive ? 1 : .4,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: avatarColor ?? Theme.of(context).colorScheme.primary,
          child: Text(_getAvatarNumber(item, isActive).toString()),
        ),
        title: widget.title(item),
        trailing: _buildTrailingActions(item, isActive),
        onTap: settings.useTvLayout ? () => _toggleItemVisibility(item) : null,
      ),
    );
  }

  int _getAvatarNumber(T item, bool isActive) {
    final activeItemsList = widget.items.where(_activeItems.contains).toList();
    return isActive
        ? activeItemsList.indexOf(item) + 1
        : activeItemsList.length + widget.items.where((i) => !_activeItems.contains(i)).toList().indexOf(item) + 1;
  }

  Widget _buildTrailingActions(T item, bool isActive) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.canRemove && _canRemoveItem(item)) _buildActionIcon(AIcons.clear, 'Remove', () => _removeItem(item)),
        if (widget.useActiveButton)
          _buildActionIcon(isActive ? AIcons.active : AIcons.inactive, isActive ? 'Hide' : 'Show',
              () => _toggleItemVisibility(item)),
        if (widget.editAction != null) _buildActionIcon(AIcons.edit, 'Edit', () => widget.editAction!(context, item)),
      ],
    );
  }

  bool _canRemoveItem(T item) {
    if (item is FiltersSetRow) {
      return !fgwSchedules.bridgeAll.any((e) => e.filtersSetId == item.id) &&
          !fgwSchedules.all.any((e) => e.filtersSetId == item.id);
    }
    if (item is FgwScheduleRow) {
      // can only be able to remove widget schedule.
      return item.updateType == WallpaperUpdateType.widget;
    }
    return true;
  }

  Widget _buildActionIcon(IconData icon, String tooltip, VoidCallback onPressed) {
    return IconButton(
      icon: Icon(icon),
      onPressed: onPressed,
      tooltip: tooltip,
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        if (widget.useSyncScheduleButton) const SizedBox(width: 8),
        if (widget.useSyncScheduleButton)
          AvesOutlinedButton(
            icon: const Icon(AIcons.refresh),
            label: context.l10n.settingsFgwScheduleSyncButtonText,
            onPressed: () async {
              await ForegroundWallpaperService.syncFgwScheduleChanges();
              await _showSyncDialog();
            },
          ),
        if (widget.addItemAction != null)
          AvesOutlinedButton(
            icon: const Icon(AIcons.add),
            label: context.l10n.settingsForegroundWallpaperConfigAddItem,
            onPressed: () async {
              widget.addItemAction?.call(context);
              setState(() {});
            },
          ),
      ],
    );
  }

  Widget _buildResetApplyButtons(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (widget.resetAction != null)
            _buildActionButton(context.l10n.resetTooltip, AIcons.reset, widget.resetAction!),
          if (widget.resetAction != null) const SizedBox(width: 32),
          if (widget.applyAction != null)
            _buildActionButton(context.l10n.applyButtonLabel, AIcons.apply, widget.applyAction!),
        ],
      ),
    );
  }

  Widget _buildActionButton(String label, IconData icon, ItemsActionBuilder<T> action) {
    return AvesOutlinedButton(
      icon: Icon(icon),
      label: label,
      onPressed: () async {
        setState(() {
          action(context, List<T>.from(widget.items), Set<T>.from(_activeItems));
        });
      },
    );
  }

  Future<void> _showSyncDialog() async {
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
  }
}
