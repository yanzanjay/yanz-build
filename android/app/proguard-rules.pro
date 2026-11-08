# Flutter core
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.embedding.** { *; }
-dontwarn io.flutter.embedding.**

# Overlay
-keep class flutter.overlay.window.** { *; }

# Background service
-keep class id.flutter.flutter_background_service.** { *; }

# App classes
-keep class com.yanz.cheat.** { *; }

# Keep native methods
-keepclasseswithmembernames class * {
    native <methods>;
}
