import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_semantic_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/providers.dart';

/// A bottom sheet that lets the user pick a theme mode
/// (system / light / dark). Shown via [showThemeSwitcherSheet].
class ThemeSwitcherSheet extends ConsumerWidget {
  const ThemeSwitcherSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(themeModeProvider);

    final options = <(ThemeMode, IconData, String, String)>[
      (ThemeMode.system, Icons.brightness_auto_outlined, '跟随系统',
          '根据系统设置自动切换浅色/深色'),
      (ThemeMode.light, Icons.light_mode_outlined, '浅色', '始终使用浅色主题'),
      (ThemeMode.dark, Icons.dark_mode_outlined, '深色', '始终使用深色主题'),
    ];

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppTheme.pagePadding,
          12,
          AppTheme.pagePadding,
          16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text('主题', style: AppTextStyles.h2),
            ),
            ...options.map((o) {
              final (mode, icon, title, subtitle) = o;
              final selected = current == mode;
              return _ThemeOption(
                icon: icon,
                title: title,
                subtitle: subtitle,
                selected: selected,
                onTap: () {
                  ref.read(themeModeProvider.notifier).set(mode);
                  Navigator.of(context).pop();
                },
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  const _ThemeOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Row(
          children: [
            Icon(
              icon,
              size: 22,
              color: selected ? StockColors.brand : context.sc.textTertiary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.body.copyWith(
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                      color: context.sc.textPrimary,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: AppTextStyles.caption.copyWith(
                      color: context.sc.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
            if (selected)
              const Icon(Icons.check_circle, size: 20, color: StockColors.brand)
            else
              Icon(Icons.radio_button_unchecked,
                  size: 20, color: context.sc.textDisabled),
          ],
        ),
      ),
    );
  }
}

/// Convenience function to show the theme switcher as a modal bottom sheet.
void showThemeSwitcherSheet(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (_) => const ThemeSwitcherSheet(),
  );
}
