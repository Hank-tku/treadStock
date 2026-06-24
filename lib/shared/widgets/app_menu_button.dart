import 'package:flutter/material.dart';
import 'package:stockpilot/core/theme/app_semantic_colors.dart';
import '../../features/settings/presentation/theme_switcher_sheet.dart';

/// A reusable overflow menu button for app headers.
///
/// Currently exposes theme switching. New features (about, settings, etc.)
/// should be added as additional [PopupMenuItem]s here so every tab shares the
/// same entry point.
class AppMenuButton extends StatelessWidget {
  const AppMenuButton({super.key});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: Icon(
        Icons.more_horiz,
        size: 22,
        color: context.sc.textTertiary,
      ),
      tooltip: '功能菜单',
      constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
      padding: EdgeInsets.zero,
      position: PopupMenuPosition.under,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      onSelected: (value) {
        switch (value) {
          case 'theme':
            showThemeSwitcherSheet(context);
            break;
        }
      },
      itemBuilder: (context) => const [
        PopupMenuItem<String>(
          value: 'theme',
          child: Row(
            children: [
              Icon(Icons.dark_mode_outlined, size: 20),
              SizedBox(width: 10),
              Text('主题切换'),
            ],
          ),
        ),
      ],
    );
  }
}
