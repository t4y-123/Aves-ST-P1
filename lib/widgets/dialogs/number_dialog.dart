import 'package:aves/widgets/common/extensions/build_context.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class NumberInputDialog extends StatefulWidget {
  static const routeName = '/dialog/number_input';
  final int initialValue;
  final int? minValue;
  final int? maxValue;

  const NumberInputDialog({
    super.key,
    required this.initialValue,
    this.minValue,
    this.maxValue,
  });

  @override
  State<NumberInputDialog> createState() => _NumberInputDialogState();
}

class _NumberInputDialogState extends State<NumberInputDialog> {
  late TextEditingController _numberController;
  final ValueNotifier<bool> _isValidNotifier = ValueNotifier(false);

  int get initialValue => widget.initialValue;

  @override
  void initState() {
    super.initState();
    _numberController = TextEditingController(text: initialValue.toString());
    _validate();
  }

  @override
  void dispose() {
    _numberController.dispose();
    _isValidNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(context.l10n.enterNumber),
      content: ValueListenableBuilder<bool>(
        valueListenable: _isValidNotifier,
        builder: (context, isValid, child) {
          return TextField(
            keyboardType: TextInputType.number,
            controller: _numberController,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly, // Only allow digits
            ],
            decoration: InputDecoration(
              errorText: isValid ? null : _getErrorMessage(),
            ),
            autofocus: true,
            onChanged: (_) => _validate(),
            onSubmitted: (_) => _submit(context),
          );
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(context.l10n.cancelTooltip),
        ),
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

  void _validate() {
    final text = _numberController.text;
    if (text.isEmpty) {
      _isValidNotifier.value = false;
      return;
    }
    final newValue = int.tryParse(text);
    if (newValue == null) {
      _isValidNotifier.value = false;
      return;
    }
    if (widget.minValue != null && newValue < widget.minValue!) {
      _isValidNotifier.value = false;
      return;
    }
    if (widget.maxValue != null && newValue > widget.maxValue!) {
      _isValidNotifier.value = false;
      return;
    }
    _isValidNotifier.value = true;
  }

  String? _getErrorMessage() {
    final newValue = int.tryParse(_numberController.text);
    if (newValue == null) {
      return 'Invalid number';
    }
    if (widget.minValue != null && newValue < widget.minValue!) {
      return 'Value must be >= ${widget.minValue}';
    }
    if (widget.maxValue != null && newValue > widget.maxValue!) {
      return 'Value must be <= ${widget.maxValue}';
    }
    return null;
  }

  void _submit(BuildContext context) {
    if (_isValidNotifier.value) {
      Navigator.of(context).pop(int.parse(_numberController.text));
    }
  }
}
