import 'package:flutter/material.dart';
import 'package:stockpilot/core/theme/app_semantic_colors.dart';
import '../../features/settings/presentation/theme_switcher_sheet.dart';

/// A reusable hamburger menu button for app headers, with a rotation
/// animation when the popup opens/closes.
///
/// Currently exposes theme switching. New features (about, settings, etc.)
/// should be added as additional [PopupMenuItem]s here so every tab shares the
/// same entry point.
class AppMenuButton extends StatefulWidget {
  const AppMenuButton({super.key});

  @override
  State<AppMenuButton> createState() => _AppMenuButtonState();
}

class _AppMenuButtonState extends State<AppMenuButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: RotationTransition(
        turns: _animation.drive(Tween<double>(begin: 0.0, end: 0.25)),
        child: Icon(
          Icons.menu,
          size: 24,
          color: context.sc.textTertiary,
        ),
      ),
      tooltip: '功能菜单',
      constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
      padding: EdgeInsets.zero,
      position: PopupMenuPosition.under,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      onOpened: () => _controller.forward(),
      onCanceled: () => _controller.reverse(),
      onSelected: (value) {
        _controller.reverse();
        _handleMenu(value);
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

  void _handleMenu(String value) {
    switch (value) {
      case 'theme':
        showThemeSwitcherSheet(context);
        break;
    }
  }
}
