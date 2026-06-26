// File: lib/shared/widgets/quick_add_sheet.dart

import 'package:flutter/material.dart';
import '../../core/constants/app_radius.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/utils/validation_helpers.dart';
import '../enums/node_type.dart';

class QuickAddSheet extends StatefulWidget {
  final String title;
  final String? hintText;
  final String? labelText;
  final int maxLength;
  final String? Function(String)? validator;

  const QuickAddSheet({
    super.key,
    required this.title,
    this.hintText,
    this.labelText,
    this.maxLength = 50,
    this.validator,
  });

  static Future<String?> show(
    BuildContext context, {
    required String title,
    String? hintText,
    String? labelText,
    int maxLength = 50,
    String? Function(String)? validator,
  }) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(RAppRadius.xl),
        ),
      ),
      builder: (_) => QuickAddSheet(
        title: title,
        hintText: hintText,
        labelText: labelText,
        maxLength: maxLength,
        validator: validator,
      ),
    );
  }

  @override
  State<QuickAddSheet> createState() => _QuickAddSheetState();
}

class _QuickAddSheetState extends State<QuickAddSheet> {
  final _controller = TextEditingController();
  String? _errorText;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    final val = widget.validator ?? ValidationHelpers.validateItemName;
    setState(() => _errorText = val(value));
  }

  void _save() {
    final val = widget.validator ?? ValidationHelpers.validateItemName;
    final error = val(_controller.text);
    setState(() => _errorText = error);
    if (error != null) return;
    Navigator.pop(context, ValidationHelpers.sanitize(_controller.text));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final val = widget.validator ?? ValidationHelpers.validateItemName;
    final isValid = val(_controller.text) == null && _controller.text.trim().isNotEmpty;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            RAppSpacing.lg,
            8,
            RAppSpacing.lg,
            RAppSpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.title,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: RAppSpacing.md + 4),
              TextField(
                controller: _controller,
                autofocus: true,
                textCapitalization: TextCapitalization.words,
                maxLength: widget.maxLength,
                cursorColor: const Color(0xFFD10047),
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
                decoration: InputDecoration(
                  hintText: widget.hintText,
                  labelText: widget.labelText ?? 'Name',
                  labelStyle: TextStyle(
                    color: _errorText != null
                        ? theme.colorScheme.error
                        : const Color(0xFFD10047),
                  ),
                  floatingLabelStyle: TextStyle(
                    color: _errorText != null
                        ? theme.colorScheme.error
                        : const Color(0xFFD10047),
                  ),
                  hintStyle: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant.withOpacity(0.6),
                  ),
                  filled: true,
                  fillColor: isDark
                      ? theme.colorScheme.surfaceContainerHighest.withOpacity(0.4)
                      : const Color(0xFFFFF5F8),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: isDark ? theme.colorScheme.outline.withOpacity(0.3) : const Color(0xFFF8D7E3),
                      width: 1,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: isDark ? theme.colorScheme.outline.withOpacity(0.3) : const Color(0xFFF8D7E3),
                      width: 1,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFD10047), width: 1.5),
                  ),
                  errorText: _errorText,
                ),
                onChanged: _onChanged,
                onSubmitted: (_) => _save(),
              ),
              const SizedBox(height: RAppSpacing.md + 4),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: isValid ? _save : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFD10047),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: isDark
                        ? theme.colorScheme.onSurface.withOpacity(0.12)
                        : Colors.grey[200],
                    disabledForegroundColor: isDark
                        ? theme.colorScheme.onSurface.withOpacity(0.38)
                        : Colors.grey[500],
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Save',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AddChildTypeSheet extends StatelessWidget {
  const AddChildTypeSheet({super.key});

  static Future<NodeType?> show(BuildContext context) {
    return showModalBottomSheet<NodeType>(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(RAppRadius.xl),
        ),
      ),
      builder: (_) => const AddChildTypeSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          RAppSpacing.lg,
          8,
          RAppSpacing.lg,
          RAppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Add Contents',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: RAppSpacing.md),
            _buildTypeOption(
              context,
              icon: Icons.view_agenda_outlined,
              iconColor: isDark ? theme.colorScheme.primaryContainer : Colors.blue,
              title: 'Section',
              subtitle: 'A logical grouping inside a location — e.g. "Top Shelf", "Left Side"',
              onTap: () => Navigator.pop(context, NodeType.section),
            ),
            const SizedBox(height: RAppSpacing.xs),
            _buildTypeOption(
              context,
              icon: Icons.inventory_2_outlined,
              iconColor: isDark ? Colors.amber[300]! : Colors.amber[700]!,
              title: 'Container',
              subtitle: 'A physical container — e.g. "Red Box", "Zip Pouch"',
              onTap: () => Navigator.pop(context, NodeType.container),
            ),
            const SizedBox(height: RAppSpacing.xs),
            _buildTypeOption(
              context,
              icon: Icons.label_outline,
              iconColor: const Color(0xFFD10047),
              title: 'Item',
              subtitle: 'An individual item you want to track — e.g. "Passport"',
              onTap: () => Navigator.pop(context, NodeType.item),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeOption(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isDark ? theme.colorScheme.outline.withOpacity(0.3) : const Color(0xFFF8D7E3),
          width: 0.8,
        ),
      ),
      child: ListTile(
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        hoverColor: isDark
            ? theme.colorScheme.surfaceContainerHighest.withOpacity(0.3)
            : const Color(0xFFFFF5F8),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 24),
        ),
        title: Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}