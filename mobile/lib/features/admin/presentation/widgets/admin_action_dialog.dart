import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';

class AdminActionField {
  final String key;
  final String label;
  final String? initialValue;
  final bool required;
  final int maxLines;
  final TextInputType keyboardType;
  final List<String>? options;
  final String? helperText;

  const AdminActionField({
    required this.key,
    required this.label,
    this.initialValue,
    this.required = true,
    this.maxLines = 1,
    this.keyboardType = TextInputType.text,
    this.options,
    this.helperText,
  });
}

class AdminActionDialog extends StatefulWidget {
  final String title;
  final String message;
  final String? warning;
  final List<AdminActionField> fields;
  final String confirmLabel;
  final bool destructive;

  const AdminActionDialog({
    super.key,
    required this.title,
    required this.message,
    this.warning,
    required this.fields,
    this.confirmLabel = 'Confirm',
    this.destructive = false,
  });

  @override
  State<AdminActionDialog> createState() => _AdminActionDialogState();
}

class _AdminActionDialogState extends State<AdminActionDialog> {
  final _formKey = GlobalKey<FormState>();
  late final List<TextEditingController> _controllers;
  late final List<String?> _selections;

  @override
  void initState() {
    super.initState();
    _controllers = widget.fields
        .map((field) => TextEditingController(text: field.initialValue ?? ''))
        .toList();
    _selections = widget.fields.map((field) {
      final options = field.options;
      if (options == null || options.isEmpty) return null;
      return options.firstWhere(
        (option) => option == field.initialValue,
        orElse: () => options.first,
      );
    }).toList();
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final values = <String, String>{};
    for (var index = 0; index < widget.fields.length; index++) {
      final field = widget.fields[index];
      values[field.key] = field.options == null
          ? _controllers[index].text.trim()
          : (_selections[index] ?? '');
    }
    Navigator.of(context).pop(values);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AlertDialog(
      backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.dialogBorderRadius),
      ),
      title: Text(widget.title),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(widget.message),
            if (widget.warning != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.warning.withOpacity(0.45),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      color: AppColors.warning,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.warning!,
                        style: const TextStyle(
                          color: AppColors.warning,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  for (var index = 0; index < widget.fields.length; index++)
                    _buildField(index, widget.fields[index], isDark),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        AppButton(
          text: widget.confirmLabel,
          onPressed: _submit,
          customColor: widget.destructive ? AppColors.error : null,
          height: 42,
        ),
      ],
    );
  }

  Widget _buildField(int index, AdminActionField field, bool isDark) {
    if (field.options != null) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: DropdownButtonFormField<String>(
          key: ValueKey<String>('admin-field-${field.key}'),
          initialValue: _selections[index],
          isExpanded: true,
          decoration: InputDecoration(
            labelText: field.label,
            helperText: field.helperText,
            border: const OutlineInputBorder(),
          ),
          items: [
            for (final option in field.options!)
              DropdownMenuItem<String>(value: option, child: Text(option)),
          ],
          validator: field.required
              ? (value) => (value == null || value.isEmpty)
                    ? '${field.label} is required.'
                    : null
              : null,
          onChanged: (value) => setState(() => _selections[index] = value),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppTextField(
        key: ValueKey<String>('admin-field-${field.key}'),
        controller: _controllers[index],
        labelText: field.label,
        helperText: field.helperText,
        maxLines: field.maxLines,
        keyboardType: field.keyboardType,
        inputFormatters: field.keyboardType == TextInputType.number
            ? <TextInputFormatter>[
                FilteringTextInputFormatter.allow(RegExp(r'^-?\d*\.?\d*$')),
              ]
            : null,
        validator: field.required
            ? (value) => (value == null || value.trim().isEmpty)
                  ? '${field.label} is required.'
                  : null
            : null,
      ),
    );
  }
}

Future<Map<String, String>?> showAdminActionDialog({
  required BuildContext context,
  required String title,
  required String message,
  String? warning,
  required List<AdminActionField> fields,
  String confirmLabel = 'Confirm',
  bool destructive = false,
}) {
  return showDialog<Map<String, String>>(
    context: context,
    builder: (context) => AdminActionDialog(
      title: title,
      message: message,
      warning: warning,
      fields: fields,
      confirmLabel: confirmLabel,
      destructive: destructive,
    ),
  );
}
