import 'package:flutter/material.dart';
import 'package:stockpilot/core/theme/app_semantic_colors.dart';
import '../../core/theme/app_theme.dart';
import 'package:shimmer/shimmer.dart';

/// Skeleton loading placeholder for stock list items.
class StockListItemSkeleton extends StatelessWidget {
  const StockListItemSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: context.sc.bgTertiary,
      highlightColor: context.sc.gray100,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.listItemPaddingH,
          vertical: AppTheme.listItemPaddingV,
        ),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: context.sc.border, width: 1),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _buildSkeletonBox(context, 28, 20), // score badge
                const SizedBox(width: 6),
                _buildSkeletonBox(context, 80, 16), // name
                const Spacer(),
                _buildSkeletonBox(context, 50, 14), // price
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                _buildSkeletonBox(context, 80, 12), // code
                const Spacer(),
                _buildSkeletonBox(context, 60, 14), // change%
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkeletonBox(BuildContext context, double width, double height) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: context.sc.bgTertiary,
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
      baseColor: context.sc.bgTertiary,
      highlightColor: context.sc.gray100,
      child: Container(
        height: height,
        margin: const EdgeInsets.symmetric(horizontal: AppTheme.pagePadding),
        decoration: BoxDecoration(
          color: context.sc.bgTertiary,
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
      baseColor: context.sc.bgTertiary,
      highlightColor: context.sc.gray100,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.pagePadding,
          vertical: 8,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildBox(context, MediaQuery.of(context).size.width * 0.7, 16),
            const SizedBox(height: 8),
            _buildBox(context, 120, 12),
          ],
        ),
      ),
    );
  }

  Widget _buildBox(BuildContext context, double width, double height) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: context.sc.bgTertiary,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}
