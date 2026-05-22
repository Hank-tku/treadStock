import 'package:flutter/material.dart';
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
      backgroundColor: StockColors.bgPrimary,
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_ios, size: 20),
        ),
        title: const Text('策略知识'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppTheme.pagePadding),
        children: const [
          _KnowledgeCard(
            title: '策略是什么',
            body: '策略是一组可重复执行的观察规则。当前版本用 MA、布林带、量价和趋势四类技术指标生成 1-10 分观察分。',
          ),
          _KnowledgeCard(
            title: '评分权重',
            body: '四个权重合计为 1.0。提高某一项权重，会让该指标对最终观察分的影响更大，例如低位修复策略通常会提高布林带权重。',
          ),
          _KnowledgeCard(
            title: 'MA 均线',
            body: 'MA 用来观察价格相对短期和长期均线的位置。短期周期越小，越敏感；长期周期越大，越稳定。',
          ),
          _KnowledgeCard(
            title: '布林带',
            body: '布林带用于观察价格是否接近波动区间的上沿或下沿。接近下沿不代表一定反转，只表示进入低位观察区。',
          ),
          _KnowledgeCard(
            title: '量价与趋势',
            body: '量价关注成交量和价格变化是否配合，趋势关注近期涨跌节奏。两者用于补充均线和布林带的静态判断。',
          ),
          _KnowledgeCard(
            title: '推荐阈值',
            body: '推荐阈值是进入观察列表的最低分。阈值越高，结果越少但更严格；阈值越低，结果更多但噪声也可能增加。',
          ),
          _KnowledgeCard(
            title: '最佳策略',
            body: '关注列表会对同一只股票运行所有启用策略，并展示得分最高的策略，帮助你理解这只股票当前更匹配哪类观察逻辑。',
          ),
          _KnowledgeCard(
            title: '复盘指标',
            body: '复盘使用已回填的 5 日表现记录，关注命中率、平均差、极限跌幅、趋势和推荐频率。样本不足时会明确标注数据周期。',
          ),
          DisclaimerLabel(),
          SizedBox(height: 40),
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
        color: StockColors.bgSecondary,
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
              color: StockColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
