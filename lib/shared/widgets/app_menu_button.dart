import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:stockpilot/core/theme/app_semantic_colors.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_theme.dart';
import '../../features/settings/presentation/theme_switcher_sheet.dart';

/// A reusable hamburger menu button for app headers.
/// Opens a right-side app drawer with product info and shared settings.
class AppMenuButton extends StatefulWidget {
  const AppMenuButton({super.key});

  @override
  State<AppMenuButton> createState() => _AppMenuButtonState();
}

class _AppMenuButtonState extends State<AppMenuButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _pressAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: AppTheme.fastDuration,
      vsync: this,
    );
    _pressAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pressAnimation,
      builder: (context, child) {
        final value = _pressAnimation.value;
        return Transform.scale(
          scale: 1 - value * 0.06,
          child: AnimatedContainer(
            duration: AppTheme.fastDuration,
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Color.lerp(
                Colors.transparent,
                context.sc.brandLight,
                value,
              ),
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            ),
            child: IconButton(
              onPressed: () => _openSidebar(context),
              tooltip: '功能菜单',
              icon: Icon(
                Icons.menu,
                size: 25,
                color: Color.lerp(
                  context.sc.textTertiary,
                  StockColors.brand,
                  value,
                ),
              ),
              padding: EdgeInsets.zero,
            ),
          ),
        );
      },
    );
  }

  Future<void> _openSidebar(BuildContext context) async {
    final parentContext = context;
    _controller.forward();
    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: '关闭菜单',
      barrierColor: Colors.black.withAlpha(72),
      transitionDuration: AppTheme.normalDuration,
      pageBuilder: (context, animation, secondaryAnimation) {
        return Align(
          alignment: Alignment.centerRight,
          child: _AppSideDrawer(
            onClose: () => Navigator.of(context).pop(),
            onThemeTap: () {
              Navigator.of(context).pop();
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (parentContext.mounted) {
                  showThemeSwitcherSheet(parentContext);
                }
              });
            },
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1, 0),
              end: Offset.zero,
            ).animate(curved),
            child: child,
          ),
        );
      },
    );
    if (mounted) {
      _controller.reverse();
    }
  }
}

class _AppSideDrawer extends StatelessWidget {
  final VoidCallback onClose;
  final VoidCallback onThemeTap;

  const _AppSideDrawer({required this.onClose, required this.onThemeTap});

  @override
  Widget build(BuildContext context) {
    final width = math.min(MediaQuery.sizeOf(context).width * 0.86, 340.0);
    return Material(
      color: Colors.transparent,
      child: SafeArea(
        left: false,
        child: Container(
          width: width,
          height: double.infinity,
          decoration: BoxDecoration(
            color: context.sc.bgPrimary,
            borderRadius: const BorderRadius.horizontal(
              left: Radius.circular(AppTheme.radiusXl),
            ),
            boxShadow: const [
              BoxShadow(
                color: StockColors.shadowLg,
                blurRadius: 24,
                offset: Offset(-8, 0),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 12, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '股势 TrendStock',
                        style: AppTextStyles.h2.copyWith(
                          color: context.sc.textPrimary,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: onClose,
                      tooltip: '关闭菜单',
                      icon: const Icon(Icons.close),
                      color: context.sc.textTertiary,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  children: [
                    _AboutCard(),
                    const SizedBox(height: 18),
                    Text(
                      '设置',
                      style: AppTextStyles.caption.copyWith(
                        color: context.sc.textTertiary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _DrawerActionTile(
                      icon: Icons.dark_mode_outlined,
                      title: '主题切换',
                      subtitle: '跟随系统、浅色或深色',
                      onTap: onThemeTap,
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Text(
                  '以上分析仅供参考，不构成任何投资建议。',
                  style: AppTextStyles.caption.copyWith(
                    color: context.sc.textTertiary,
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

class _AboutCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.sc.brandLight,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: context.sc.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: StockColors.brand,
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            ),
            child: const Icon(Icons.trending_up, color: Colors.white, size: 24),
          ),
          const SizedBox(height: 14),
          Text(
            '关于股势',
            style: AppTextStyles.h2.copyWith(color: context.sc.textPrimary),
          ),
          const SizedBox(height: 8),
          Text(
            '股势是面向 A 股观察与策略复盘的本地工具，帮助你把行情、关注列表和策略线索放在一起看。',
            style: AppTextStyles.body.copyWith(color: context.sc.textSecondary),
          ),
          const SizedBox(height: 14),
          const _FeaturePoint(
            icon: Icons.shield_outlined,
            text: '无账号、无云同步，关注和策略配置保存在本机',
          ),
          const _FeaturePoint(
            icon: Icons.insights_outlined,
            text: '用均线、布林带、量比和趋势评分辅助复盘',
          ),
          const _FeaturePoint(
            icon: Icons.school_outlined,
            text: '策略用于观察和学习，不替代你的独立判断',
          ),
        ],
      ),
    );
  }
}

class _FeaturePoint extends StatelessWidget {
  final IconData icon;
  final String text;

  const _FeaturePoint({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: StockColors.brand),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.caption.copyWith(
                color: context.sc.textSecondary,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DrawerActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _DrawerActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.sc.bgSecondary,
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Icon(icon, color: StockColors.brand, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.body.copyWith(
                        color: context.sc.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: AppTextStyles.caption.copyWith(
                        color: context.sc.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: context.sc.textTertiary),
            ],
          ),
        ),
      ),
    );
  }
}
