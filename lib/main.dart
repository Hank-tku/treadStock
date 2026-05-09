import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app.dart';
import 'core/constants/api_constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait mode before showing any UI.
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  // Check first-launch risk disclaimer.
  final prefs = await SharedPreferences.getInstance();
  final disclaimerAccepted = prefs.getBool('risk_disclaimer_accepted') ?? false;

  runApp(
    ProviderScope(
      child: StockPilotApp(disclaimerAccepted: disclaimerAccepted),
    ),
  );
}

/// Risk disclaimer dialog that must be acknowledged on first launch.
class RiskDisclaimerDialog extends StatelessWidget {
  const RiskDisclaimerDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // Prevent back button dismissal
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                size: 48,
                color: Color(0xFFE69321),
              ),
              const SizedBox(height: 16),
              const Text(
                '投资风险提示',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                '本应用提供的股票分析数据和技术指标仅供参考，不构成任何投资建议。\n\n'
                '股市有风险，投资需谨慎。过往表现不代表未来收益。请根据自身风险承受能力做出独立的投资决策。\n\n'
                '使用本应用即表示您已了解并自愿承担投资风险。',
                style: TextStyle(
                  fontSize: 14,
                  height: 1.6,
                  color: Color(0xFF6B6B6B),
                ),
                textAlign: TextAlign.justify,
              ),
              const SizedBox(height: 8),
              Text(
                AppConstants.disclaimer,
                style: const TextStyle(
                  fontSize: 11,
                  height: 1.4,
                  color: Color(0xFFBDBDBD),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton(
                  onPressed: () async {
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setBool('risk_disclaimer_accepted', true);
                    if (context.mounted) {
                      Navigator.of(context).pop(true);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A6AFF),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    '我已阅读并了解',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
