import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Band Low Tag widget.
/// Orange label indicating the stock is at a band low position.
/// Design: DESIGN.md BandLowTag component spec.
class BandLowTag extends StatelessWidget {
  const BandLowTag({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 18,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
      decoration: BoxDecoration(
        color: StockColors.bandLowBg,
        borderRadius: BorderRadius.circular(4),
      ),
      alignment: Alignment.center,
      child: const Text(
        '波段低位',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: StockColors.bandLow,
          height: 1.2,
        ),
      ),
    );
  }
}
