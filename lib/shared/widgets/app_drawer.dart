// File: lib/shared/widgets/app_drawer.dart
//
// CHANGES in this version:
//   - All four dialogs (About, Contact, Bug Report, FAQ) converted to
//     bottom sheets (showModalBottomSheet with DraggableScrollableSheet)
//     so they feel native on mobile instead of popping up as overlays.
//   - About: app identity + _AboutInfoRow emoji rows + features.
//   - Contact + Bug Report: _ContactCard tiles with clipboard copy.
//   - FAQ: animated accordion items inside a draggable sheet.
//   - Drawer header version from AppInfoService.fullVersion.

import 'package:find_my_stuff/core/constants/app_colours.dart';
import 'package:find_my_stuff/core/constants/app_radius.dart';
import 'package:find_my_stuff/core/constants/app_spacing.dart';
import 'package:find_my_stuff/core/services/app_info_service.dart';
import 'package:find_my_stuff/shared/providers/theme_provider.dart';
import 'package:find_my_stuff/shared/widgets/custom_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final currentTheme = ref.watch(themeModeProvider);

    void onThemeChanged(ThemeMode mode) {
      ref.read(themeModeProvider.notifier).setThemeMode(mode);
    }

    return Drawer(
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(RAppSpacing.md),
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(vertical: RAppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(RAppRadius.md),
                    ),
                    child: Image.asset('assets/logo/app_logo.png', width: 50),
                  ),
                  const SizedBox(height: RAppSpacing.sm),
                  Text('FindMyStuff', style: theme.textTheme.titleLarge),
                  Text(
                    AppInfoService.fullVersion,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: RAppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            const Divider(height: RAppSpacing.lg),
            const SizedBox(height: RAppSpacing.xs),

            _SectionLabel('Appearance'),
            const SizedBox(height: RAppSpacing.sm),
            _ThemeSelector(
              currentTheme: currentTheme,
              onThemeChanged: onThemeChanged,
            ),

            const SizedBox(height: RAppSpacing.lg),
            const Divider(height: RAppSpacing.lg),
            const SizedBox(height: RAppSpacing.xs),

            _SectionLabel('Help & Support'),
            const SizedBox(height: RAppSpacing.sm),
            _DrawerTile(
              icon: Icons.help_outline_rounded,
              label: 'FAQs',
              onTap: () => _showFaqDialog(context),
            ),
            _DrawerTile(
              icon: Icons.email_outlined,
              label: 'Contact Developer',
              onTap: () => _showContactDialog(context),
            ),
            _DrawerTile(
              icon: Icons.bug_report_outlined,
              label: 'Report a Bug',
              onTap: () => _showBugReportDialog(context),
            ),

            const SizedBox(height: RAppSpacing.lg),
            const Divider(height: RAppSpacing.lg),
            const SizedBox(height: RAppSpacing.xs),

            _SectionLabel('About'),
            const SizedBox(height: RAppSpacing.sm),
            _DrawerTile(
              icon: Icons.info_outline_rounded,
              label: 'About FindMyStuff',
              onTap: () => _showAboutDialog(context),
            ),
          ],
        ),
      ),
    );
  }

  // ── About ──────────────────────────────────────────────────────────────
  void _showAboutDialog(BuildContext context) {
    Navigator.pop(context);
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(RAppRadius.xl)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.75,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (_, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(RAppSpacing.lg, 0, RAppSpacing.lg, RAppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // App identity block
              Container(
                padding: const EdgeInsets.all(RAppSpacing.md),
                decoration: BoxDecoration(
                  color: Theme.of(ctx).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(RAppRadius.md),
                ),
                child: Image.asset('assets/logo/app_logo.png', width: 64),
              ),
              const SizedBox(height: RAppSpacing.sm),
              Text('FindMyStuff', style: Theme.of(ctx).textTheme.titleLarge),
              Text(
                AppInfoService.fullVersion,
                style: Theme.of(ctx).textTheme.labelMedium?.copyWith(
                  color: RAppColors.textSecondary,
                ),
              ),

              const SizedBox(height: RAppSpacing.lg),
              const Divider(),
              const SizedBox(height: RAppSpacing.md),

              // Info rows
              _AboutInfoRow(emoji: '👨‍💻', title: 'Developer', value: 'Ruban'),
              const SizedBox(height: RAppSpacing.sm),
              _AboutInfoRow(
                emoji: '📧',
                title: 'Contact',
                value: 'riyooruban@gmail.com',
                copyable: true,
                snackContext: ctx,
              ),
              const SizedBox(height: RAppSpacing.sm),
              _AboutInfoRow(
                emoji: '🚀',
                title: 'Version',
                value: AppInfoService.fullVersion,
              ),

              const SizedBox(height: RAppSpacing.lg),
              const Divider(),
              const SizedBox(height: RAppSpacing.md),

              // Features
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'What FindMyStuff does',
                  style: Theme.of(ctx).textTheme.titleSmall,
                ),
              ),
              const SizedBox(height: RAppSpacing.sm),
              const _AboutFeature(
                icon: Icons.account_tree_outlined,
                text: 'Organise items hierarchically by room, location, and container',
              ),
              const _AboutFeature(
                icon: Icons.search_rounded,
                text: 'Search items instantly across your entire place',
              ),
              const _AboutFeature(
                icon: Icons.star_outline_rounded,
                text: 'Mark important items for quick access',
              ),
              const _AboutFeature(
                icon: Icons.schedule_rounded,
                text: 'Track expiry dates for perishables',
              ),
              const _AboutFeature(
                icon: Icons.photo_camera_outlined,
                text: 'Add photos to identify items visually',
              ),
              const _AboutFeature(
                icon: Icons.wifi_off_rounded,
                text: 'Completely offline — no internet required',
              ),

              const SizedBox(height: RAppSpacing.lg),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Close'),
                ),
              ),
              const SizedBox(height: RAppSpacing.md),
            ],
          ),
        ),
      ),
    );
  }

  // ── Contact ────────────────────────────────────────────────────────────
  void _showContactDialog(BuildContext context) {
    Navigator.pop(context);
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(RAppRadius.xl)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(RAppSpacing.lg, 0, RAppSpacing.lg, RAppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Contact Developer', style: Theme.of(ctx).textTheme.titleMedium),
              const SizedBox(height: RAppSpacing.xs),
              Text(
                'Have feedback, ideas, or found a problem? Get in touch.',
                style: Theme.of(ctx).textTheme.bodyMedium,
              ),
              const SizedBox(height: RAppSpacing.md),
              _ContactCard(
                icon: Icons.person_outline_rounded,
                label: 'Developer',
                value: 'Ruban',
              ),
              const SizedBox(height: RAppSpacing.sm),
              _ContactCard(
                icon: Icons.email_outlined,
                label: 'Email',
                value: 'riyooruban@gmail.com',
                copyable: true,
                snackContext: ctx,
              ),
              const SizedBox(height: RAppSpacing.md),
            ],
          ),
        ),
      ),
    );
  }

  // ── Bug Report ─────────────────────────────────────────────────────────
  void _showBugReportDialog(BuildContext context) {
    Navigator.pop(context);
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(RAppRadius.xl)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(RAppSpacing.lg, 0, RAppSpacing.lg, RAppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.bug_report_outlined, color: Theme.of(ctx).colorScheme.primary, size: 20),
                  const SizedBox(width: RAppSpacing.sm),
                  Text('Report a Bug', style: Theme.of(ctx).textTheme.titleMedium),
                ],
              ),
              const SizedBox(height: RAppSpacing.sm),
              Text(
                'Found something wrong? Send an email with:',
                style: Theme.of(ctx).textTheme.bodyMedium,
              ),
              const SizedBox(height: RAppSpacing.sm),
              _BulletPoint('What you were trying to do'),
              _BulletPoint('What happened instead'),
              _BulletPoint('Your device model (optional)'),
              const SizedBox(height: RAppSpacing.md),
              _ContactCard(
                icon: Icons.email_outlined,
                label: 'Send to',
                value: 'riyooruban@gmail.com',
                copyable: true,
                snackContext: ctx,
              ),
              const SizedBox(height: RAppSpacing.md),
            ],
          ),
        ),
      ),
    );
  }

  // ── FAQ ────────────────────────────────────────────────────────────────
  void _showFaqDialog(BuildContext context) {
    Navigator.pop(context);
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(RAppRadius.xl)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        minChildSize: 0.4,
        builder: (_, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(RAppSpacing.lg, 0, RAppSpacing.lg, RAppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(RAppSpacing.sm),
                    decoration: BoxDecoration(
                      color: Theme.of(ctx).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(RAppRadius.sm),
                    ),
                    child: Icon(
                      Icons.help_outline_rounded,
                      color: Theme.of(ctx).colorScheme.onPrimaryContainer,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: RAppSpacing.sm),
                  Text('FAQs', style: Theme.of(ctx).textTheme.titleMedium),
                ],
              ),
              const SizedBox(height: RAppSpacing.md),

              const _FaqItem(
                question: 'How do I organise my items?',
                answer:
                'Navigate: Place → Room → Location → Section/Container → Item. Each level holds the next. Tap the + button on any page to add the next level down.',
              ),
              const _FaqItem(
                question: 'What does Quick Add Item do?',
                answer:
                'Quick Add Item lets you add items directly to any location without navigating the full hierarchy. It appears on the Home screen once you have at least one location set up.',
              ),
              const _FaqItem(
                question: 'Can I move items between locations?',
                answer:
                'Yes. Open any item, tap Move in the action bar at the bottom, then choose a new location from the searchable list.',
              ),
              const _FaqItem(
                question: 'What does archiving do?',
                answer:
                'Archiving hides items from your main view without deleting them. You can restore archived items anytime from the Archived Items page in the menu.',
              ),
              const _FaqItem(
                question: "What's the difference between Section and Container?",
                answer:
                'A Section is a logical grouping (e.g. "Top Shelf", "Left Side"). A Container is a physical object (e.g. "Red Box", "Drawer"). Both can hold more sections, containers, or items.',
              ),
              const _FaqItem(
                question: 'Is my data stored online?',
                answer:
                'No. FindMyStuff is fully offline. All data lives on your device — no account, no internet needed.',
              ),

              const SizedBox(height: RAppSpacing.md),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Got it'),
                ),
              ),
              const SizedBox(height: RAppSpacing.md),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Shared sub-widgets ──────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.labelMedium?.copyWith(
        fontWeight: FontWeight.w600,
        color: RAppColors.textSecondary,
      ),
    );
  }
}

class _ThemeSelector extends StatelessWidget {
  final ThemeMode currentTheme;
  final void Function(ThemeMode) onThemeChanged;

  const _ThemeSelector({
    required this.currentTheme,
    required this.onThemeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(RAppSpacing.sm + 4),
      decoration: BoxDecoration(
        border: Border.all(color: RAppColors.border),
        borderRadius: BorderRadius.circular(RAppRadius.md),
      ),
      child: Column(
        children: [
          _ThemeOption(
            icon: Icons.light_mode_outlined,
            label: 'Light',
            isSelected: currentTheme == ThemeMode.light,
            onTap: () => onThemeChanged(ThemeMode.light),
          ),
          const Divider(height: RAppSpacing.md),
          _ThemeOption(
            icon: Icons.dark_mode_outlined,
            label: 'Dark',
            isSelected: currentTheme == ThemeMode.dark,
            onTap: () => onThemeChanged(ThemeMode.dark),
          ),
          const Divider(height: RAppSpacing.md),
          _ThemeOption(
            icon: Icons.brightness_auto_outlined,
            label: 'System',
            isSelected: currentTheme == ThemeMode.system,
            onTap: () => onThemeChanged(ThemeMode.system),
          ),
        ],
      ),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ThemeOption({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(RAppRadius.sm),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: RAppSpacing.sm,
          horizontal: RAppSpacing.sm,
        ),
        child: Row(
          children: [
            Icon(icon, size: 20),
            const SizedBox(width: RAppSpacing.sm + 4),
            Text(label, style: theme.textTheme.bodyMedium),
            const Spacer(),
            Icon(
              isSelected ? Icons.check_circle : Icons.circle_outlined,
              color: isSelected
                  ? theme.colorScheme.primary
                  : RAppColors.textSecondary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _DrawerTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, size: 20),
      title: Text(label, style: Theme.of(context).textTheme.bodyMedium),
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
      horizontalTitleGap: RAppSpacing.sm + 4,
    );
  }
}

/// Emoji + title + value info row used in the About dialog.
class _AboutInfoRow extends StatelessWidget {
  final String emoji;
  final String title;
  final String value;
  final bool copyable;
  final BuildContext? snackContext;

  const _AboutInfoRow({
    required this.emoji,
    required this.title,
    required this.value,
    this.copyable = false,
    this.snackContext,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: copyable && snackContext != null
          ? () {
        Clipboard.setData(ClipboardData(text: value));
        AppSnackBar.success(snackContext!, '$title copied to clipboard');
      }
          : null,
      borderRadius: BorderRadius.circular(RAppRadius.sm),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: RAppSpacing.sm + 4,
          vertical: RAppSpacing.sm + 2,
        ),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(RAppRadius.sm),
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: RAppSpacing.sm + 4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: RAppColors.textSecondary,
                    ),
                  ),
                  Text(
                    value,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            if (copyable)
              Icon(
                Icons.copy_outlined,
                size: 16,
                color: RAppColors.textSecondary,
              ),
          ],
        ),
      ),
    );
  }
}

/// Tappable contact card with icon + label + value + optional clipboard copy.
class _ContactCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool copyable;
  final BuildContext? snackContext;

  const _ContactCard({
    required this.icon,
    required this.label,
    required this.value,
    this.copyable = false,
    this.snackContext,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      borderRadius: BorderRadius.circular(RAppRadius.md),
      onTap: copyable && snackContext != null
          ? () {
        Clipboard.setData(ClipboardData(text: value));
        AppSnackBar.success(snackContext!, '$label copied to clipboard');
      }
          : null,
      child: Container(
        padding: const EdgeInsets.all(RAppSpacing.md),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(RAppRadius.md),
          border: Border.all(color: RAppColors.border),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(RAppSpacing.sm),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(RAppRadius.sm),
              ),
              child: Icon(
                icon,
                size: 18,
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(width: RAppSpacing.sm + 4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: RAppColors.textSecondary,
                    ),
                  ),
                  Text(
                    value,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            if (copyable)
              Icon(Icons.copy_outlined, size: 16, color: RAppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}

/// Feature row in the About dialog.
class _AboutFeature extends StatelessWidget {
  final IconData icon;
  final String text;

  const _AboutFeature({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: RAppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.primary),
          const SizedBox(width: RAppSpacing.sm),
          Expanded(child: Text(text, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );
  }
}

/// Bullet point used in the Bug Report dialog.
class _BulletPoint extends StatelessWidget {
  final String text;
  const _BulletPoint(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: RAppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(fontWeight: FontWeight.bold)),
          Expanded(
            child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}

/// Expandable FAQ accordion with animated chevron.
class _FaqItem extends StatefulWidget {
  final String question;
  final String answer;

  const _FaqItem({required this.question, required this.answer});

  @override
  State<_FaqItem> createState() => _FaqItemState();
}

class _FaqItemState extends State<_FaqItem> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: RAppSpacing.sm),
      decoration: BoxDecoration(
        border: Border.all(color: RAppColors.border),
        borderRadius: BorderRadius.circular(RAppRadius.sm),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(RAppRadius.sm),
        onTap: () => setState(() => _expanded = !_expanded),
        child: Padding(
          padding: const EdgeInsets.all(RAppSpacing.sm + 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.question,
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(Icons.expand_more_rounded, size: 20),
                  ),
                ],
              ),
              if (_expanded) ...[
                const SizedBox(height: RAppSpacing.sm),
                const Divider(height: 1),
                const SizedBox(height: RAppSpacing.sm),
                Text(widget.answer, style: theme.textTheme.bodyMedium),
              ],
            ],
          ),
        ),
      ),
    );
  }
}