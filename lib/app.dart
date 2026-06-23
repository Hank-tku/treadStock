import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'core/theme/app_theme.dart';
import 'shared/providers.dart';
import 'features/onboarding/data/onboarding_service.dart';
import 'features/onboarding/presentation/onboarding_page.dart';
import 'features/recommendation/presentation/recommendation_tab.dart';
import 'features/watchlist/presentation/watchlist_tab.dart';
import 'features/stock/presentation/stock_detail_page.dart';
import 'features/strategy/presentation/strategy_tab.dart';
import 'features/strategy/presentation/strategy_detail_page.dart';
import 'features/strategy/presentation/strategy_edit_page.dart';
import 'features/strategy/presentation/strategy_knowledge_page.dart';
import 'features/strategy/presentation/backtest_config_page.dart';
import 'features/strategy/presentation/strategy_compare_page.dart';
import 'features/strategy/presentation/strategy_template_page.dart';
import 'features/strategy/presentation/strategy_tuner_page.dart';
import 'features/strategy/presentation/strategy_creation_guide_page.dart';
import 'features/strategy/domain/strategy_models.dart';
import 'main.dart' show RiskDisclaimerDialog;

/// Root router configuration.
final _rootNavigatorKey = GlobalKey<NavigatorState>();

class AppRouter {
  AppRouter._();

  static final GoRouter router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/recommend',
    debugLogDiagnostics: false,
    redirect: (context, state) async {
      final currentPath = state.matchedLocation;
      // If already on onboarding page, do nothing.
      if (currentPath == '/onboarding') return null;
      // Check if onboarding is needed.
      final onboardingService = OnboardingService();
      final completed = await onboardingService.isCompleted();
      if (!completed) return '/onboarding';
      return null;
    },
    routes: [
      GoRoute(
        path: '/onboarding',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const OnboardingPage(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return _MainScaffold(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/recommend',
                builder: (context, state) => const RecommendationTab(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/watchlist',
                builder: (context, state) => const WatchlistTab(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/strategies',
                builder: (context, state) => const StrategyTab(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/stock/:code',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return StockDetailPage(
            code: state.pathParameters['code'] ?? '',
            name: extra?['name'] as String? ?? '',
            market: extra?['market'] as String? ?? 'SH',
            strategyId: extra?['strategyId'] as String?,
            strategyName: extra?['strategyName'] as String?,
          );
        },
      ),
      GoRoute(
        path: '/strategy/new',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const StrategyEditPage(),
      ),
      GoRoute(
        path: '/strategy/create',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const StrategyCreationGuidePage(),
      ),
      GoRoute(
        path: '/strategy/knowledge',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const StrategyKnowledgePage(),
      ),
      GoRoute(
        path: '/strategy/:id/edit',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return StrategyEditPage(
            strategyId: state.pathParameters['id'],
            suggestion: extra?['suggestion'] as StrategySuggestion?,
          );
        },
      ),
      GoRoute(
        path: '/strategy/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          return StrategyDetailPage(
            strategyId: state.pathParameters['id'] ?? '',
          );
        },
      ),
      GoRoute(
        path: '/strategy/:id/backtest',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return BacktestConfigPage(
            strategyId: state.pathParameters['id'] ?? '',
            strategyName: extra?['strategyName'] as String? ?? '',
          );
        },
      ),
      GoRoute(
        path: '/strategy/compare',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const StrategyComparePage(),
      ),
      GoRoute(
        path: '/strategy/templates',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const StrategyTemplatePage(),
      ),
      GoRoute(
        path: '/strategy/:id/tuner',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return StrategyTunerPage(
            strategyId: state.pathParameters['id'] ?? '',
            stockCode: extra?['stockCode'] as String? ?? '',
          );
        },
      ),
    ],
  );
}

/// Main scaffold with bottom tab bar.
class _MainScaffold extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const _MainScaffold({required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: navigationShell.currentIndex,
        onTap: (index) {
          if (index == navigationShell.currentIndex) {
            // Tapping the active tab again scrolls its primary scrollable
            // back to the top, matching common list-app behavior.
            final controller = PrimaryScrollController.maybeOf(context);
            if (controller != null && controller.hasClients) {
              controller.animateTo(
                0,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
              );
            }
            return;
          }
          navigationShell.goBranch(index);
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.trending_up_outlined, size: 24),
            activeIcon: Icon(Icons.trending_up, size: 24),
            label: '推荐',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.star_outline, size: 24),
            activeIcon: Icon(Icons.star, size: 24),
            label: '关注',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.lightbulb_outline, size: 24),
            activeIcon: Icon(Icons.lightbulb, size: 24),
            label: '策略',
          ),
        ],
      ),
    );
  }
}

/// App widget.
class StockPilotApp extends ConsumerStatefulWidget {
  final bool disclaimerAccepted;

  const StockPilotApp({super.key, required this.disclaimerAccepted});

  @override
  ConsumerState<StockPilotApp> createState() => _StockPilotAppState();
}

class _StockPilotAppState extends ConsumerState<StockPilotApp>
    with WidgetsBindingObserver {
  Timer? _foregroundAlertTimer;
  Timer? _startupAlertTimer;

  @override
  void initState() {
    super.initState();
    // Observe lifecycle so we can run an alert scan when the user returns to
    // the app, in addition to the periodic foreground timer below.
    WidgetsBinding.instance.addObserver(this);

    // Load the persisted theme mode (defaults to system). Done after first
    // frame so the MaterialApp builds with the correct themeMode immediately
    // rather than flashing the default.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(themeModeProvider.notifier).init();
    });

    // Periodic foreground alert scan. The background workmanager task is the
    // primary mechanism; this timer ensures alerts still fire reasonably
    // promptly while the app is in the foreground.
    _foregroundAlertTimer = Timer.periodic(
      const Duration(minutes: 30),
      (_) => _runAlertScan(),
    );
    // Kick off one scan shortly after startup so a recently-triggered
    // condition surfaces quickly.
    _startupAlertTimer = Timer(const Duration(seconds: 15), _runAlertScan);
  }

  @override
  void dispose() {
    _foregroundAlertTimer?.cancel();
    _startupAlertTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      // User came back to the app — run an alert scan immediately. The
      // scheduler coalesces re-entrant calls and de-duplicates per day.
      _runAlertScan();
      // Also run the daily review pass; ReviewScheduler de-duplicates by
      // calendar day so this is cheap when already done today.
      ref.read(reviewSchedulerProvider).runDailyReview();
    }
  }

  void _runAlertScan() {
    // Fire and forget; AlertScheduler swallows per-stock errors and logs them.
    ref.read(alertSchedulerProvider).runScan();
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    return MaterialApp.router(
      title: '股势 TrendStock',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      routerConfig: AppRouter.router,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('zh', 'CN'), Locale('en', 'US')],
      locale: const Locale('zh', 'CN'),
      builder: (context, child) {
        return _DisclaimerWrapper(
          disclaimerAccepted: widget.disclaimerAccepted,
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}

/// Wrapper that shows risk disclaimer inside MaterialApp context.
class _DisclaimerWrapper extends StatefulWidget {
  final bool disclaimerAccepted;
  final Widget child;

  const _DisclaimerWrapper({
    required this.disclaimerAccepted,
    required this.child,
  });

  @override
  State<_DisclaimerWrapper> createState() => _DisclaimerWrapperState();
}

class _DisclaimerWrapperState extends State<_DisclaimerWrapper> {
  @override
  void initState() {
    super.initState();
    if (!widget.disclaimerAccepted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _showRiskDisclaimer();
      });
    }
  }

  Future<void> _showRiskDisclaimer() async {
    final navContext = _rootNavigatorKey.currentContext;
    if (navContext == null) return;
    final accepted = await showDialog<bool>(
      context: navContext,
      barrierDismissible: false,
      builder: (_) => const RiskDisclaimerDialog(),
    );
    if (accepted == true && mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
