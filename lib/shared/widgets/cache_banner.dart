import 'package:flutter/material.dart';
import 'package:stockpilot/core/theme/app_semantic_colors.dart';
import '../../core/theme/app_colors.dart';

/// Cache/Offline banner shown when network is unavailable.
/// Design: DESIGN.md CacheBanner component spec.
class CacheBanner extends StatelessWidget {
  final String message;
  final String? timestamp;
  final VoidCallback? onClose;

  const CacheBanner({
    super.key,
    required this.message,
    this.timestamp,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 32,
      color: context.sc.bgWarning,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          const Icon(
            Icons.wifi_off,
            size: 16,
            color: StockColors.warning,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 12,
                color: context.sc.cacheBannerText,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
          if (timestamp != null)
            Text(
              timestamp!,
              style: TextStyle(
                fontSize: 11,
                color: context.sc.gray500,
              ),
            ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onClose,
            child: Icon(
              Icons.close,
              size: 16,
              color: context.sc.gray500,
            ),
          ),
        ],
      ),
    );
  }
}
