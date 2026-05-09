# TrendStock (股势) ProGuard Rules

# =============================================
# Flutter / Dart
# =============================================

# Keep Flutter classes used in reflection / plugin registration
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Keep Dart model classes used by JSON serialization (json_serializable / freezed)
-keep class com.stockpilot.stockpilot.** { *; }

# =============================================
# Drift ORM (SQLite)
# =============================================
-keep class drift.** { *; }
-keep class * extends drift.DartType { *; }

# =============================================
# Remove debug / verbose logs in release
# =============================================
-assumenosideeffects class android.util.Log {
    public static *** d(...);
    public static *** v(...);
    public static *** i(...);
    public static *** w(...);
    public static *** e(...);
}

# =============================================
# Keep enum values (used by Drift and data models)
# =============================================
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# =============================================
# Obfuscate generic signatures
# =============================================
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes SourceFile,LineNumberTable
