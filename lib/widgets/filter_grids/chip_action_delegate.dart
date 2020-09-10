import 'package:aves/model/settings/settings.dart';
import 'package:aves/model/source/enums.dart';
import 'package:aves/utils/durations.dart';
import 'package:aves/widgets/common/aves_selection_dialog.dart';
import 'package:aves/widgets/filter_grids/chip_actions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

abstract class ChipActionDelegate {
  ChipSortFactor get sortFactor;

  set sortFactor(ChipSortFactor factor);

  Future<void> onChipActionSelected(BuildContext context, ChipAction action) async {
    // wait for the popup menu to hide before proceeding with the action
    await Future.delayed(Durations.popupMenuAnimation * timeDilation);

    switch (action) {
      case ChipAction.sort:
        await _showSortDialog(context);
        break;
    }
  }

  Future<void> _showSortDialog(BuildContext context) async {
    final factor = await showDialog<ChipSortFactor>(
      context: context,
      builder: (context) => AvesSelectionDialog<ChipSortFactor>(
        initialValue: sortFactor,
        options: {
          ChipSortFactor.date: 'By date',
          ChipSortFactor.name: 'By name',
        },
        title: 'Sort',
      ),
    );
    if (factor != null) {
      sortFactor = factor;
    }
  }
}

class AlbumChipActionDelegate extends ChipActionDelegate {
  @override
  ChipSortFactor get sortFactor => settings.albumSortFactor;

  @override
  set sortFactor(ChipSortFactor factor) => settings.albumSortFactor = factor;
}

class CountryChipActionDelegate extends ChipActionDelegate {
  @override
  ChipSortFactor get sortFactor => settings.countrySortFactor;

  @override
  set sortFactor(ChipSortFactor factor) => settings.countrySortFactor = factor;
}

class TagChipActionDelegate extends ChipActionDelegate {
  @override
  ChipSortFactor get sortFactor => settings.tagSortFactor;

  @override
  set sortFactor(ChipSortFactor factor) => settings.tagSortFactor = factor;
}
