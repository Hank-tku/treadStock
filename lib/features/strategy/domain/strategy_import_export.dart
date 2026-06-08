import 'dart:convert';

import 'strategy_models.dart';

/// Domain service for importing and exporting strategies as JSON.
class StrategyImportExport {
  StrategyImportExport._();

  /// Current export format version.
  static const int _exportVersion = 1;

  /// App identifier embedded in export wrappers.
  static const String _appId = 'stockpilot';

  /// Exports a single [strategy] as a pretty-printed JSON string wrapped in
  /// a metadata envelope containing version, app id, and timestamp.
  static String exportStrategy(Strategy strategy) {
    final wrapper = <String, dynamic>{
      'version': _exportVersion,
      'app': _appId,
      'exportedAt': DateTime.now().toIso8601String(),
      'strategy': strategy.toJson(),
    };
    return const JsonEncoder.withIndent('  ').convert(wrapper);
  }

  /// Parses [jsonString] and returns a [Strategy].
  ///
  /// Supports both the wrapped envelope format (with `strategy` key) and a
  /// raw strategy JSON object for flexibility.
  static Strategy importStrategy(String jsonString) {
    final dynamic parsed = jsonDecode(jsonString);

    if (parsed is! Map<String, dynamic>) {
      throw FormatException('Invalid strategy JSON: expected a JSON object');
    }

    final Map<String, dynamic> data;
    if (parsed.containsKey('strategy')) {
      // Wrapped format — validate envelope fields.
      _validateEnvelope(parsed);
      data = parsed['strategy'] as Map<String, dynamic>;
    } else {
      // Assume raw strategy JSON.
      data = parsed;
    }

    return Strategy.fromJson(data);
  }

  /// Validates [jsonString] without fully parsing into a [Strategy].
  ///
  /// Returns `null` if the JSON is valid, or an error message describing the
  /// problem.
  static String? validateImportJson(String jsonString) {
    try {
      final dynamic parsed = jsonDecode(jsonString);
      if (parsed is! Map<String, dynamic>) {
        return 'Invalid format: expected a JSON object';
      }

      if (parsed.containsKey('strategy')) {
        // Wrapped format — check envelope.
        final envelopeError = _validateEnvelopeOrNull(parsed);
        if (envelopeError != null) return envelopeError;

        final strategyJson = parsed['strategy'];
        if (strategyJson is! Map<String, dynamic>) {
          return 'Invalid format: "strategy" must be a JSON object';
        }
        _tryParseStrategy(strategyJson);
      } else {
        // Raw strategy JSON — must have the required keys.
        _tryParseStrategy(parsed);
      }

      return null; // valid
    } on FormatException catch (e) {
      return 'JSON parse error: ${e.message}';
    } catch (e) {
      return 'Validation error: $e';
    }
  }

  /// Exports a list of [strategies] as a list of pretty-printed JSON strings,
  /// one per strategy.
  static List<String> batchExport(List<Strategy> strategies) {
    return strategies.map(exportStrategy).toList();
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  /// Validates the envelope fields of a wrapped export. Throws on problems.
  static void _validateEnvelope(Map<String, dynamic> wrapper) {
    final version = wrapper['version'];
    if (version is! int) {
      throw FormatException(
        'Invalid export envelope: missing or invalid "version"',
      );
    }
    if (version > _exportVersion) {
      throw FormatException(
        'Unsupported export version $version (max supported: $_exportVersion)',
      );
    }

    final app = wrapper['app'];
    if (app is! String) {
      throw FormatException(
        'Invalid export envelope: missing or invalid "app"',
      );
    }
  }

  /// Same as [_validateEnvelope] but returns an error string instead of
  /// throwing. Used by [validateImportJson].
  static String? _validateEnvelopeOrNull(Map<String, dynamic> wrapper) {
    final version = wrapper['version'];
    if (version is! int) {
      return 'Invalid envelope: missing or invalid "version"';
    }
    if (version > _exportVersion) {
      return 'Unsupported export version $version (max supported: $_exportVersion)';
    }

    final app = wrapper['app'];
    if (app is! String) {
      return 'Invalid envelope: missing or invalid "app"';
    }

    return null;
  }

  /// Attempts to construct a [Strategy] from [json] to surface any
  /// deserialization errors during validation.
  static void _tryParseStrategy(Map<String, dynamic> json) {
    Strategy.fromJson(json);
  }
}
