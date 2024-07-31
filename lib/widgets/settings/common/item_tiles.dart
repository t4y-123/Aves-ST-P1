import 'package:aves/model/settings/settings.dart';
import 'package:aves/theme/durations.dart';
import 'package:aves/theme/text.dart';
import 'package:aves/utils/time_utils.dart';
import 'package:aves/widgets/common/extensions/build_context.dart';
import 'package:aves/widgets/common/identity/aves_caption.dart';
import 'package:aves/widgets/dialogs/duration_dialog.dart';
import 'package:aves/widgets/dialogs/selection_dialogs/common.dart';
import 'package:aves/widgets/dialogs/selection_dialogs/multi_selection.dart';
import 'package:aves/widgets/dialogs/selection_dialogs/single_selection.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../dialogs/aves_dialog.dart';
import 'item_dialog.dart';

class ItemSettingsSubPageTile<S> extends StatelessWidget {
  final String title, routeName;
  final WidgetBuilder builder;
  final String Function(BuildContext, S) subtitleSelector;

  const ItemSettingsSubPageTile({
    super.key,
    required this.title,
    required this.routeName,
    required this.builder,
    required this.subtitleSelector,
  });

  @override
  Widget build(BuildContext context) {
    return Selector<S, String>(
      selector: subtitleSelector,
      builder: (context, current, child) {
        return ListTile(
          title: Text(title),
          subtitle: Text(current),
          onTap: () {
            Navigator.maybeOf(context)?.push(
              MaterialPageRoute(
                settings: RouteSettings(name: routeName),
                builder: builder,
              ),
            );
          },
        );
      },
    );
  }
}

class ItemSettingsSwitchListTile<S> extends StatelessWidget {
  final bool Function(BuildContext, S) selector;
  final ValueChanged<bool> onChanged;
  final String title;
  final String? subtitle;
  final Widget? trailing;

  static const disabledOpacity = .2;

  const ItemSettingsSwitchListTile({
    super.key,
    required this.selector,
    required this.onChanged,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Selector<S, bool>(
      selector: selector,
      builder: (context, current, child) {
    Widget titleWidget = Text(title);
    if (trailing != null) {
      titleWidget = Row(
        children: [
          Expanded(child: titleWidget),
          AnimatedOpacity(
                opacity: current ? 1 : disabledOpacity,
            duration: ADurations.toggleableTransitionAnimation,
            child: trailing,
          ),
        ],
      );
    }
    return SwitchListTile(
          value: current,
      onChanged: onChanged,
      title: titleWidget,
      subtitle: subtitle != null ? Text(subtitle!) : null,
        );
      },
    );
  }
}

class ItemSettingsSelectionListTile<S,T> extends StatelessWidget {
  final List<T> values;
  final String Function(BuildContext, T) getName;
  final T Function(BuildContext, S) selector;
  final ValueChanged<T> onSelection;
  final String tileTitle;
  final WidgetBuilder? trailingBuilder;
  final String? dialogTitle;
  final TextBuilder<T>? optionSubtitleBuilder;
  final bool showSubTitle;

  const ItemSettingsSelectionListTile({
    super.key,
    required this.values,
    required this.getName,
    required this.selector,
    required this.onSelection,
    required this.tileTitle,
    this.trailingBuilder,
    this.dialogTitle,
    this.optionSubtitleBuilder,
    this.showSubTitle = true,
  });

  @override
  Widget build(BuildContext context) {
    return Selector<S, T>(
      selector: selector,
      builder: (context, current, child) {
    Widget titleWidget = Text(tileTitle);
    if (trailingBuilder != null) {
      titleWidget = Row(
        children: [
          Expanded(child: titleWidget),
          trailingBuilder!(context),
        ],
      );
    }
    return ListTile(
      title: titleWidget,
        subtitle: showSubTitle?AvesCaption(getName(context, current)):null,
      onTap: () => showSelectionDialog<T>(
        context: context,
        builder: (context) => AvesSingleSelectionDialog<T>(
              initialValue: current,
          options: Map.fromEntries(values.map((v) => MapEntry(v, getName(context, v)))),
          optionSubtitleBuilder: optionSubtitleBuilder,
          title: dialogTitle,
        ),
        onSelection: onSelection,
      ),
    );
      },
    );
  }
}

class ItemSettingsMultiSelectionListTile<S,T>  extends StatelessWidget {
  final List<T> values;
  final String Function(BuildContext, T) getName;
  final List<T> Function(BuildContext, S) selector;
  final ValueChanged<List<T>> onSelection;
  final String tileTitle, noneSubtitle;
  final WidgetBuilder? trailingBuilder;
  final String? dialogTitle;
  final TextBuilder<T>? optionSubtitleBuilder;

  const ItemSettingsMultiSelectionListTile({
    super.key,
    required this.values,
    required this.getName,
    required this.selector,
    required this.onSelection,
    required this.tileTitle,
    required this.noneSubtitle,
    this.trailingBuilder,
    this.dialogTitle,
    this.optionSubtitleBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return Selector<S, List<T>>(
      selector: selector,
      builder: (context, current, child) {
        Widget titleWidget = Text(tileTitle);
        if (trailingBuilder != null) {
          titleWidget = Row(
            children: [
              Expanded(child: titleWidget),
              trailingBuilder!(context),
            ],
          );
        }
        return ListTile(
          title: titleWidget,
          subtitle: AvesCaption(current.isEmpty ? noneSubtitle : current.map((v) => getName(context, v)).join(AText.separator)),
          onTap: () => showSelectionDialog<List<T>>(
            context: context,
            builder: (context) => AvesMultiSelectionDialog<T>(
              initialValue: current.toSet(),
              options: Map.fromEntries(values.map((v) => MapEntry(v, getName(context, v)))),
              optionSubtitleBuilder: optionSubtitleBuilder,
              title: dialogTitle,
            ),
            onSelection: onSelection,
          ),
        );
      },
    );
  }
}

// t4y: to make it can deal with some group multi selection that should auto cancel the values not in the same group.
// like, in wallpaper schedule update, {home,lock} and {both} will cancel each other if any.
class ItemSettingsMultiSelectionWithExcludeSetListTile<S, T> extends StatelessWidget {
  final List<T> values;
  final String Function(BuildContext, T) getName;
  final List<T> Function(BuildContext, S) selector;
  final ValueChanged<List<T>> onSelection;
  final String tileTitle, noneSubtitle;
  final WidgetBuilder? trailingBuilder;
  final String? dialogTitle;
  final TextBuilder<T>? optionSubtitleBuilder;
  final List<Set<T>> conflictGroups;

  const ItemSettingsMultiSelectionWithExcludeSetListTile({
    super.key,
    required this.values,
    required this.getName,
    required this.selector,
    required this.onSelection,
    required this.tileTitle,
    required this.noneSubtitle,
    this.trailingBuilder,
    this.dialogTitle,
    this.optionSubtitleBuilder,
    required this.conflictGroups,
  });

  @override
  Widget build(BuildContext context) {
    return Selector<S, List<T>>(
      selector: selector,
      builder: (context, current, child) {
        Widget titleWidget = Text(tileTitle);
        if (trailingBuilder != null) {
          titleWidget = Row(
            children: [
              Expanded(child: titleWidget),
              trailingBuilder!(context),
            ],
          );
        }
        return ListTile(
          title: titleWidget,
          subtitle: AvesCaption(current.isEmpty ? noneSubtitle : current.map((v) => getName(context, v)).join(AText.separator)),
          onTap: () => showSelectionDialog<List<T>>(
            context: context,
            builder: (context) => AvesMultiSelectionWithConflictGroupDialog<T>(
              initialValue: current.toSet(),
              options: Map.fromEntries(values.map((v) => MapEntry(v, getName(context, v)))),
              optionSubtitleBuilder: optionSubtitleBuilder,
              title: dialogTitle,
              conflictGroups: conflictGroups,
            ),
            onSelection: onSelection,
          ),
        );
      },
    );
  }
}


class ItemSettingsDurationListTile extends StatelessWidget {
  final int Function(BuildContext, Settings) selector;
  final ValueChanged<int> onChanged;
  final String title;

  const ItemSettingsDurationListTile({
    super.key,
    required this.selector,
    required this.onChanged,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Selector<Settings, int>(
      selector: selector,
      builder: (context, current, child) {
        final currentMinutes = current ~/ secondsInMinute;
        final currentSeconds = current % secondsInMinute;

        final l10n = context.l10n;
        final subtitle = [
          if (currentMinutes > 0) l10n.timeMinutes(currentMinutes),
          if (currentSeconds > 0) l10n.timeSeconds(currentSeconds),
        ].join(' ');

        return ListTile(
          title: Text(title),
          subtitle: AvesCaption(subtitle),
          onTap: () async {
            final v = await showDialog<int>(
              context: context,
              builder: (context) => DurationDialog(initialSeconds: current),
            );
            if (v != null) {
              onChanged(v);
            }
          },
        );
      },
    );
  }
}


// for only show some info , tap will do nothing.
class ItemInfoListTile<S> extends StatelessWidget {
  final String Function(BuildContext, S) selector;
  final String tileTitle;

  const ItemInfoListTile({
    super.key,
    required this.selector,
    required this.tileTitle,
  });

  @override
  Widget build(BuildContext context) {
    return Selector<S, String>(
      selector: selector,
      builder: (context, current, child) {
        return ListTile(
          title: Text(tileTitle),
          subtitle: AvesCaption(current),
          onTap: () async {
            await showDialog<String>(
              context: context,
              builder: (context) => AlertDialog(
                content: Text('$tileTitle\n$current'),
                actions: <Widget>[
                  FilledButton(
                    child:Text(context.l10n.cancelTooltip),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}


class ItemSettingsLabelNameListTile<S> extends StatelessWidget {
  final String Function(BuildContext, S) selector;
  final ValueChanged<String> onChanged;
  final String tileTitle;

  const ItemSettingsLabelNameListTile({
    super.key,
    required this.selector,
    required this.onChanged,
    required this.tileTitle,
  });

  @override
  Widget build(BuildContext context) {
    return Selector<S, String>(
        selector: selector,
        builder: (context, current, child) {
        return ListTile(
          title: Text(tileTitle),
          subtitle: AvesCaption(current),
          onTap: () async {
            final newValue = await showDialog<String>(
              context: context,
              builder: (context) => LabelNameDialog(label: current),
            );
            if (newValue != null && newValue != current) {
              onChanged(newValue);
            }
          },
        );
      },
    );
  }
}

class LabelNameDialog extends StatefulWidget {
  static const routeName = '/dialog/label_name';

  final String label;

  const LabelNameDialog({
    super.key,
    required this.label,
  });

  @override
  State<LabelNameDialog> createState() => _RenameLabelDialogState();
}

class _RenameLabelDialogState extends State<LabelNameDialog> {
  final TextEditingController _nameController = TextEditingController();
  final ValueNotifier<bool> _existsNotifier = ValueNotifier(false);
  final ValueNotifier<bool> _isValidNotifier = ValueNotifier(false);

  String get label => widget.label;

  @override
  void initState() {
    super.initState();
    _nameController.text = label;
    _validate();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _existsNotifier.dispose();
    _isValidNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AvesDialog(
      content: ValueListenableBuilder<bool>(
          valueListenable: _existsNotifier,
          builder: (context, exists, child) {
            return TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: context.l10n.renameLabelNameDialogLabel,
                helperText: exists ? context.l10n.renameLabelNameDialogLabelAlreadyExistsHelper : '',
              ),
              autofocus: true,
              onChanged: (_) => _validate(),
              onSubmitted: (_) => _submit(context),
            );
          }),
      actions: [
        const CancelButton(),
        ValueListenableBuilder<bool>(
          valueListenable: _isValidNotifier,
          builder: (context, isValid, child) {
            return TextButton(
              onPressed: isValid ? () => _submit(context) : null,
              child: Text(context.l10n.applyButtonLabel),
            );
          },
        ),
      ],
    );
  }

  Future<void> _validate() async {
    final newName = _nameController.text;
    bool coantianIllegal = newName.contains(',');
    _existsNotifier.value = newName.isNotEmpty && newName == label || coantianIllegal;
    _isValidNotifier.value = newName.isNotEmpty && !coantianIllegal && !_existsNotifier.value;
  }

  void _submit(BuildContext context) {
    if (_isValidNotifier.value) {
      Navigator.maybeOf(context)?.pop(_nameController.text);
    }
  }
}




