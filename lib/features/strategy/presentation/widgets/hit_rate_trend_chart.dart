import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:stockpilot/core/theme/app_colors.dart';
import 'package:stockpilot/core/theme/app_text_styles.dart';
import '../providers/hit_rate_trend_provider.dart';

/// Hit rate trend chart widget using CustomPainter.
///
/// Draws a line chart of daily hit rates over the past 30 trading days.
/// Shows "数据积累中" placeholder when no data is available.
class HitRateTrendChart extends StatelessWidget {
  final List<DailyHitRate> data;
  final double height;

  const HitRateTrendChart({
    super.key,
    required this.data,
    this.height = 200,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return SizedBox(
        height: height,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.show_chart,
                size: 40,
                color: StockColors.gray400,
              ),
              const SizedBox(height: 8),
              Text(
                '数据积累中',
                style: AppTextStyles.body.copyWith(
                  color: StockColors.textTertiary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '满 5 个交易日后可查看命中率趋势',
                style: AppTextStyles.caption.copyWith(
                  color: StockColors.textTertiary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SizedBox(
      height: height,
      child: CustomPaint(
        painter: _HitRateTrendPainter(data: data),
        size: Size.infinite,
      ),
    );
  }
}

class _HitRateTrendPainter extends CustomPainter {
  final List<DailyHitRate> data;

  _HitRateTrendPainter({required this.data});

  // Chart padding
  static const double _leftPadding = 36;
  static const double _rightPadding = 12;
  static const double _topPadding = 12;
  static const double _bottomPadding = 24;

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final chartWidth = size.width - _leftPadding - _rightPadding;
    final chartHeight = size.height - _topPadding - _bottomPadding;

    if (chartWidth <= 0 || chartHeight <= 0) return;

    final chartLeft = _leftPadding;
    final chartTop = _topPadding;

    // Draw Y axis labels and grid lines
    _drawYAxis(canvas, chartLeft, chartTop, chartHeight);

    // Draw 50% reference dashed line
    _drawDashedLine(
      canvas,
      Offset(chartLeft, chartTop + chartHeight * 0.5),
      Offset(chartLeft + chartWidth, chartTop + chartHeight * 0.5),
      StockColors.gray300,
      dashWidth: 4,
      dashGap: 3,
    );

    // Draw X axis labels (first, middle, last)
    _drawXAxis(canvas, chartLeft, chartTop + chartHeight, chartWidth);

    // Compute data points
    final points = <Offset>[];
    final stepX = data.length > 1 ? chartWidth / (data.length - 1) : 0.0;
    for (var i = 0; i < data.length; i++) {
      final x = chartLeft + i * stepX;
      final y = chartTop + chartHeight * (1.0 - data[i].hitRate);
      points.add(Offset(x, y));
    }

    if (points.isEmpty) return;

    // Draw filled area gradient under the line
    _drawFillArea(canvas, points, chartLeft + chartWidth, chartTop + chartHeight);

    // Draw the line
    final linePaint = Paint()
      ..color = StockColors.up
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    if (points.length == 1) {
      canvas.drawPoints(PointMode.points, points, linePaint);
    } else {
      final path = Path()..moveTo(points[0].dx, points[0].dy);
      for (var i = 1; i < points.length; i++) {
        path.lineTo(points[i].dx, points[i].dy);
      }
      canvas.drawPath(path, linePaint);
    }

    // Draw data point dots
    final dotPaint = Paint()
      ..color = StockColors.up
      ..style = PaintingStyle.fill;
    final dotBorderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    for (final point in points) {
      canvas.drawCircle(point, 3.5, dotBorderPaint);
      canvas.drawCircle(point, 2.5, dotPaint);
    }
  }

  void _drawYAxis(Canvas canvas, double chartLeft, double chartTop, double chartHeight) {
    final labels = ['100%', '50%', '0%'];
    final positions = [0.0, 0.5, 1.0];

    final textStyle = TextStyle(
      color: StockColors.textTertiary,
      fontSize: 10,
    );

    for (var i = 0; i < labels.length; i++) {
      final y = chartTop + chartHeight * positions[i];

      // Grid line
      final gridPaint = Paint()
        ..color = StockColors.gray200
        ..strokeWidth = 0.5;
      canvas.drawLine(
        Offset(chartLeft, y),
        Offset(chartLeft + 200, y), // extends off-screen, clipped by parent
        gridPaint,
      );

      // Label
      final span = TextSpan(text: labels[i], style: textStyle);
      final tp = TextPainter(text: span, textDirection: TextDirection.ltr)
        ..layout();
      tp.paint(canvas, Offset(chartLeft - tp.width - 4, y - tp.height / 2));
    }
  }

  void _drawXAxis(
    Canvas canvas,
    double chartLeft,
    double chartBottom,
    double chartWidth,
  ) {
    if (data.isEmpty) return;

    final textStyle = TextStyle(
      color: StockColors.textTertiary,
      fontSize: 10,
    );

    // Show 3 labels: first, middle, last
    final indices = <int>[0];
    if (data.length > 2) {
      indices.add(data.length ~/ 2);
    }
    if (data.length > 1) {
      indices.add(data.length - 1);
    }

    for (final idx in indices) {
      final label = data[idx].dateLabel;
      final stepX = data.length > 1 ? chartWidth / (data.length - 1) : 0.0;
      final x = chartLeft + idx * stepX;

      final span = TextSpan(text: label, style: textStyle);
      final tp = TextPainter(text: span, textDirection: TextDirection.ltr)
        ..layout();
      tp.paint(canvas, Offset(x - tp.width / 2, chartBottom + 4));
    }
  }

  void _drawFillArea(
    Canvas canvas,
    List<Offset> points,
    double chartRight,
    double chartBottom,
  ) {
    if (points.isEmpty) return;

    final fillPath = Path()..moveTo(points[0].dx, points[0].dy);
    for (var i = 1; i < points.length; i++) {
      fillPath.lineTo(points[i].dx, points[i].dy);
    }
    fillPath.lineTo(points.last.dx, chartBottom);
    fillPath.lineTo(points.first.dx, chartBottom);
    fillPath.close();

    final rect = Rect.fromLTRB(
      points.first.dx,
      0,
      points.last.dx,
      chartBottom,
    );

    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        StockColors.up.withValues(alpha: 0.20),
        StockColors.up.withValues(alpha: 0.02),
      ],
    );

    final fillPaint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.fill;

    canvas.drawPath(fillPath, fillPaint);
  }

  void _drawDashedLine(
    Canvas canvas,
    Offset start,
    Offset end,
    Color color, {
    double dashWidth = 5,
    double dashGap = 3,
  }) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.0;

    final dx = end.dx - start.dx;
    final dy = end.dy - start.dy;
    final totalLength = math.sqrt(dx * dx + dy * dy);

    if (totalLength == 0) return;

    final unitX = dx / totalLength;
    final unitY = dy / totalLength;

    var drawn = 0.0;
    var drawing = true;

    while (drawn < totalLength) {
      final segmentLength = drawing ? dashWidth : dashGap;
      final endDrawn = math.min(drawn + segmentLength, totalLength);

      if (drawing) {
        canvas.drawLine(
          Offset(start.dx + unitX * drawn, start.dy + unitY * drawn),
          Offset(start.dx + unitX * endDrawn, start.dy + unitY * endDrawn),
          paint,
        );
      }

      drawn = endDrawn;
      drawing = !drawing;
    }
  }

  @override
  bool shouldRepaint(_HitRateTrendPainter oldDelegate) {
    return oldDelegate.data != data;
  }
}
