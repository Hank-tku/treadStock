import 'package:flutter/material.dart';
import 'package:stockpilot/core/theme/app_semantic_colors.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/disclaimer_label.dart';

class StrategyKnowledgePage extends StatelessWidget {
  const StrategyKnowledgePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.sc.bgPrimary,
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_ios, size: 20),
        ),
        title: const Text('策略知识'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppTheme.pagePadding),
        children: [
          const _KnowledgeCard(
            title: '先从一个目标开始',
            body: '不要先纠结参数。新手可以先选“低位修复”“趋势延续”或“少一点噪声”，让 App 生成一条可观察、可复盘的策略。',
          ),
          const _LearningStepCard(),
          _CreateGoalCard(onTap: () => context.push('/strategy/new')),
          const _ComparisonCard(),
          const _KnowledgeCard(
            title: '策略是什么',
            body: '策略是一组可重复执行的观察规则。当前版本用 MA、布林带、量价和趋势四类技术指标生成 1-10 分观察分。',
          ),
          const _KnowledgeCard(
            title: '评分权重',
            body: '四个权重合计为 1.0。提高某一项权重，会让该指标对最终观察分的影响更大，例如低位修复策略通常会提高布林带权重。',
          ),
          const _KnowledgeCard(
            title: 'MA 均线',
            body: 'MA 用来观察价格相对短期和长期均线的位置。短期周期越小，越敏感；长期周期越大，越稳定。',
          ),
          const _KnowledgeCard(
            title: '布林带',
            body: '布林带用于观察价格是否接近波动区间的上沿或下沿。接近下沿不代表一定反转，只表示进入低位观察区。',
          ),
          const _KnowledgeCard(
            title: '量价与趋势',
            body: '量价关注成交量和价格变化是否配合，趋势关注近期涨跌节奏。两者用于补充均线和布林带的静态判断。',
          ),
          const _KnowledgeCard(
            title: '推荐阈值',
            body: '推荐阈值是进入观察列表的最低分。阈值越高，结果越少但更严格；阈值越低，结果更多但噪声也可能增加。',
          ),
          const _KnowledgeCard(
            title: '最佳策略',
            body: '关注列表会对同一只股票运行所有启用策略，并展示得分最高的策略，帮助你理解这只股票当前更匹配哪类观察逻辑。',
          ),
          const _KnowledgeCard(
            title: '复盘指标',
            body:
                '复盘使用已回填的 5 日表现记录，关注命中率、平均差、极限跌幅、趋势和推荐频率。样本不足时先看观察记录，不要急着判断策略好坏。',
          ),
          const _KnowledgeCard(
            title: '什么是失效',
            body:
                '策略失效不是某一只股票下跌，而是连续多次推荐后的表现变差、极限跌幅扩大，或推荐数量长期异常。遇到这种情况先复盘，再考虑调参或停用。',
          ),
          const DisclaimerLabel(),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

class _CreateGoalCard extends StatelessWidget {
  final VoidCallback onTap;

  const _CreateGoalCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.sc.bgSecondary,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: context.sc.border),
      ),
      child: Row(
        children: [
          const Icon(Icons.add_circle_outline, color: StockColors.brand),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('从新手目标创建策略', style: AppTextStyles.h3),
                const SizedBox(height: 2),
                Text(
                  '选择一个观察目标，生成策略后回到推荐页查看今天是否有线索。',
                  style: AppTextStyles.caption.copyWith(
                    color: context.sc.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          TextButton(onPressed: onTap, child: const Text('去创建')),
        ],
      ),
    );
  }
}

class _LearningStepCard extends StatelessWidget {
  const _LearningStepCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: StockColors.brand.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: StockColors.brand.withValues(alpha: 0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text('7 天学习路径', style: AppTextStyles.h3),
          SizedBox(height: 8),
          _StepLine(index: '1', text: '第 1 天：选择一条新手策略，只观察不改参数。'),
          _StepLine(index: '2', text: '第 2-5 天：每天看推荐理由，收藏 2-3 只你能看懂的标的。'),
          _StepLine(index: '3', text: '第 6 天：比较收藏标的的评分变化和价格变化。'),
          _StepLine(index: '4', text: '第 7 天：做一次复盘，再决定提高或降低推荐阈值。'),
        ],
      ),
    );
  }
}

class _StepLine extends StatelessWidget {
  final String index;
  final String text;

  const _StepLine({required this.index, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 18,
            height: 18,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: StockColors.brand,
              shape: BoxShape.circle,
            ),
            child: Text(
              index,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.body.copyWith(
                color: context.sc.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ComparisonCard extends StatelessWidget {
  const _ComparisonCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.sc.bgSecondary,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('怎么比较策略', style: AppTextStyles.h3),
          const SizedBox(height: 8),
          Text(
            '同一只股票在不同策略下得分不同，是学习策略的入口。',
            style: AppTextStyles.body.copyWith(
              color: context.sc.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          _buildCompareRow(context, '低位修复分高', '说明它更接近低位观察区，重点看是否企稳。'),
          _buildCompareRow(context, '趋势延续分高', '说明它更符合顺势观察，重点看趋势是否保持。'),
          _buildCompareRow(context, '两个策略都低', '说明当前不适合强行观察，可以先放弃。'),
        ],
      ),
    );
  }

  static Widget _buildCompareRow(BuildContext context, String label, String body) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 88,
            child: Text(
              label,
              style: AppTextStyles.caption.copyWith(color: StockColors.brand),
            ),
          ),
          Expanded(
            child: Text(
              body,
              style: AppTextStyles.caption.copyWith(
                color: context.sc.textTertiary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _KnowledgeCard extends StatelessWidget {
  final String title;
  final String body;

  const _KnowledgeCard({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.sc.bgSecondary,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.h3),
          const SizedBox(height: 6),
          Text(
            body,
            style: AppTextStyles.body.copyWith(
              color: context.sc.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
