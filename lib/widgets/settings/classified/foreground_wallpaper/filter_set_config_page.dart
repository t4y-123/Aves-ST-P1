import 'package:aves/widgets/common/basic/scaffold.dart';
import 'package:aves/widgets/common/extensions/build_context.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import '../../../../model/foreground_wallpaper/filterSet.dart';
import '../../../../model/filters/aspect_ratio.dart';
import '../../../../model/filters/filters.dart';
import '../../../../model/filters/mime.dart';
import '../../../common/identity/buttons/outlined_button.dart';
import '../../common/collection_tile.dart';

class FilterSetConfigPage extends StatefulWidget {
  static const routeName = '/settings/classified/filter_set_config';
  final FilterSetRow? item;
  final List<FilterSetRow?> allItems;
  final Set<FilterSetRow?> activeItems;

  const FilterSetConfigPage({
    super.key,
    required this.item,
    required this.allItems,
    required this.activeItems,
  });

  @override
  State<FilterSetConfigPage> createState() => _FilterSetConfigPageState();
}
class _FilterSetConfigPageState extends State<FilterSetConfigPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _aliasNameController;
  late FilterSetRow? _currentItem;
  late Set<CollectionFilter> _collectionFilters;

  @override
  void initState() {
    super.initState();
    final int newFilterSetNum = _generateFilterSetNum();
    final int newId = _generateUniqueId();
    _currentItem = widget.item ?? FilterSetRow(
      filterSetId: newId,
      filterSetNum: newFilterSetNum,
      aliasName: 'N$newFilterSetNum id:$newId',
      filters: {AspectRatioFilter.portrait, MimeFilter.image},
    );
    _aliasNameController = TextEditingController(text: _currentItem!.aliasName);
    _collectionFilters = _currentItem?.filters ?? {};
  }

  int _generateUniqueId() {
    int id = 1;
    while (filterSet.all.any((item) => item.filterSetId == id)) {
      id++;
    }
    return id;
  }

  int _generateFilterSetNum() {
    // final activeItems = widget.allItems.where((item) => item?.isActive ?? false).toList();
    final int maxLevelNow = widget.allItems.where((item) => widget.activeItems.contains(item)).length;
    return maxLevelNow + 1;
  }

  void _applyChanges() {
    if (_formKey.currentState?.validate() ?? false) {
      final updatedItem = FilterSetRow(
        filterSetId: _currentItem!.filterSetId,
        filterSetNum: _currentItem!.filterSetNum,
        aliasName: _aliasNameController.text,
        filters:_collectionFilters,
      );
      Navigator.pop(context, updatedItem); // Return the updated item
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AvesScaffold(
      appBar: AppBar(
        title: Text(l10n.settingsConfirmationDialogTitle),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              Text('ID: ${_currentItem?.filterSetId ?? ''}'),
              const SizedBox(height: 8),
              Text('Sequence Number: ${_currentItem?.filterSetNum ?? ''}'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _aliasNameController,
                decoration: const InputDecoration(labelText: 'Alias Name'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an alias name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              SettingsCollectionTile(
                filters: _collectionFilters,
                onSelection: (v) => setState(() => _collectionFilters = v),
              ),
              AvesOutlinedButton(
                onPressed: _applyChanges,
                label: context.l10n.settingsForegroundWallpaperConfigApplyChanges,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
