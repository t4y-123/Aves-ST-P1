import 'package:aves/model/filters/query.dart';
import 'package:aves/widgets/common/extensions/build_context.dart';
import 'package:flutter/material.dart';

class QueryFilterDialog extends StatefulWidget {
  final String queryKey;
  final bool isNotQuery;
  final String operator;
  final String? unit;
  final int? value;

  const QueryFilterDialog({
    required this.queryKey,
    this.isNotQuery = false,
    this.operator = '<',
    this.unit = 'M',
    this.value,
    super.key,
  });

  @override
  State<QueryFilterDialog> createState() => _QueryFilterDialogState();
}

class _QueryFilterDialogState extends State<QueryFilterDialog> {
  late String operator;
  String? unit;
  int? value;

  int? _years;
  int? _months;
  int? _days;
  int? _hours;
  int? _minutes;
  int? _seconds;

  @override
  void initState() {
    super.initState();
    operator = widget.operator;
    unit = widget.unit;
    value = widget.value;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    String keyContent = widget.queryKey;
    return AlertDialog(
      title: Text(l10n.queryHelperDialogTitle),
      content: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.5, // Limit the height
          ),
          child: keyContent == QueryFilter.keyContentTime2Now
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(l10n.queryHelperDialogOperator),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              operator = operator == '='
                                  ? '<'
                                  : operator == '<'
                                      ? '>'
                                      : '=';
                            });
                          },
                          child: Text(operator),
                        ),
                      ],
                    ),
                    _buildTimeInputRow(l10n.queryHelperDialogYear, (value) => setState(() => _years = value)),
                    _buildTimeInputRow(l10n.queryHelperDialogMonths, (value) => setState(() => _months = value)),
                    _buildTimeInputRow(l10n.queryHelperDialogDays, (value) => setState(() => _days = value)),
                    _buildTimeInputRow(l10n.queryHelperDialogHours, (value) => setState(() => _hours = value)),
                    _buildTimeInputRow(l10n.queryHelperDialogMinutes, (value) => setState(() => _minutes = value)),
                    _buildTimeInputRow(l10n.queryHelperDialogSeconds, (value) => setState(() => _seconds = value)),
                  ],
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      '$keyContent',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 8.0),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          operator = operator == '='
                              ? '<'
                              : operator == '<'
                                  ? '>'
                                  : '=';
                        });
                      },
                      child: Text(operator),
                    ),
                    const SizedBox(width: 8.0),
                    SizedBox(
                      width: 60,
                      child: TextField(
                        keyboardType: TextInputType.number,
                        onChanged: (newValue) {
                          value = int.tryParse(newValue);
                        },
                        decoration: InputDecoration(
                          hintText: l10n.queryHelperDialogValueHintText,
                          border: const OutlineInputBorder(),
                          contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 8),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8.0),
                    if (keyContent == QueryFilter.keyContentSize)
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            unit = unit == null
                                ? 'K'
                                : unit == 'K'
                                    ? 'M'
                                    : unit == 'M'
                                        ? 'G'
                                        : 'K';
                          });
                        },
                        child: Text('${unit}B'),
                      ),
                  ],
                ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, null),
          child: Text(context.l10n.cancelTooltip),
        ),
        TextButton(
          onPressed: () {
            var queryResult = keyContent + operator;
            if (keyContent == QueryFilter.keyContentTime2Now) {
              queryResult +=
                  '${_years ?? 0}Y${_months ?? 0}M${_days ?? 0}D ${_hours ?? 0}HH${_minutes ?? 0}MM${_seconds ?? 0}SS';
            } else {
              queryResult += (value != null ? value.toString() : '');
              if (keyContent == QueryFilter.keyContentSize && unit != null) {
                queryResult += unit!;
              }
            }
            Navigator.pop(context, queryResult);
          },
          child: Text(context.l10n.applyButtonLabel),
        ),
      ],
    );
  }

  Widget _buildTimeInputRow(String label, Function(int) onChanged) {
    return Row(
      children: [
        Text('$label: '),
        const Spacer(),
        SizedBox(
          width: 60,
          child: TextField(
            textAlign: TextAlign.end, // Align text to the end (right side)
            keyboardType: TextInputType.number,
            onChanged: (newValue) {
              final intValue = int.tryParse(newValue) ?? 0;
              onChanged(intValue);
            },
            decoration: const InputDecoration(
              hintText: '0',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 8),
            ),
          ),
        ),
      ],
    );
  }
}
