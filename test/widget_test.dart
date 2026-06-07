import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/native.dart';
import 'package:stockpilot/app.dart';
import 'package:stockpilot/features/analysis/domain/analysis_engine.dart';
import 'package:stockpilot/features/analysis/domain/analysis_models.dart';
import 'package:stockpilot/features/recommendation/presentation/recommendation_tab.dart';
import 'package:stockpilot/features/strategy/data/strategy_service.dart';
import 'package:stockpilot/features/strategy/domain/strategy_models.dart';
import 'package:stockpilot/features/strategy/domain/strategy_scoring_service.dart';
import 'package:stockpilot/features/strategy/presentation/strategy_detail_page.dart';
import 'package:stockpilot/features/strategy/presentation/strategy_provider.dart';
import 'package:stockpilot/features/strategy/data/database.dart';
import 'package:stockpilot/features/strategy/presentation/strategy_knowledge_page.dart';
import 'package:stockpilot/features/stock/data/stock_api_service.dart';
import 'package:stockpilot/features/stock/domain/stock_models.dart';
import 'package:stockpilot/shared/providers.dart';

class FakeStockApiService extends StockApiService {
  @override
  Future<List<StockQuote>> fetchAllMarketQuotes() async => [];

  @override
  Future<List<StockQuote>> fetchRecommendationCandidates({
    int limit = 50,
  }) async => [];

  @override
  Future<StockQuote?> fetchStockQuote(
    String stockCode, {
    String market = 'SH',
  }) async => null;
}

List<Override> testOverrides() {
  return [
    stockApiServiceProvider.overrideWithValue(FakeStockApiService()),
    appDatabaseProvider.overrideWith((ref) {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      ref.onDispose(db.close);
      return db;
    }),
  ];
}

void main() {
  testWidgets('StockPilot app renders without crash', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: testOverrides(),
        child: const StockPilotApp(disclaimerAccepted: true),
      ),
    );
    await tester.pump(const Duration(seconds: 3));
    // Verify the app starts and shows the recommendation tab
    expect(find.text('推荐'), findsWidgets);
  });

  testWidgets('strategy knowledge page renders core learning content', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: StrategyKnowledgePage()));
    await tester.pump(const Duration(seconds: 2));

    expect(find.text('策略知识'), findsOneWidget);
    expect(find.text('先从一个目标开始'), findsOneWidget);
    expect(find.text('7 天学习路径'), findsOneWidget);
    expect(find.text('从新手目标创建策略'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('策略是什么'),
      180,
      scrollable: find.byType(Scrollable),
    );
    expect(find.text('策略是什么'), findsOneWidget);
  });

  testWidgets('strategy detail distinguishes not found state', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          strategyDetailProvider.overrideWith((ref) {
            return _FakeStrategyDetailNotifier(
              const StrategyDetailState(
                isLoading: false,
                errorType: StrategyDetailErrorType.notFound,
              ),
            );
          }),
        ],
        child: const MaterialApp(home: StrategyDetailPage(strategyId: 'bad')),
      ),
    );
    await tester.pump();

    expect(find.text('未找到该策略'), findsOneWidget);
    expect(find.text('统计计算失败'), findsNothing);
  });

  testWidgets('strategy detail explains insufficient sample', (
    WidgetTester tester,
  ) async {
    final now = DateTime(2026, 5, 24);
    final strategy = Strategy(
      id: 'strategy-1',
      name: '样本测试策略',
      createdAt: now,
      updatedAt: now,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          strategyDetailProvider.overrideWith((ref) {
            return _FakeStrategyDetailNotifier(
              StrategyDetailState(
                strategy: strategy,
                isLoading: false,
                stats: const StrategyStats(
                  totalRecommendations: 3,
                  evaluatedCount: 0,
                ),
              ),
            );
          }),
        ],
        child: const MaterialApp(
          home: StrategyDetailPage(strategyId: 'strategy-1'),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('复盘样本不足'), findsOneWidget);
    expect(find.textContaining('当前累计推荐 3 条'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('样本不足，先看趋势'),
      180,
      scrollable: find.byType(Scrollable),
    );
    expect(find.text('样本不足，先看趋势'), findsOneWidget);
  });

  testWidgets('recommendation strategy group can collapse and expand', (
    WidgetTester tester,
  ) async {
    final now = DateTime(2026, 5, 18);
    final strategy = Strategy(
      id: 'strategy-1',
      name: '测试策略',
      description: '用于测试折叠',
      createdAt: now,
      updatedAt: now,
    );
    final state = StrategyRecommendationState(
      groups: [
        StrategyRecommendation(
          strategy: strategy,
          recommendations: const [
            DailyRecommendation(
              code: '002472',
              name: '双环传动',
              market: 'SZ',
              category: 'mid_term',
              closePrice: 12.3,
              changePct: 1.2,
              score: StockScore(
                score: 8,
                maScore: 8,
                bollScore: 8,
                volScore: 8,
                trendScore: 8,
                isBandLow: false,
                reason: '测试评分',
              ),
            ),
          ],
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          strategyRecommendationProvider.overrideWith((ref) {
            return _FakeStrategyRecommendationNotifier(state);
          }),
        ],
        child: const MaterialApp(home: RecommendationTab()),
      ),
    );
    await tester.pump();

    expect(find.text('双环传动'), findsOneWidget);

    await tester.tap(find.text('测试策略'));
    await tester.pump();
    expect(find.text('双环传动'), findsNothing);

    await tester.tap(find.text('测试策略'));
    await tester.pump();
    expect(find.text('双环传动'), findsOneWidget);
  });
}

class _FakeStrategyRecommendationNotifier
    extends StrategyRecommendationNotifier {
  _FakeStrategyRecommendationNotifier(StrategyRecommendationState state)
    : this._(state, AppDatabase.forTesting(NativeDatabase.memory()));

  _FakeStrategyRecommendationNotifier._(
    StrategyRecommendationState state,
    AppDatabase db,
  ) : _db = db,
      super(
        StrategyService(db: db),
        FakeStockApiService(),
        StrategyScoringService(AnalysisEngine()),
      ) {
    this.state = state;
  }

  final AppDatabase _db;

  @override
  Future<void> loadRecommendations() async {}

  @override
  Future<void> refresh() async {}

  @override
  void dispose() {
    _db.close();
    super.dispose();
  }
}

class _FakeStrategyDetailNotifier extends StrategyDetailNotifier {
  _FakeStrategyDetailNotifier(StrategyDetailState state)
    : this._(state, AppDatabase.forTesting(NativeDatabase.memory()));

  _FakeStrategyDetailNotifier._(StrategyDetailState state, AppDatabase db)
    : _db = db,
      super(StrategyService(db: db)) {
    this.state = state;
  }

  final AppDatabase _db;

  @override
  Future<void> loadDetail(String strategyId) async {}

  @override
  void dispose() {
    _db.close();
    super.dispose();
  }
}
