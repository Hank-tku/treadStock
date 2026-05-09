# Code Review Report v1
**Conclusion: FAIL**
Review Date: 2026-04-10 | Reviewer: Code Reviewer (Paranoid Engineer)

---

## Change Scope

Flutter client: 27 Dart files across `lib/`
- Core theme/constants: 4 files
- Features (analysis, recommendation, stock, watchlist): 12 files
- Shared widgets/utils/providers: 11 files

## Verification Execution Record

| Check | Result | Details |
|-------|--------|---------|
| Flutter Analyze | PASS | 7 issues, all `info` level (no errors/warnings) |
| Dart Analyze | PASS | Same 7 `info` issues |
| Hardcoded Secrets (S01) | PASS | No API_KEY/SECRET/PASSWORD in source code |
| Non-HTTPS URLs (S02) | PASS | All external URLs use HTTPS; no `http://` found |
| Debug Print Statements (S03) | PASS | No `print()` or `debugPrint()` in source |
| Color Token Usage | PASS | All colors reference `StockColors` constants; no raw hex in widgets |
| Disclaimer (S05) | PASS | `AppConstants.disclaimer` present; `DisclaimerLabel` used on all 3 pages |
| Traceability Matrix Must Coverage | PASS | 14/14 Must scenarios marked "already implemented" |
| Design File Existence | PASS | `design/` has 3 page HTML files + index.html |

---

## FAIL Issues (Blocking)

### F-S01: AndroidManifest Missing `usesCleartextTraffic=false` (Security Baseline S02)

**Severity**: HIGH
**Location**: `/Users/henry/code/stock/android/app/src/main/AndroidManifest.xml`
**Problem**: The `<application>` tag does not include `android:usesCleartextTraffic="false"`. The security-baseline.md explicitly requires this. While no HTTP URLs are currently used, this is a defense-in-depth requirement. Without it, a future developer could accidentally add an `http://` endpoint without the OS blocking it.
**Evidence**: `grep usesCleartextTraffic android/app/src/main/AndroidManifest.xml` returns nothing.
**Fix**: Add `android:usesCleartextTraffic="false"` to the `<application>` element.

---

### F-S02: First-Launch Risk Disclaimer Dialog Missing (Security Baseline S04)

**Severity**: HIGH
**Location**: `lib/main.dart`, `lib/app.dart`
**Problem**: Security-baseline.md section 5 ("Compliance Requirements") mandates a first-launch risk disclaimer dialog that users must acknowledge before using the app. The dialog content is explicitly specified (investment risk warning with "I have read and understood" button). The current implementation only shows a static `DisclaimerLabel` widget at the bottom of pages -- this is NOT an acknowledgment dialog and does not gate app usage.
**Evidence**: No dialog/warning code in `main.dart` or `app.dart`. `SharedPreferences` is a dependency but not used to track first-launch state.
**Fix**: Implement a first-launch dialog in `_StockPilotAppState.initState()` that checks `SharedPreferences` for a `risk_disclaimer_accepted` flag. If not accepted, show a non-dismissible dialog with the required text. Only proceed after user taps "I have read and understood".

---

### F-S03: WatchlistService Uses In-Memory Storage -- All Data Lost on App Restart (Critical Functional Gap)

**Severity**: CRITICAL
**Location**: `/Users/henry/code/stock/lib/features/watchlist/data/watchlist_service.dart` (line 7)
**Problem**: The watchlist service uses a plain `List<WatchlistItem> _items = []` in memory. Every app restart destroys the user's entire watchlist. The ADR explicitly states data persistence via SQLite (drift), and `drift` + `sqlite3_flutter_libs` are listed as dependencies in `pubspec.yaml`. The traceability matrix lists F002 (watchlist) as "already implemented", but the core persistence layer is completely absent.
**Evidence**: `WatchlistService` class -- line 7: `final List<WatchlistItem> _items = [];` with no SQLite/drift integration.
**Fix**: Replace in-memory storage with drift database implementation. The ADR Step 4 already provides the complete Drift table schema (`WatchlistItems`). At minimum, a `SharedPreferences`-based persistence or `sqflite` direct usage would be acceptable for v1, but the current state means F002 is functionally broken.

---

### F-S04: DailyKline.preClose Uses Broken Heuristic Instead of Actual Previous Close

**Severity**: HIGH
**Location**: `/Users/henry/code/stock/lib/features/stock/domain/stock_models.dart` (lines 113-116)
**Problem**: The `preClose` getter uses an approximation formula: `open * (1 - (close - open) / (open + close) * 0.5)`. This is mathematically nonsensical and will produce incorrect values. The East Money K-line API returns data in the format `date,open,close,high,low,volume,amount` which does NOT include the previous close. However, the real-time quote API (`fetchAllMarketQuotes`) DOES return `f18` (previous close, `昨收价`). The `changePct` field on `DailyKline` depends on `preClose`, so all downstream calculations (trend score, downside alert, etc.) that rely on daily change percentages will be wrong.
**Evidence**:
```dart
double get preClose {
    return open * (1 - (close - open) / (open + close) * 0.5);
}
```
This formula yields incorrect values. For example: open=44.80, close=45.20 gives preClose=44.80*(1 - 0.4/90*0.5) = 44.80*0.9978 = 44.70, which is fabricated.
**Fix**: Either (a) fetch the actual previous close from the real-time quote API and merge it into K-line data, or (b) compute `preClose` from the previous day's K-line entry (`klines[i-1].close` for `klines[i]`), or (c) store it as an explicit field parsed from a data source that provides it.

---

### F-S05: Custom JSON Parser Reimplements dart:convert Without Justification

**Severity**: MEDIUM
**Location**: `/Users/henry/code/stock/lib/features/stock/data/stock_api_service.dart` (lines 194-306)
**Problem**: The `_SimpleJsonParser` / `_JsonDecoder` classes are a hand-written recursive descent JSON parser spanning ~110 lines. The comment says "avoids full dart:convert dependency" but `dart:convert` is part of the Dart SDK and is always available -- it cannot be "avoided". This custom parser has no error handling for edge cases (empty strings, nested objects beyond depth 2, unicode escapes) and introduces maintenance burden and potential correctness bugs.
**Evidence**: The code already uses `dart:convert` implicitly through Dio's response parsing. The custom parser is only used for JSONP wrapping in `fetchStockNews`.
**Fix**: Replace the entire `_SimpleJsonParser` / `_JsonDecoder` / `_JsonDecoder` with:
```dart
import 'dart:convert';
// For JSONP: extract JSON string, then:
data = json.decode(jsonPart) as Map<String, dynamic>;
```
This is 1 line instead of 110, battle-tested, and handles all edge cases.

---

### F-S06: N+1 API Calls in RecommendationProvider -- Sequential K-line Fetching for 50 Stocks

**Severity**: HIGH (Performance)
**Location**: `/Users/henry/code/stock/lib/features/recommendation/presentation/recommendation_provider.dart` (lines 73-97)
**Problem**: `loadRecommendations()` takes the top 50 stocks from the market quote response and sequentially fetches K-line data for each one in a for-loop with `await`. Each HTTP call has a 10-second timeout. In the worst case (network latency ~200ms per call), this takes 50 * 200ms = 10 seconds. If some calls timeout, it could take up to 50 * 10s = 500 seconds. There is no cancellation mechanism, no parallel fetching, and no timeout for the entire operation.
**Evidence**:
```dart
for (final quote in topStocks) {
    try {
      final klines = await _apiService.fetchStockKline(quote.code, market: quote.market);
      // ...
    } catch (_) { }
}
```
**Fix**: Use `Future.wait()` with a concurrency limit (e.g., 5 parallel requests) or reduce the number of stocks scored. Consider caching K-line data so subsequent loads are faster.

---

### F-S07: WatchlistNotifier Uses `ref.watch()` Instead of `ref.read()` for Service Providers

**Severity**: MEDIUM (State Management)
**Location**: `/Users/henry/code/stock/lib/features/watchlist/presentation/watchlist_provider.dart` (lines 165-168)
**Problem**: The `watchlistProvider` uses `ref.watch()` for `watchlistServiceProvider`, `stockApiServiceProvider`, and `analysisEngineProvider`. Since these are plain `Provider` (not `StateNotifierProvider`), using `ref.watch()` means the `WatchlistNotifier` will be recreated every time any of these providers change. Since they are currently static singletons, this won't trigger in practice, but it is incorrect usage. More importantly, `ref.watch()` inside a `StateNotifierProvider`'s callback can cause the notifier to rebuild unexpectedly if any dependency changes.
**Evidence**:
```dart
final watchlistProvider = StateNotifierProvider<WatchlistNotifier, WatchlistState>((ref) {
  final watchlistService = ref.watch(watchlistServiceProvider);  // should be ref.read
  final apiService = ref.watch(stockApiServiceProvider);          // should be ref.read
  final analysisEngine = ref.watch(analysisEngineProvider);      // should be ref.read
  return WatchlistNotifier(watchlistService, apiService, analysisEngine);
});
```
**Fix**: Change `ref.watch()` to `ref.read()` for all three service providers inside `StateNotifierProvider` factories.

---

### F-S08: StockDetailPage Alert Toggle Not Persisted to WatchlistService

**Severity**: MEDIUM (Functional)
**Location**: `/Users/henry/code/stock/lib/features/stock/presentation/stock_detail_page.dart` (lines 178-195)
**Problem**: The alert toggle switch on the detail page only updates local state (`setState(() => _alertEnabled = value)`) and shows a Toast. It does not call `WatchlistService.toggleAlert()` to persist the setting. When the user navigates away and returns, the toggle will revert to its default (false). The `WatchlistNotifier` has a `toggleAlert()` method that is never called from the detail page.
**Evidence**: Line 181: `setState(() => _alertEnabled = value);` -- no service call.
**Fix**: Call `ref.read(watchlistProvider.notifier).toggleAlert()` or `ref.read(watchlistServiceProvider).toggleAlert()` from the detail page when the switch is toggled.

---

### F-S09: BuildContext Used Across Async Gaps Without Proper mounted Check (4 occurrences)

**Severity**: MEDIUM
**Location**: `/Users/henry/code/stock/lib/features/watchlist/presentation/watchlist_tab.dart` (lines 244, 248, 343, 366)
**Problem**: The Dart analyzer reports `use_build_context_synchronously` warnings. The code checks `if (mounted)` but uses `mounted` from `State`, while the `BuildContext` used in `ToastHelper.showSuccess(context, ...)` comes from the enclosing `build()` method's context parameter, not from the State's context. Per Dart's lint rules, this is a potential memory leak or exception if the widget is disposed during the async gap.
**Evidence**: Flutter analyze output shows 4 `use_build_context_synchronously` warnings at the specified lines.
**Fix**: Either (a) capture the BuildContext before the async gap and check `context.mounted` (Dart 3.7+), or (b) use `ref.read()` within ConsumerState to access the provider instead of using BuildContext directly, or (c) use a local variable assignment pattern that the analyzer accepts.

---

### F-S10: CacheBanner Text Color Does Not Match Design Spec

**Severity**: LOW (Design Compliance)
**Location**: `/Users/henry/code/stock/lib/shared/widgets/cache_banner.dart` (line 37)
**Problem**: The CacheBanner message text uses `color: StockColors.gray800` (#333333), but the design HTML spec (`design/index.html` line 48) defines `.cache-banner` text color as `#8C6B00`. The design-spec.md does not specify a separate token for this. While the overall design system is internally consistent with StockColors, the HTML design mockup uses a different color for cache banner text.
**Evidence**: Design HTML has `color: #8C6B00` for `.cache-banner`; implementation uses `StockColors.gray800` (#333333).
**Fix**: Either update the design HTML to match the implementation or add a `StockColors.cacheBannerText` token. Given that #8C6B00 is more semantically meaningful (warning text in a warning banner), consider matching the design.

---

### F-S11: iOS Info.plist Allows Landscape Orientation Contradicting PRD

**Severity**: LOW
**Location**: `/Users/henry/code/stock/ios/Runner/Info.plist` (lines 57-68)
**Problem**: The Info.plist lists both `UIInterfaceOrientationLandscapeLeft` and `UIInterfaceOrientationLandscapeRight` as supported orientations. The PRD and design-spec both state landscape is "Out of Scope" and the app locks to portrait in code (`SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp])`). However, the plist still declares landscape support, which could cause issues with iOS multitasking or App Store review.
**Evidence**: Lines 59-60: `<string>UIInterfaceOrientationLandscapeLeft</string>` and `<string>UIInterfaceOrientationLandscapeRight</string>`.
**Fix**: Remove landscape orientations from `UISupportedInterfaceOrientations` in Info.plist. Keep only `UIInterfaceOrientationPortrait`.

---

## WARNINGS (Not Blocking, But Should Address)

### W-01: Empty Catch Blocks Throughout Codebase (12 occurrences)

12 `catch (_)` or `catch (e)` blocks either silently swallow errors or have only minimal handling. While some are intentional (skip malformed data), critical paths like `stock_detail_page.dart:75` (entire score calculation failure) silently do nothing, leaving the user with no feedback.

Key locations:
- `stock_api_service.dart`: 4 catch blocks return empty results (acceptable for API resilience)
- `recommendation_provider.dart`: 2 catch blocks (one skips stocks, one sets error state -- acceptable)
- `watchlist_provider.dart`: 1 completely silent catch at line 148 (`_fetchStockData`)
- `stock_detail_page.dart`: 2 catch blocks (lines 75 and 95) -- the first one is concerning
- `watchlist_service.dart`: 1 catch block at line 95

**Recommendation**: At minimum, add `debugPrint` or structured logging for the silent catches. The `stock_detail_page.dart:75` catch should set an error flag so the UI can show a degraded state.

### W-02: Zero Unit Tests for Business Logic

Only 1 widget test exists (`test/widget_test.dart`) that just verifies the app renders. There are zero tests for:
- `AnalysisEngine` (MA, Bollinger, scoring algorithms)
- `StockQuote.fromJson` (data parsing)
- `DailyKline.fromEastMoney` (data parsing)
- `WatchlistService` (CRUD operations)
- Formatters (formatting edge cases)

The analysis engine contains non-trivial mathematical logic (MA, Bollinger, scoring) that should have unit tests to prevent regressions.

### W-03: ScoreBadge "Loading" State Never Used

`ScoreBadgeLoading` widget is defined but never referenced anywhere in the codebase. The detail page shows skeleton placeholders instead of this widget during score calculation. This is dead code.

### W-04: StockDetailRouteData Class Is Dead Code

`StockDetailRouteData` in `stock_detail_route.dart` is never instantiated or referenced. The routing in `app.dart` uses `state.extra as Map<String, dynamic>` instead.

### W-05: RecommendationProvider Fetches Only First 50 Stocks

Line 71: `final topStocks = quotes.take(50).toList();`. The market snapshot returns ~5000 stocks sorted by change percentage. Taking only the first 50 means the recommendation list is biased toward the top gainers of the day, not the full market analysis that the PRD describes. This could miss stocks at band lows that have small positive or negative changes.

### W-06: `StockQuote._detectMarket` Misses SZ Stocks Starting with '0'

The `_detectMarket` method checks `code.startsWith('6') || code.startsWith('9')` for SH, and defaults everything else to SZ. This works for current A-stock codes (6xxxxx=SH, 0xxxxx=SZ, 3xxxxx=SZ/ChiNext). However, Beijing Stock Exchange codes (8xxxxx, 4xxxxx) would be misclassified as SZ. Consider adding explicit BSE handling.

### W-07: SearchBar Clear Button Does Not Trigger Rebuild

In `watchlist_tab.dart`, the clear button visibility is controlled by `_searchController.text.isNotEmpty`, but `TextField`'s `onChanged` only fires when the user types, not when the controller is programmatically cleared. The clear button (`suffixIcon`) may not visually disappear after tapping X because the widget doesn't rebuild to reflect the empty text state. This requires a `setState()` wrapper around `_clearSearch()`.

---

## Pixel-Level Design Verification

### Page 1: Recommendation Tab

| Component | CSS Property | Design Value | Implementation Value | Delta | Verdict |
|-----------|-------------|-------------|---------------------|-------|---------|
| Page title | font-size | 20px | `AppTextStyles.h1` fontSize: 20 | 0 | PASS |
| Page title | font-weight | 600 | FontWeight.w600 | 0 | PASS |
| Page date | font-size | 11px | `AppTextStyles.caption` fontSize: 11 | 0 | PASS |
| Page date | color | #8C8C8C | StockColors.textTertiary (#8C8C8C) | 0 | PASS |
| Subtitle | font-size | 13px | `AppTextStyles.body` fontSize: 13 | 0 | PASS |
| Group name | font-size | 15px | `AppTextStyles.h3` fontSize: 15 | 0 | PASS |
| Stock item | padding | 12px 16px | listItemPaddingV:12, listItemPaddingH:16 | 0 | PASS |
| Stock item | border-bottom | 1px solid #EEEEEE | BorderSide(color: StockColors.border #EEEEEE) | 0 | PASS |
| Stock name | font-size | 15px | bodyLg fontSize: 15 | 0 | PASS |
| Stock code | font-size | 11px | caption fontSize: 11 | 0 | PASS |
| Stock price | font-size | 16px | number fontSize: 16 | 0 | PASS |
| Score badge | size | 28x20 | Container(width:28, height:20) | 0 | PASS |
| Score badge | border-radius | 4px | BorderRadius.circular(4) | 0 | PASS |
| Band low tag | background | rgba(230,147,33,0.12) | StockColors.bandLowBg (0x1FE69321 = ~12%) | 0 | PASS |
| Band low tag | text color | #E69321 | StockColors.bandLow #E69321 | 0 | PASS |
| Tab bar | height | 48px | bottomTabHeight: 48 (implicit in BottomNavigationBar) | 0 | PASS |
| Disclaimer | font-size | 11px | caption fontSize: 11 | 0 | PASS |
| Disclaimer | color | #BDBDBD | StockColors.gray400 #BDBDBD | 0 | PASS |

### Page 2: Watchlist Tab

| Component | CSS Property | Design Value | Implementation Value | Delta | Verdict |
|-----------|-------------|-------------|---------------------|-------|---------|
| Search bar | height | 40px | searchBarHeight: 40 | 0 | PASS |
| Search bar | border-radius | 8px | radiusMd: 8 | 0 | PASS |
| Search bar | border | 1px solid #E0E0E0 | StockColors.borderFocus #E0E0E0 | 0 | PASS |
| Search bar | focus border | #1A6AFF | StockColors.borderActive #1A6AFF | 0 | PASS |
| Add button | color | #1A6AFF | StockColors.brand #1A6AFF | 0 | PASS |
| Already added | color | #8C8C8C | StockColors.gray400 #BDBDBD | N/A | WARN (BDBDBD vs 8C8C8C) |
| Stock item | padding | 12px 16px | Same as recommendation | 0 | PASS |

### Page 3: Stock Detail

| Component | CSS Property | Design Value | Implementation Value | Delta | Verdict |
|-----------|-------------|-------------|---------------------|-------|---------|
| Current price | font-size | 32px | displayLg fontSize: 32 | 0 | PASS |
| Current price | font-weight | 700 | FontWeight.w700 | 0 | PASS |
| Price change | font-size | 24px | numberLg fontSize: 24 | 0 | PASS |
| Indicator card | background | #F7F8FA | StockColors.bgSecondary #F7F8FA | 0 | PASS |
| Indicator card | border-radius | 8px | radiusMd: 8 | 0 | PASS |
| News title | font-size | 15px | bodyLg fontSize: 15 | 0 | PASS |
| News source | font-size | 11px | caption fontSize: 11 | 0 | PASS |

### Color System Verification

All colors in widgets reference `StockColors.*` constants. No hardcoded hex values in widget code. The color token system in `app_colors.dart` matches the design-spec.md Color Tokens section.

**Color mapping verification** (design-spec vs implementation):

| Token | Design Spec | Implementation | Match |
|-------|-----------|---------------|-------|
| --color-brand | #1A6AFF | StockColors.brand #1A6AFF | PASS |
| --color-price-up | #E6432D | StockColors.up #E6432D | PASS |
| --color-price-down | #1DB954 | StockColors.down #1DB954 | PASS |
| --color-score-high | #E6432D | StockColors.scoreHigh #E6432D | PASS |
| --color-score-mid | #D4A017 | StockColors.scoreMid #D4A017 | PASS |
| --color-score-low | #1DB954 | StockColors.scoreLow #1DB954 | PASS |
| --color-band-low | #E69321 | StockColors.bandLow #E69321 | PASS |
| --color-bg-primary | #FFFFFF | StockColors.bgPrimary #FFFFFF | PASS |
| --color-bg-secondary | #F7F8FA | StockColors.bgSecondary #F7F8FA | PASS |
| --color-bg-warning | #FFF8E1 | StockColors.bgWarning #FFF8E1 | PASS |
| --color-text-primary | #1A1A1A | StockColors.textPrimary #1A1A1A | PASS |
| --color-text-secondary | #6B6B6B | StockColors.textSecondary #6B6B6B | PASS |
| --color-text-tertiary | #8C8C8C | StockColors.textTertiary #8C8C8C | PASS |
| --color-border | #EEEEEE | StockColors.border #EEEEEE | PASS |
| --color-toast-bg | #333333 | StockColors.toastBg #333333 | PASS |
| --color-danger | #E6432D | StockColors.danger #E6432D | PASS |
| --color-pin | #1A6AFF | StockColors.pin #1A6AFF | PASS |

**Design pixel verification: 0 FAIL items, 1 WARN item (already-added button color).**

---

## Highlights

1. **Clean architecture separation**: Feature-based folder structure with clear data/domain/presentation layers. Each feature is self-contained.
2. **Consistent design system**: All colors, typography, and spacing are centralized in `StockColors`, `AppTextStyles`, and `AppTheme` with no raw hex values in widget code.
3. **Comprehensive state management**: Riverpod StateNotifier pattern is correctly used for both recommendation and watchlist features with proper loading/error/empty states.
4. **Complete shared widget library**: All 9 components from the traceability matrix (StockListItem, ScoreBadge, SkeletonLoader, EmptyState, CacheBanner, ToastHelper, BandLowTag, DisclaimerLabel) are implemented and match their design specs.
5. **Search debounce**: 300ms debounce on search input matches the interaction-spec requirement exactly.
6. **Analysis engine**: The MA, Bollinger, and scoring algorithms follow the ADR-SP-002 formula precisely with correct weights (0.30, 0.30, 0.20, 0.20) and band-low detection logic.
7. **Security posture**: No hardcoded secrets, all HTTPS, no debug logging, no sensitive data in URL parameters.

---

## Summary of Required Fixes

| Priority | ID | Issue | Effort |
|----------|-----|-------|--------|
| P0 | F-S03 | WatchlistService in-memory -- all data lost on restart | 4-6h (drift DB integration) |
| P0 | F-S04 | DailyKline.preClose broken heuristic | 1-2h (fetch from quote API or compute from adjacent K-line) |
| P0 | F-S02 | First-launch risk disclaimer dialog missing | 1-2h |
| P1 | F-S06 | N+1 sequential API calls for recommendations | 2-3h (parallel fetching) |
| P1 | F-S01 | AndroidManifest missing usesCleartextTraffic=false | 5min |
| P1 | F-S05 | Custom JSON parser (replace with dart:convert) | 30min |
| P1 | F-S08 | Alert toggle not persisted | 30min |
| P2 | F-S07 | ref.watch -> ref.read in StateNotifierProvider | 5min |
| P2 | F-S09 | BuildContext async gap warnings | 30min |
| P3 | F-S10 | CacheBanner text color mismatch | 5min |
| P3 | F-S11 | iOS Info.plist landscape orientation | 5min |
