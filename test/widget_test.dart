import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/native.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
import 'package:stockpilot/features/dashboard/presentation/dashboard_provider.dart';
import 'package:stockpilot/features/watchlist/data/watchlist_service.dart';
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

  @override
  Future<List<DailyKline>> fetchStockKline(
    String stockCode, {
    String market = 'SH',
    int days = 120,
  }) async => [];
}

List<Override> testOverrides() {
  return [
    stockApiServiceProvider.overrideWithValue(FakeStockApiService()),
    appDatabaseProvider.overrideWith((ref) {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      ref.onDispose(db.close);
      return db;
    }),
    // Prevent the merged overview header (auto-loading dashboardProvider)
    // from triggering real strategy/watchlist loads during app smoke tests.
    dashboardProvider.overrideWith((ref) {
      final db = ref.read(appDatabaseProvider);
      return DashboardNotifier(
        StrategyService(db: db),
        WatchlistService(db: db, seedDefaults: false),
        autoLoad: false,
      );
    }),
  ];
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({'onboarding_completed': true});
  });
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

    expect(find.text('数据积累中'), findsWidgets);
    expect(find.textContaining('当前还在积累样本'), findsOneWidget);
    expect(find.textContaining('满 5 个交易日后再看命中率、极限涨跌和平均差'), findsOneWidget);
  });

  testWidgets('recommendation flat list shows items and filter tabs', (
    WidgetTester tester,
  ) async {
    final now = DateTime(2026, 5, 18);
    final strategy = Strategy(
      id: 'strategy-1',
      name: '波段低位修复',
      description: '测试策略',
      createdAt: now,
      updatedAt: now,
      stats: const StrategyStats(
        totalRecommendations: 50,
        hitRate: 0.7,
        maxGain: 30.0,
        maxLoss: -5.0,
        healthScore: 7.0,
        tradingDaysRun: 30,
      ),
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
              isBandLow: true,
              score: StockScore(
                score: 8,
                maScore: 8,
                bollScore: 8,
                volScore: 8,
                trendScore: 8,
                isBandLow: true,
                reason: '测试评分',
              ),
            ),
            DailyRecommendation(
              code: '600519',
              name: '贵州茅台',
              market: 'SH',
              category: 'mid_term',
              closePrice: 1680.0,
              changePct: -0.5,
              score: StockScore(
                score: 5,
                maScore: 5,
                bollScore: 5,
                volScore: 5,
                trendScore: 5,
                isBandLow: false,
                reason: '中性',
              ),
            ),
          ],
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...testOverrides(),
          watchlistServiceProvider.overrideWith((ref) {
            final db = ref.read(appDatabaseProvider);
            return WatchlistService(db: db, seedDefaults: false);
          }),
          strategyRecommendationProvider.overrideWith((ref) {
            return _FakeStrategyRecommendationNotifier(state);
          }),
          dashboardProvider.overrideWith((ref) {
            return _FakeDashboardNotifier();
          }),
        ],
        child: const MaterialApp(home: RecommendationTab()),
      ),
    );

    // Multiple pumps to let async microtasks and Riverpod settle
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));

    // Both stocks appear in "全部" view
    expect(find.text('双环传动'), findsOneWidget);
    expect(find.text('贵州茅台'), findsOneWidget);

    // Filter tabs exist. Note: "波段低位" may also appear as a band-low tag
    // on the matched item, so we assert at least one match for the chip.
    expect(find.text('全部'), findsWidgets);
    expect(find.text('波段低位'), findsAtLeastNWidgets(1));

    // Switch to 波段低位 filter — only 双环传动 should show.
    // Tap the filter chip specifically (the band-low tag on the item shares
    // the same label text, so scope the finder to the GestureDetector chip).
    await tester.tap(
      find.ancestor(
        of: find.text('波段低位'),
        matching: find.byType(GestureDetector),
      ).first,
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('双环传动'), findsOneWidget);
    expect(find.text('贵州茅台'), findsNothing);

    // Switch back to 全部
    await tester.tap(find.text('全部').first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('双环传动'), findsOneWidget);
    expect(find.text('贵州茅台'), findsOneWidget);
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
  Future<void> loadRecommendations() async {
    // No-op in tests; state is set directly in constructor
  }

  @override
  Future<void> refresh() async {}

  @override
  void dispose() {
    _db.close();
    super.dispose();
  }
}

class _FakeDashboardNotifier extends DashboardNotifier {
  _FakeDashboardNotifier()
      : super(
          StrategyService(db: AppDatabase.forTesting(NativeDatabase.memory())),
          WatchlistService(
            db: AppDatabase.forTesting(NativeDatabase.memory()),
            seedDefaults: false,
          ),
          autoLoad: false,
        );
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
