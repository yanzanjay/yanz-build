# Flutter core
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.embedding.** { *; }
-dontwarn io.flutter.embedding.**

# Overlay
-keep class flutter.overlay.window.** { *; }

# Background service
-keep class id.flutter.flutter_background_service.** { *; }

# device_info_plus (yang tadi bikin error)
-keep class dev.fluttercommunity.plus.device_info.** { *; }
-dontwarn dev.fluttercommunity.plus.device_info.**

# permission_handler
-keep class com.baseflow.permissionhandler.** { *; }

# shared_preferences
-keep class io.flutter.plugins.sharedpreferences.** { *; }

# App
-keep class com.yanz.cheat.** { *; }

# Native methods
-keepclasseswithmembernames class * {
    native <methods>;
}
