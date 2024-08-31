import 'package:aves/model/fgw/filters_set.dart';
import 'package:aves/model/filters/aspect_ratio.dart';
import 'package:aves/model/filters/filters.dart';
import 'package:aves/model/filters/mime.dart';
import 'package:aves/services/common/services.dart';
import 'package:aves/widgets/common/basic/scaffold.dart';
import 'package:aves/widgets/common/extensions/build_context.dart';
import 'package:aves/widgets/common/identity/buttons/outlined_button.dart';
import 'package:aves/widgets/settings/common/collection_tile.dart';
import 'package:flutter/material.dart';

class FilterSetConfigPage extends StatefulWidget {
  static const routeName = '/settings/presentation/filter_set_config';
  final FiltersSetRow? item;
  final List<FiltersSetRow?> allItems;
  final Set<FiltersSetRow?> activeItems;

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
  late FiltersSetRow? _currentItem;
  late Set<CollectionFilter> _collectionFilters;
  bool _isActive = false;

  @override
  void initState() {
    super.initState();
    final int newFilterSetNum = _generateFilterSetNum();
    final int newId = metadataDb.nextId;
    _currentItem = widget.item ??
        FiltersSetRow(
          id: newId,
          orderNum: newFilterSetNum,
          labelName: 'N$newFilterSetNum id:$newId',
          filters: {AspectRatioFilter.portrait, MimeFilter.image},
          isActive: true,
        );
    _aliasNameController = TextEditingController(text: _currentItem!.labelName);
    _collectionFilters = _currentItem?.filters ?? {};
    _isActive = _currentItem!.isActive;
  }

  int _generateFilterSetNum() {
    // final activeItems = widget.allItems.where((item) => item?.isActive ?? false).toList();
    final int maxLevelNow = widget.allItems.where((item) => widget.activeItems.contains(item)).length;
    return maxLevelNow + 1;
  }

  void _applyChanges() {
    if (_formKey.currentState?.validate() ?? false) {
      final updatedItem = FiltersSetRow(
        id: _currentItem!.id,
        orderNum: _currentItem!.orderNum,
        labelName: _aliasNameController.text,
        filters: _collectionFilters,
        isActive: _isActive,
      );
      Navigator.pop(context, updatedItem); // Return the updated item
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AvesScaffold(
      appBar: AppBar(
        title: Text(l10n.settingsFilterSetTabTypes),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              Text('ID: ${_currentItem?.id ?? ''}'),
              const SizedBox(height: 8),
              Text('Sequence Number: ${_currentItem?.orderNum ?? ''}'),
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
              const SizedBox(height: 20),
              SwitchListTile(
                title: const Text('Active'),
                value: _isActive,
                onChanged: (value) {
                  setState(() {
                    _isActive = value;
                  });
                },
              ),
              const SizedBox(height: 20),
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
