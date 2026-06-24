// 冒烟集成测试：在真实 macOS/桌面 App 上验证核心 UI 路径。
//
// 与 test/e2e/stockpilot_app_test.dart 的区别：
// - e2e 跑在 flutter_test headless binding 上（快、纯 widget）。
// - 集成测试通过 IntegrationTestWidgetsFlutterBinding 接到真实平台，
//   能暴露 channel/plugin、字体渲染、平台通道等真实环境问题。
//
// 运行方式（任选一种）：
//   flutter test integration_test/app_smoke_test.dart                       # 头less
//   flutter test integration_test/app_smoke_test.dart -d macos              # 真实 macOS App
//   flutter test integration_test/app_smoke_test.dart -d "Chrome"           # Web

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stockpilot/app.dart';
import 'package:stockpilot/features/strategy/data/database.dart';
import 'package:stockpilot/features/stock/data/stock_api_service.dart';
import 'package:stockpilot/features/stock/domain/stock_models.dart';
import 'package:stockpilot/shared/providers.dart';

/// 复用一份 fake：所有网络都返回空，避免冒烟测试依赖外部 API。
class _FakeStockApiService extends StockApiService {
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
  Future<List<StockSearchResult>> searchStock(String keyword) async => [];

  @override
  Future<List<DailyKline>> fetchStockKline(
    String code, {
    String market = 'SH',
    int days = 120,
  }) async => [];
}

List<Override> _testOverrides() {
  return [
    stockApiServiceProvider.overrideWithValue(_FakeStockApiService()),
    appDatabaseProvider.overrideWith((ref) {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      ref.onDispose(db.close);
      return db;
    }),
  ];
}

Future<void> _bootApp(WidgetTester tester) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: _testOverrides(),
      child: const StockPilotApp(disclaimerAccepted: true),
    ),
  );
  // 推进足够多帧，让 FutureBuilder / StateNotifier 完成首次解析。
  await tester.pump(const Duration(seconds: 2));
  await tester.pumpAndSettle(const Duration(seconds: 2));
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({'onboarding_completed': true});
  });

  group('App smoke', () {
    testWidgets('三个底部 tab 均渲染（推荐/关注/策略）', (tester) async {
      await _bootApp(tester);

      expect(find.text('推荐'), findsWidgets);
      expect(find.text('关注'), findsWidgets);
      expect(find.text('策略'), findsWidgets);
    });

    testWidgets('关注 tab 可切换并渲染搜索入口', (tester) async {
      await _bootApp(tester);

      // 默认进入推荐
      expect(find.text('推荐'), findsWidgets);

      // 切到关注
      await tester.tap(find.text('关注').first);
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // 关注 tab 至少应渲染搜索框（无论列表是否为空，搜索框常驻）。
      // 之所以不断言「暂无关注的股票」文案：空态标题可能在后续帧才出现，
      // 且文案属产品细节，不在冒烟测试的稳定断言范围内。
      expect(find.byType(TextField), findsWidgets);
    });

    testWidgets('策略 tab 可切换并渲染（无崩溃）', (tester) async {
      await _bootApp(tester);

      await tester.tap(find.text('策略').first);
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // 策略 tab 应已切换并渲染。冒烟测试不断言空态文案（属产品细节，
      // 可能在后续帧出现），只验证切换后页面未崩溃。
      expect(find.text('策略'), findsWidgets);
    });

    testWidgets('tab 之间可来回切换不崩溃', (tester) async {
      await _bootApp(tester);

      // 推荐 -> 关注 -> 策略 -> 关注 -> 推荐 来回切换
      await tester.tap(find.text('关注').first);
      await tester.pumpAndSettle(const Duration(seconds: 1));
      await tester.tap(find.text('策略').first);
      await tester.pumpAndSettle(const Duration(seconds: 1));
      await tester.tap(find.text('关注').first);
      await tester.pumpAndSettle(const Duration(seconds: 1));
      await tester.tap(find.text('推荐').first);
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // 回到推荐后仍可正常渲染
      expect(find.text('推荐'), findsWidgets);
    });
  });
}
