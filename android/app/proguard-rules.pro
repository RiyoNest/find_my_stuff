# Flutter
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Firebase
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**

# Play Core
-keep class com.google.android.play.core.** { *; }
-dontwarn com.google.android.play.core.**

# Gson
-keepattributes Signature
-keepattributes *Annotation*

# Exif
-keep class androidx.exifinterface.** { *; }

# ObjectBox
-keep class io.objectbox.** { *; }
-dontwarn io.objectbox.**

# Speech To Text
-keep class android.speech.** { *; }

# File Picker
-keep class com.mr.flutter.plugin.filepicker.** { *; }

# Share Plus
-keep class dev.fluttercommunity.plus.share.** { *; }

# Model Classes
-keep class com.riyonest.find_my_stuff.models.** { *; }