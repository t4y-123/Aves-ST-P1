import 'dart:math';

import 'package:aves/model/presentation/base_bridge_row.dart';
import 'package:aves/theme/durations.dart';
import 'package:aves/widgets/common/action_mixins/feedback.dart';
import 'package:aves/widgets/common/app_bar/app_bar_title.dart';
import 'package:aves/widgets/common/basic/insets.dart';
import 'package:aves/widgets/common/basic/scaffold.dart';
import 'package:aves/widgets/common/extensions/build_context.dart';
import 'package:aves/widgets/common/extensions/media_query.dart';
import 'package:aves/widgets/settings/settings_definition.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:provider/provider.dart';

class PresentRowItemPage<T extends PresentRow<T>> extends StatefulWidget {
  final T item;
  final List<SettingsTile> Function(T item) buildTiles;

  const PresentRowItemPage({
    super.key,
    required this.item,
    required this.buildTiles,
  });

  @override
  State<PresentRowItemPage<T>> createState() => _PresentRowItemPageState<T>();
}

class _PresentRowItemPageState<T extends PresentRow<T>> extends State<PresentRowItemPage<T>> with FeedbackMixin {
  final ValueNotifier<String?> _expandedNotifier = ValueNotifier(null);
  T get _item => widget.item;

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
      ),
      body: GestureAreaProtectorStack(
        child: SafeArea(
          bottom: false,
          child: AnimationLimiter(
            child: _buildSettingsList(context),
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsList(BuildContext context) {
    final durations = context.watch<DurationsData>();

    return Selector<MediaQueryData, double>(
      selector: (context, mq) => max(mq.effectiveBottomPadding, mq.systemGestureInsets.bottom),
      builder: (context, mqPaddingBottom, __) {
        return ListView(
          padding: const EdgeInsets.all(8) + EdgeInsets.only(bottom: mqPaddingBottom),
          children: AnimationConfiguration.toStaggeredList(
            duration: durations.staggeredAnimation,
            delay: durations.staggeredAnimationDelay * timeDilation,
            childAnimationBuilder: (child) => SlideAnimation(
              verticalOffset: 50.0,
              child: FadeInAnimation(child: child),
            ),
            children: [
              ...widget.buildTiles(_item).map((v) => v.build(context)),
              CommonApplyTile<T>(item: _item).build(context),
            ],
          ),
        );
      },
    );
  }
}

class CommonApplyTile<T> extends SettingsTile {
  @override
  String title(BuildContext context) => context.l10n.applyTooltip;

  final T item;

  CommonApplyTile({
    required this.item,
  });

  @override
  Widget build(BuildContext context) => ListTile(
        title: null,
        trailing: ElevatedButton(
          onPressed: () async {
            Navigator.of(context).pop(true);
          },
          child: Text(context.l10n.applyTooltip),
        ),
      );
}
