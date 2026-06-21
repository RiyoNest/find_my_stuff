// File: lib/shared/widgets/app_drawer.dart
//
// Custom navigation drawer with theme selection, settings, and useful links.
// Provides access to FAQs, contact developer, about app, and other features.
// Uses RAppRadius / RAppSpacing / RAppColors tokens for visual consistency
// with the rest of the app. Theme mode reads/writes themeModeProvider
// directly so the drawer doesn't need callback props threaded through
// every page that includes it.

import 'package:find_my_stuff/core/constants/app_colours.dart';
import 'package:find_my_stuff/core/constants/app_radius.dart';
import 'package:find_my_stuff/core/constants/app_spacing.dart';
import 'package:find_my_stuff/shared/providers/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final currentTheme = ref.watch(themeModeProvider);

    void onThemeChanged(ThemeMode mode) {
      ref.read(themeModeProvider.notifier).state = mode;
    }

    return Drawer(
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(RAppSpacing.md),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: RAppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(RAppSpacing.sm + 4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(RAppRadius.md),
                    ),
                    child: Icon(
                      Icons.inventory_2_outlined,
                      size: 32,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(height: RAppSpacing.sm),
                  Text(
                    'FindMyStuff',
                    style: theme.textTheme.titleLarge,
                  ),
                  Text(
                    'v1.0.0',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: RAppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: RAppSpacing.lg),
            const SizedBox(height: RAppSpacing.xs),
            Text(
              'Appearance',
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: RAppColors.textSecondary,
              ),
            ),
            const SizedBox(height: RAppSpacing.sm),
            _ThemeSelector(
              currentTheme: currentTheme,
              onThemeChanged: onThemeChanged,
            ),
            const SizedBox(height: RAppSpacing.lg),
            const Divider(height: RAppSpacing.lg),
            const SizedBox(height: RAppSpacing.xs),
            Text(
              'Help & Support',
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: RAppColors.textSecondary,
              ),
            ),
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
            Text(
              'About',
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: RAppColors.textSecondary,
              ),
            ),
            const SizedBox(height: RAppSpacing.sm),
            _DrawerTile(
              icon: Icons.info_outline_rounded,
              label: 'About FindMyStuff',
              onTap: () => _showAboutDialog(context),
            ),
            _DrawerTile(
              icon: Icons.description_outlined,
              label: 'Terms & Privacy',
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Terms & Privacy - Coming Soon'),
                  ),
                );
              },
            ),
            const SizedBox(height: RAppSpacing.lg),
            Center(
              child: Text(
                '© 2024 FindMyStuff\nMade with care',
                textAlign: TextAlign.center,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: RAppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFaqDialog(BuildContext context) {
    Navigator.pop(context);
    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(RAppRadius.lg),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(RAppSpacing.lg - 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Frequently Asked Questions',
                style: Theme.of(dialogContext).textTheme.titleMedium,
              ),
              const SizedBox(height: RAppSpacing.md),
              const _FaqItem(
                question: 'How do I organize my items?',
                answer:
                'Navigate through Place to Room to Location to Section or Container to Item. Each level can contain the next level down, allowing flexible organization.',
              ),
              const _FaqItem(
                question: 'What does Quick Add Item do?',
                answer:
                'Quick Add Item lets you add items directly to any location without navigating the full hierarchy. It appears once you have some locations set up.',
              ),
              const _FaqItem(
                question: 'Can I move items between locations?',
                answer:
                'Yes. Open an item, tap Move, and select a new parent location. Items can move between rooms and locations freely.',
              ),
              const _FaqItem(
                question: 'What does archiving do?',
                answer:
                'Archiving hides items from your main view without deleting them. Archived items can be recovered from the Archived Items section.',
              ),
              const _FaqItem(
                question: 'Is my data stored online?',
                answer:
                'No, FindMyStuff is completely offline-first. All your data is stored locally on your device. No internet required.',
              ),
              const SizedBox(height: RAppSpacing.md),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showContactDialog(BuildContext context) {
    Navigator.pop(context);
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(RAppRadius.lg),
        ),
        title: const Text('Contact Developer'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Have feedback or questions? Reach out.',
              style: Theme.of(dialogContext).textTheme.bodyMedium,
            ),
            const SizedBox(height: RAppSpacing.md),
            const _ContactOption(
              icon: Icons.email,
              label: 'Email',
              value: 'developer@findmystuff.app',
            ),
            const SizedBox(height: RAppSpacing.sm),
            const _ContactOption(
              icon: Icons.language,
              label: 'Website',
              value: 'www.findmystuff.app',
            ),
            const SizedBox(height: RAppSpacing.sm),
            const _ContactOption(
              icon: Icons.chat_bubble_outline,
              label: 'Discord',
              value: 'discord.gg/findmystuff',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showBugReportDialog(BuildContext context) {
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Bug report feature coming soon')),
    );
  }

  void _showAboutDialog(BuildContext context) {
    Navigator.pop(context);
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(RAppRadius.lg),
        ),
        title: const Text('About FindMyStuff'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "FindMyStuff is an offline-first app that helps you remember where you've stored your belongings.",
                style: Theme.of(dialogContext).textTheme.bodyMedium,
              ),
              const SizedBox(height: RAppSpacing.md),
              Text(
                'Features:',
                style: Theme.of(dialogContext).textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: RAppSpacing.sm),
              const _AboutFeature(
                'Organize items hierarchically by room, location, and container',
              ),
              const _AboutFeature(
                'Search items instantly across your entire place',
              ),
              const _AboutFeature('Mark important items for quick access'),
              const _AboutFeature('Track expiry dates for perishables'),
              const _AboutFeature('Add photos to identify items visually'),
              const _AboutFeature('Completely offline, no internet required'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close'),
          ),
        ],
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

class _FaqItem extends StatefulWidget {
  final String question;
  final String answer;

  const _FaqItem({required this.question, required this.answer});

  @override
  State<_FaqItem> createState() => _FaqItemState();
}

class _FaqItemState extends State<_FaqItem> {
  bool isExpanded = false;

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
        onTap: () => setState(() => isExpanded = !isExpanded),
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
                  Icon(
                    isExpanded
                        ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded,
                    size: 20,
                  ),
                ],
              ),
              if (isExpanded) ...[
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

class _ContactOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _ContactOption({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Icon(icon, size: 20),
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
      ],
    );
  }
}

class _AboutFeature extends StatelessWidget {
  final String text;

  const _AboutFeature(this.text);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: RAppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 16,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: RAppSpacing.sm),
          Expanded(child: Text(text, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );
  }
}