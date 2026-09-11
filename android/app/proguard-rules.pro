# Flutter and its plugins register Android entry points dynamically.
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Firebase and Google Sign-In use reflection and generated registries.
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }

# Local notification callbacks and messaging background entry points.
-keep class com.dexterous.flutterlocalnotifications.** { *; }
-keep class com.google.firebase.messaging.** { *; }
