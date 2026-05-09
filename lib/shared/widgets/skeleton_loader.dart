import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import 'package:shimmer/shimmer.dart';

/// Skeleton loading placeholder for stock list items.
class StockListItemSkeleton extends StatelessWidget {
  const StockListItemSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: StockColors.bgTertiary,
      highlightColor: StockColors.gray100,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.listItemPaddingH,
          vertical: AppTheme.listItemPaddingV,
        ),
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: StockColors.border, width: 1),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _buildSkeletonBox(28, 20), // score badge
                const SizedBox(width: 6),
                _buildSkeletonBox(80, 16), // name
                const Spacer(),
                _buildSkeletonBox(50, 14), // price
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                _buildSkeletonBox(80, 12), // code
                const Spacer(),
                _buildSkeletonBox(60, 14), // change%
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkeletonBox(double width, double height) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: StockColors.bgTertiary,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

/// Multiple skeleton list items.
class StockListSkeleton extends StatelessWidget {
  final int count;
  const StockListSkeleton({super.key, this.count = 6});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        count,
        (_) => const StockListItemSkeleton(),
      ),
    );
  }
}

/// Skeleton for detail page sections.
class DetailSectionSkeleton extends StatelessWidget {
  final double height;
  const DetailSectionSkeleton({super.key, this.height = 100});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: StockColors.bgTertiary,
      highlightColor: StockColors.gray100,
      child: Container(
        height: height,
        margin: const EdgeInsets.symmetric(horizontal: AppTheme.pagePadding),
        decoration: BoxDecoration(
          color: StockColors.bgTertiary,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        ),
      ),
    );
  }
}

/// Skeleton for news items.
class NewsItemSkeleton extends StatelessWidget {
  const NewsItemSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: StockColors.bgTertiary,
      highlightColor: StockColors.gray100,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.pagePadding,
          vertical: 8,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildBox(MediaQuery.of(context).size.width * 0.7, 16),
            const SizedBox(height: 8),
            _buildBox(120, 12),
          ],
        ),
      ),
    );
  }

  Widget _buildBox(double width, double height) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: StockColors.bgTertiary,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}
