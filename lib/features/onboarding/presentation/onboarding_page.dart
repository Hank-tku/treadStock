import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_theme.dart';
import '../data/onboarding_service.dart';
import '../providers/onboarding_provider.dart';

/// Descriptions mapped to each investment style key.
class _StyleInfo {
  final String emoji;
  final String title;
  final String subtitle;
  final String strategyName;
  final String description;

  const _StyleInfo({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.strategyName,
    required this.description,
  });
}

const _styleMap = <String, _StyleInfo>{
  'conservative': _StyleInfo(
    emoji: '\u{1F6E1}\uFE0F',
    title: '保守型',
    subtitle: '防御保值策略',
    strategyName: '防御保值策略',
    description: '侧重低估值和抗跌能力，精选安全边际较高的标的，适合追求稳健的投资者。',
  ),
  'balanced': _StyleInfo(
    emoji: '\u{2696}\uFE0F',
    title: '稳健型',
    subtitle: '均衡波段策略',
    strategyName: '均衡波段策略',
    description: '平衡趋势和均值回归信号，捕捉波段行情中的机会，适合中短期投资者。',
  ),
  'aggressive': _StyleInfo(
    emoji: '\u{1F680}',
    title: '激进型',
    subtitle: '短线突破策略',
    strategyName: '短线突破策略',
    description: '追踪强势股突破信号，快进快出，适合有丰富短线经验的投资者。',
  ),
};

class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  final _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToPage(int page) {
    _pageController.animateToPage(
      page,
      duration: AppTheme.normalDuration,
      curve: AppTheme.easeInOut,
    );
  }

  Future<void> _onFinish() async {
    final style = ref.read(investmentStyleProvider);
    final service = OnboardingService();
    await service.setCompleted();
    if (style != null) {
      await service.saveStyle(style);
    }
    if (mounted) {
      context.go('/dashboard');
    }
  }

  void _onSkip() {
    _onFinish();
  }

  @override
  Widget build(BuildContext context) {
    final style = ref.watch(investmentStyleProvider);

    return Scaffold(
      backgroundColor: StockColors.bgPrimary,
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, AppTheme.space4, AppTheme.pagePadding, 0),
                child: TextButton(
                  onPressed: _onSkip,
                  child: Text(
                    '跳过',
                    style: TextStyle(
                      fontSize: 14,
                      color: StockColors.textTertiary,
                    ),
                  ),
                ),
              ),
            ),
            // Page content
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (index) => setState(() => _currentPage = index),
                children: [
                  _buildPage1(),
                  _buildPage2(style),
                  _buildPage3(style),
                ],
              ),
            ),
            // Dot indicators
            Padding(
              padding: const EdgeInsets.only(bottom: AppTheme.space8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(3, (i) {
                  final isActive = i == _currentPage;
                  return AnimatedContainer(
                    duration: AppTheme.fastDuration,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: isActive ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: isActive ? StockColors.brand : StockColors.gray300,
                      borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Page 1: Choose investment style ──────────────────────────────────

  Widget _buildPage1() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.pagePadding),
      child: Column(
        children: [
          const SizedBox(height: AppTheme.space6),
          Text(
            '你的投资风格？',
            style: AppTextStyles.h1.copyWith(
              color: StockColors.textPrimary,
              fontFamily: AppTheme.textFont,
            ),
          ),
          const SizedBox(height: AppTheme.space2),
          Text(
            '选择最接近你的投资偏好',
            style: TextStyle(
              fontSize: 14,
              color: StockColors.textTertiary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: AppTheme.space8),
          ..._styleMap.entries.map((e) => _StyleCard(
                info: e.value,
                styleKey: e.key,
                isSelected: ref.watch(investmentStyleProvider) == e.key,
                onTap: () {
                  ref.read(investmentStyleProvider.notifier).state = e.key;
                  _goToPage(1);
                },
              )),
        ],
      ),
    );
  }

  // ── Page 2: Matched strategy ──────────────────────────────────────────

  Widget _buildPage2(String? style) {
    return _MatchedStrategyPage(
      styleKey: style,
      onNext: () => _goToPage(2),
      onBack: () => _goToPage(0),
    );
  }

  // ── Page 3: Ready ────────────────────────────────────────────────────

  Widget _buildPage3(String? style) {
    final info = _styleMap[style];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.pagePadding),
      child: Column(
        children: [
          const SizedBox(height: AppTheme.space10),
          Text(
            '\u{2728}',
            style: const TextStyle(fontSize: 56),
          ),
          const SizedBox(height: AppTheme.space6),
          Text(
            '准备就绪！',
            style: AppTextStyles.h1.copyWith(
              color: StockColors.textPrimary,
              fontFamily: AppTheme.textFont,
            ),
          ),
          const SizedBox(height: AppTheme.space4),
          Text(
            '欢迎来到股势 TrendStock',
            style: TextStyle(
              fontSize: 15,
              color: StockColors.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: AppTheme.space8),
          if (info != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppTheme.space5),
              decoration: BoxDecoration(
                color: StockColors.brandLight,
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                border: Border.all(color: StockColors.borderLight),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${info.emoji} ${info.strategyName}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: StockColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    info.description,
                    style: TextStyle(
                      fontSize: 13,
                      color: StockColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _onFinish,
              style: ElevatedButton.styleFrom(
                backgroundColor: StockColors.brand,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                ),
              ),
              child: const Text(
                '开始使用',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(height: AppTheme.space6),
        ],
      ),
    );
  }
}

// ── Style selection card ────────────────────────────────────────────────

class _StyleCard extends StatelessWidget {
  final _StyleInfo info;
  final String styleKey;
  final bool isSelected;
  final VoidCallback onTap;

  const _StyleCard({
    required this.info,
    required this.styleKey,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.space3),
      child: Material(
        color: isSelected ? StockColors.brandLight : StockColors.bgCard,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          onTap: onTap,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppTheme.space4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              border: Border.all(
                color: isSelected ? StockColors.brand : StockColors.border,
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                Text(info.emoji, style: const TextStyle(fontSize: 32)),
                const SizedBox(width: AppTheme.space4),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        info.title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? StockColors.brand : StockColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        info.subtitle,
                        style: TextStyle(
                          fontSize: 13,
                          color: StockColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  Icon(Icons.check_circle, color: StockColors.brand, size: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Page 2 widget with loading animation ────────────────────────────────

class _MatchedStrategyPage extends StatefulWidget {
  final String? styleKey;
  final VoidCallback onNext;
  final VoidCallback onBack;

  const _MatchedStrategyPage({
    required this.styleKey,
    required this.onNext,
    required this.onBack,
  });

  @override
  State<_MatchedStrategyPage> createState() => _MatchedStrategyPageState();
}

class _MatchedStrategyPageState extends State<_MatchedStrategyPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  bool _showButton = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _controller.forward().then((_) {
      if (mounted) setState(() => _showButton = true);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final info = _styleMap[widget.styleKey];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.pagePadding),
      child: Column(
        children: [
          const SizedBox(height: AppTheme.space10),
          Text(
            '\u{1F3AF}',
            style: const TextStyle(fontSize: 56),
          ),
          const SizedBox(height: AppTheme.space6),
          Text(
            '已为你匹配策略',
            style: AppTextStyles.h1.copyWith(
              color: StockColors.textPrimary,
              fontFamily: AppTheme.textFont,
            ),
          ),
          const SizedBox(height: AppTheme.space8),
          FadeTransition(
            opacity: _fadeAnimation,
            child: info != null
                ? Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppTheme.space6),
                    decoration: BoxDecoration(
                      color: StockColors.bgCard,
                      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                      border: Border.all(color: StockColors.border),
                      boxShadow: [
                        BoxShadow(
                          color: StockColors.shadowMd,
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Text(
                          info.emoji,
                          style: const TextStyle(fontSize: 40),
                        ),
                        const SizedBox(height: AppTheme.space3),
                        Text(
                          info.strategyName,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: StockColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: AppTheme.space2),
                        Text(
                          info.description,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: StockColors.textSecondary,
                            height: 1.6,
                          ),
                        ),
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          const Spacer(),
          AnimatedOpacity(
            opacity: _showButton ? 1.0 : 0.0,
            duration: AppTheme.normalDuration,
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: widget.styleKey != null ? widget.onNext : widget.onBack,
                style: ElevatedButton.styleFrom(
                  backgroundColor: StockColors.brand,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  ),
                ),
                child: Text(
                  widget.styleKey != null ? '下一步' : '返回选择',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppTheme.space6),
        ],
      ),
    );
  }
}
