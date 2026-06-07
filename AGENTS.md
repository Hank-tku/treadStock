# AGENTS.md

This file is the handoff guide for coding agents working in this repository.

## Project Snapshot

StockPilot / 股势 TrendStock is a Flutter app for A-share wave analysis and decision support. It is a pure client-side app: there is no owned backend, no user account system, and no cloud sync. The app fetches public market data directly from East Money APIs, calculates technical indicators locally in Dart, and persists the user's watchlist in local SQLite through Drift.

Core product surfaces:

- 推荐 tab: fetches market quotes, scores candidate stocks, and groups daily recommendations.
- 关注 tab: local watchlist CRUD, search, pinning, alerts, and per-stock refresh.
- 个股详情页: K-line based score summary, MA values, local alert toggle, and news links.

## Tech Stack

- Flutter / Dart, SDK constraint `^3.11.3`
- Riverpod with `StateNotifierProvider`
- GoRouter with a bottom `StatefulShellRoute`
- Dio for HTTP
- Drift / SQLite for local persistence
- SharedPreferences for lightweight launch state
- `flutter_local_notifications` and `workmanager` are declared for alert/background work, but much of that capability is still MVP-level or documented rather than fully wired.

## Important Files

- App entry and routing:
  - `lib/main.dart`
  - `lib/app.dart`
- Shared providers:
  - `lib/shared/providers.dart`
- External market/news data:
  - `lib/features/stock/data/stock_api_service.dart`
  - `lib/core/constants/api_constants.dart`
- Domain models:
  - `lib/features/stock/domain/stock_models.dart`
  - `lib/features/analysis/domain/analysis_models.dart`
- Technical analysis:
  - `lib/features/analysis/domain/analysis_engine.dart`
- Watchlist persistence:
  - `lib/features/watchlist/data/tables.dart`
  - `lib/features/watchlist/data/database.dart`
  - `lib/features/watchlist/data/watchlist_service.dart`
- UI:
  - `lib/features/recommendation/presentation/`
  - `lib/features/watchlist/presentation/`
  - `lib/features/stock/presentation/`
  - `lib/shared/widgets/`
- Theme and formatting:
  - `lib/core/theme/`
  - `lib/shared/utils/formatters.dart`
- Product and architecture docs:
  - `docs/prd.md`
  - `docs/api-spec.md`
  - `docs/arch-decision.md`
  - `docs/security-baseline.md`
  - `docs/test-report.md`

## Generated And Build Files

Do not manually edit generated or build output:

- `lib/features/watchlist/data/database.g.dart`
- `build/`
- `.dart_tool/` if present
- platform ephemeral/generated files under `ios/Flutter/ephemeral/` and `macos/Flutter/ephemeral/`

If Drift table definitions change, update `tables.dart` / `database.dart`, then regenerate:

```bash
dart run build_runner build --delete-conflicting-outputs
```

## Common Commands

Install dependencies:

```bash
flutter pub get
```

Static analysis:

```bash
flutter analyze
```

Run all tests:

```bash
flutter test
```

Run focused tests:

```bash
flutter test test/unit/analysis_engine_test.dart
flutter test test/unit/watchlist_service_test.dart
flutter test test/provider/recommendation_provider_test.dart
```

Run the app:

```bash
flutter run
```

Regenerate code after Drift/schema changes:

```bash
dart run build_runner build --delete-conflicting-outputs
```

## Architecture Rules

- Keep the app pure-client unless the task explicitly introduces backend work. Existing docs assume no owned server.
- Put reusable singleton dependencies in `lib/shared/providers.dart`.
- Keep business logic out of widgets when practical. Scoring belongs in `AnalysisEngine`; persistence belongs in `WatchlistService`; API parsing belongs in `StockApiService` and model factories.
- Prefer adding tests around domain/service changes before broad UI tests. The core algorithm and watchlist service already have strong test coverage.
- Preserve the current market convention: A-share red means price up, green means price down. Use `StockColors.up` and `StockColors.down`.
- Use existing theme tokens in `AppTheme`, `StockColors`, and `AppTextStyles` instead of ad hoc styling.
- User-facing text is mostly Chinese. Keep financial wording conservative and avoid language that sounds like guaranteed advice.

## Stock Product Workflow Skill

For non-trivial product, UX, strategy-learning, recommendation, QA, or finance-copy work, use the repo workflow in `docs/stock-product-workflow-skill.md`.

The workflow adapts two external agent-process ideas to this project:

- `garrytan/gstack`: product/CEO/design/engineering/QA/security/release specialist passes.
- `poz110/claude-harness`: staged delivery from idea and PRD through architecture, design, implementation, QA, security, and deployment readiness.

Default to the smallest useful mode:

- Hotfix: reproduce or trace the bug, find root cause, patch, focused test.
- Feature: product framing, UX/state design, implementation, focused tests, then broader validation if shared behavior changed.
- Product review: run product, design, engineering, QA, security, and documentation passes, then return ranked findings and implementation slices.

For ordinary-user strategy features, always distinguish:

- no enabled strategy,
- strategy exists but has no matching stocks,
- insufficient review sample,
- true loading/statistics error.

## Data And API Notes

`StockApiService` calls public East Money endpoints:

- `fetchAllMarketQuotes()` reads market snapshot data.
- `fetchStockKline()` reads daily K-line strings and converts them with `DailyKline.parseKlines`.
- `searchStock()` searches by code/name with the public East Money suggest API.
- `fetchStockNews()` parses JSONP-like news responses.

Network failures are often swallowed and converted to empty lists or fallback UI. When changing this behavior, update tests and keep offline/cache messaging in mind.

Market detection is duplicated in model factories:

- Codes starting with `6` or `9` are treated as `SH`.
- Other common A-share codes are treated as `SZ`.

## Analysis Rules

`AnalysisEngine` is pure Dart and should stay deterministic:

- MA defaults are MA20 and MA60.
- Bollinger defaults are 20 periods and 2 standard deviations.
- Score weights live in `AppConstants`: MA 30%, Bollinger 30%, volume 20%, trend 20%.
- `calculateScore` returns score `0` with reason `数据不足` when fewer than 20 K-lines are available.
- `isBandLow` should stay aligned with `calculateScore(...).isBandLow`; tests assert this.
- `checkDownsideAlert` is the source of truth for downside alert conditions.

Any scoring change should update `test/unit/analysis_engine_test.dart` and any product docs that describe scoring.

## Persistence Rules

Watchlist state is persisted in Drift and mirrored in an in-memory cache:

- Always call `WatchlistService.init()` before relying on persisted data.
- `WatchlistService.getWatchlist()` returns sorted cache data, not a DB query.
- Pinned items sort before unpinned items.
- Multiple pinned items sort by descending `sortOrder`.
- Unpinned items sort by descending `createdAt`.
- Real-time quote/score fields on `WatchlistItem` are in-memory only and are not persisted.

Use `AppDatabase.forTesting(NativeDatabase.memory())` for service tests.

## UI Rules

- `StockPilotApp` uses `MaterialApp.router`; add routes in `AppRouter`.
- The main tabs are `/recommend` and `/watchlist`; stock detail is `/stock/:code`.
- `StockDetailPage` expects route extras for `name` and `market`; provide sensible fallbacks if linking directly.
- Keep bottom-tab spacing in list views so content is not hidden behind navigation.
- Reuse shared widgets such as `StockListItem`, `ScoreBadge`, `EmptyState`, `SkeletonLoader`, `CacheBanner`, and `DisclaimerLabel`.

## Security And Compliance

This is a finance-related app. Changes must preserve these constraints:

- Do not add language that implies guaranteed returns or direct buy/sell advice.
- Keep the first-launch risk disclaimer flow intact.
- Keep disclaimer labels visible on recommendation/detail surfaces.
- Do not log API tokens, full sensitive request details, or user preference data in production.
- Do not introduce API keys into the client. If a future data source needs a secret, it requires a backend proxy.
- Use HTTPS-only external APIs.
- Do not store sensitive data in SharedPreferences.

The East Money search token is currently public and split in `ApiConstants`; do not treat that pattern as sufficient for real secrets.

## Testing Guidance

For most changes, run at least:

```bash
flutter analyze
flutter test
```

For narrow changes, focused tests are acceptable during iteration, but finish with broader coverage when touching shared code, scoring, persistence, routing, or user-visible finance wording.

Suggested mapping:

- Scoring or summaries: `test/unit/analysis_engine_test.dart`
- Models / parsing: `test/unit/stock_models_test.dart`
- Watchlist DB/cache behavior: `test/unit/watchlist_service_test.dart`
- Formatters: `test/unit/formatters_test.dart`
- Providers: `test/provider/`
- Shared widgets: `test/widget/`

## Current Caveats

- The repository directory may not be a git worktree in this workspace.
- Some documentation describes future or intended behavior that is not fully implemented yet, especially caching tables, background notifications, Sentry instrumentation, and release automation.
- `README.md` is still template-like; prefer the docs and code for truth.
- Network-dependent behavior may be flaky because it relies on public external financial APIs and rate limits.
