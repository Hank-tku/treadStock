import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stockpilot/core/theme/app_semantic_colors.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_theme.dart';
import '../providers.dart';
import 'toast_helper.dart';

/// A reusable hamburger menu button for app headers.
/// Opens a compact settings-style side panel.
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
              onPressed: () => _openSettings(context),
              tooltip: '设置',
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

  Future<void> _openSettings(BuildContext context) async {
    _controller.forward();
    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: '关闭设置',
      barrierColor: Colors.black.withAlpha(84),
      transitionDuration: AppTheme.normalDuration,
      pageBuilder: (context, animation, secondaryAnimation) {
        return Align(
          alignment: Alignment.centerRight,
          child: _SettingsPanel(onClose: () => Navigator.of(context).pop()),
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

class _SettingsPanel extends ConsumerStatefulWidget {
  final VoidCallback onClose;

  const _SettingsPanel({required this.onClose});

  @override
  ConsumerState<_SettingsPanel> createState() => _SettingsPanelState();
}

class _SettingsPanelState extends ConsumerState<_SettingsPanel> {
  String? _expandedSection = 'about';
  bool _isClearingCache = false;

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isCompact = screenWidth < 600;

    return Material(
      color: Colors.transparent,
      child: SafeArea(
        left: false,
        right: false,
        bottom: false,
        child: Container(
          width: isCompact ? double.infinity : 380,
          height: double.infinity,
          decoration: BoxDecoration(
            color: context.sc.bgSecondary,
            borderRadius: isCompact
                ? BorderRadius.zero
                : const BorderRadius.horizontal(
                    left: Radius.circular(AppTheme.radiusXl),
                  ),
            boxShadow: isCompact
                ? null
                : const [
                    BoxShadow(
                      color: StockColors.shadowLg,
                      blurRadius: 24,
                      offset: Offset(-8, 0),
                    ),
                  ],
          ),
          child: Column(
            children: [
              _DrawerHandleHeader(onClose: widget.onClose),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.fromLTRB(
                    isCompact ? 16 : 18,
                    8,
                    isCompact ? 16 : 18,
                    32 + MediaQuery.paddingOf(context).bottom,
                  ),
                  children: [
                    _AccordionItem(
                      id: 'about',
                      title: '关于应用',
                      icon: Icons.info_outline,
                      expanded: _expandedSection == 'about',
                      onTap: _toggleSection,
                      child: const _AboutContent(),
                    ),
                    _AccordionItem(
                      id: 'theme',
                      title: '主题',
                      icon: Icons.dark_mode_outlined,
                      trailingText: _themeLabel(themeMode),
                      expanded: _expandedSection == 'theme',
                      onTap: _toggleSection,
                      child: _ThemeContent(
                        current: themeMode,
                        onSelect: (mode) =>
                            ref.read(themeModeProvider.notifier).set(mode),
                      ),
                    ),
                    _AccordionItem(
                      id: 'cache',
                      title: '清理缓存',
                      icon: Icons.cleaning_services_outlined,
                      trailingText: _isClearingCache ? '清理中' : null,
                      expanded: _expandedSection == 'cache',
                      onTap: _toggleSection,
                      child: _CacheContent(
                        isClearing: _isClearingCache,
                        onClear: _isClearingCache ? null : _clearCache,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
                child: Text(
                  '以上分析仅供参考，不构成任何投资建议。',
                  textAlign: TextAlign.center,
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

  void _toggleSection(String id) {
    setState(() {
      _expandedSection = _expandedSection == id ? null : id;
    });
  }

  String _themeLabel(ThemeMode mode) {
    return switch (mode) {
      ThemeMode.light => '浅色',
      ThemeMode.dark => '深色',
      ThemeMode.system => '跟随系统',
    };
  }

  Future<void> _clearCache() async {
    setState(() => _isClearingCache = true);
    try {
      await ref.read(cachedStockApiServiceProvider).clearCache();
      if (!mounted) return;
      ToastHelper.showSuccess(context, '缓存已清理');
    } catch (_) {
      if (!mounted) return;
      ToastHelper.showError(context, '清理失败，请重试');
    } finally {
      if (mounted) {
        setState(() => _isClearingCache = false);
      }
    }
  }
}

class _DrawerHandleHeader extends StatelessWidget {
  final VoidCallback onClose;

  const _DrawerHandleHeader({required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 14, 10),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: StockColors.brand,
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            ),
            child: const Icon(Icons.trending_up, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '设置',
              style: AppTextStyles.bodyLg.copyWith(
                color: context.sc.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          IconButton(
            onPressed: onClose,
            tooltip: '关闭',
            icon: const Icon(Icons.close),
            iconSize: 22,
            color: context.sc.textTertiary,
            style: IconButton.styleFrom(
              backgroundColor: context.sc.bgPrimary,
              fixedSize: const Size(38, 38),
            ),
          ),
        ],
      ),
    );
  }
}

class _AccordionItem extends StatelessWidget {
  final String id;
  final String title;
  final IconData icon;
  final String? trailingText;
  final bool expanded;
  final ValueChanged<String> onTap;
  final Widget child;

  const _AccordionItem({
    required this.id,
    required this.title,
    required this.icon,
    required this.expanded,
    required this.onTap,
    required this.child,
    this.trailingText,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      decoration: BoxDecoration(
        color: context.sc.bgPrimary,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: context.sc.borderLight),
      ),
      child: Column(
        children: [
          Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            child: InkWell(
              onTap: () => onTap(id),
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              child: SizedBox(
                height: 62,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: expanded
                              ? context.sc.brandLight
                              : context.sc.bgSecondary,
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusSm,
                          ),
                        ),
                        child: Icon(
                          icon,
                          size: 19,
                          color: expanded
                              ? StockColors.brand
                              : context.sc.textTertiary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          title,
                          style: AppTextStyles.body.copyWith(
                            color: context.sc.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      if (trailingText != null) ...[
                        Text(
                          trailingText!,
                          style: AppTextStyles.caption.copyWith(
                            color: context.sc.textTertiary,
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      AnimatedRotation(
                        turns: expanded ? 0.5 : 0,
                        duration: AppTheme.fastDuration,
                        curve: Curves.easeOutCubic,
                        child: Icon(
                          Icons.keyboard_arrow_down,
                          size: 24,
                          color: context.sc.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox(width: double.infinity),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: child,
            ),
            crossFadeState: expanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: AppTheme.normalDuration,
            firstCurve: Curves.easeOutCubic,
            secondCurve: Curves.easeOutCubic,
            sizeCurve: Curves.easeOutCubic,
          ),
        ],
      ),
    );
  }
}

class _AboutContent extends StatelessWidget {
  const _AboutContent();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
      decoration: BoxDecoration(
        color: context.sc.bgSecondary,
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '股势',
            style: AppTextStyles.bodyLg.copyWith(
              color: context.sc.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '面向 A 股观察与策略复盘的本地工具。关注列表、策略配置和缓存数据保存在本机，用公开行情和技术指标提供观察线索。',
            style: AppTextStyles.caption.copyWith(
              color: context.sc.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _ThemeContent extends StatelessWidget {
  final ThemeMode current;
  final ValueChanged<ThemeMode> onSelect;

  const _ThemeContent({required this.current, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final options = <(ThemeMode, String)>[
      (ThemeMode.system, '跟随系统'),
      (ThemeMode.light, '浅色'),
      (ThemeMode.dark, '深色'),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: context.sc.bgSecondary,
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      ),
      child: Column(
        children: options.map((option) {
          final selected = current == option.$1;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Material(
              color: selected ? context.sc.bgPrimary : Colors.transparent,
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              child: InkWell(
                onTap: () => onSelect(option.$1),
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          option.$2,
                          style: AppTextStyles.body.copyWith(
                            color: selected
                                ? StockColors.brand
                                : context.sc.textPrimary,
                            fontWeight: selected
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                        ),
                      ),
                      Icon(
                        selected
                            ? Icons.check_circle
                            : Icons.radio_button_unchecked,
                        size: 20,
                        color: selected
                            ? StockColors.brand
                            : context.sc.textTertiary,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _CacheContent extends StatelessWidget {
  final bool isClearing;
  final VoidCallback? onClear;

  const _CacheContent({required this.isClearing, required this.onClear});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.sc.bgSecondary,
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '清理本地 K 线缓存，不会删除关注列表和策略配置。',
            style: AppTextStyles.caption.copyWith(
              color: context.sc.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 42,
            child: ElevatedButton.icon(
              onPressed: onClear,
              icon: isClearing
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.delete_sweep_outlined, size: 18),
              label: Text(isClearing ? '清理中...' : '清理缓存'),
              style: ElevatedButton.styleFrom(
                backgroundColor: StockColors.brand,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
