import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/native.dart';
import 'package:stockpilot/app.dart';
import 'package:stockpilot/features/strategy/data/database.dart';
import 'package:stockpilot/features/stock/data/stock_api_service.dart';
import 'package:stockpilot/features/stock/domain/stock_models.dart';
import 'package:stockpilot/shared/providers.dart';

class FakeStockApiService extends StockApiService {
  @override
  Future<List<StockQuote>> fetchAllMarketQuotes() async => [];
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
    await tester.pumpAndSettle(const Duration(seconds: 5));
    // Verify the app starts and shows the recommendation tab
    expect(find.text('推荐'), findsWidgets);
  });
}
