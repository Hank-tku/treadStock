// T-F003-4, T-F004-2: ScoreBadge Widget 测试

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stockpilot/shared/widgets/score_badge.dart';
import 'package:stockpilot/core/theme/app_colors.dart';

void main() {
  group('T-F003-4: ScoreBadge', () {
    testWidgets('高分（>=8）显示红色背景', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: Center(child: ScoreBadge(score: 9))),
        ),
      );

      final container = tester.widget<Container>(
        find.ancestor(
          of: find.text('9'),
          matching: find.byType(Container),
        ).first,
      );
      final decoration = container.decoration as BoxDecoration;
      // score >= 8 -> upBg = rgba(230, 67, 45, 0.08)
      expect(decoration.color, StockColors.upBg);
    });

    testWidgets('中分（5-7）显示黄色背景', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: Center(child: ScoreBadge(score: 6))),
        ),
      );

      final container = tester.widget<Container>(
        find.ancestor(
          of: find.text('6'),
          matching: find.byType(Container),
        ).first,
      );
      final decoration = container.decoration as BoxDecoration;
      // score 5-7 -> rgba(212,160,23,0.08)
      expect(decoration.color, Color(0x14D4A017));
    });

    testWidgets('低分（<5）显示绿色背景', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: Center(child: ScoreBadge(score: 3))),
        ),
      );

      final container = tester.widget<Container>(
        find.ancestor(
          of: find.text('3'),
          matching: find.byType(Container),
        ).first,
      );
      final decoration = container.decoration as BoxDecoration;
      // score < 5 -> downBg = rgba(29, 185, 84, 0.08)
      expect(decoration.color, StockColors.downBg);
    });

    testWidgets('null score 显示 N/A', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: Center(child: ScoreBadge(score: null))),
        ),
      );

      expect(find.text('N/A'), findsOneWidget);

      final container = tester.widget<Container>(
        find.ancestor(
          of: find.text('N/A'),
          matching: find.byType(Container),
        ).first,
      );
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, StockColors.gray200);
    });

    testWidgets('显示正确的分数文字', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: Center(child: ScoreBadge(score: 10))),
        ),
      );
      expect(find.text('10'), findsOneWidget);
    });
  });

  group('T-F004-2: ScoreBadgeLoading', () {
    testWidgets('显示加载占位符', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: Center(child: ScoreBadgeLoading())),
        ),
      );

      expect(find.text('...'), findsOneWidget);
    });
  });
}
