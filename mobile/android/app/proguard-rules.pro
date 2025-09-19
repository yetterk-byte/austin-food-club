# Austin Food Club ProGuard Rules

# Flutter specific rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Dart specific rules
-dontwarn io.flutter.embedding.**
-keep class io.flutter.embedding.** { *; }

# Firebase rules
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**

# Firebase Messaging
-keep class com.google.firebase.messaging.** { *; }
-keep class com.google.firebase.iid.** { *; }

# Supabase rules
-keep class io.supabase.** { *; }
-dontwarn io.supabase.**

# Image processing rules
-keep class androidx.exifinterface.** { *; }
-keep class com.bumptech.glide.** { *; }
-dontwarn com.bumptech.glide.**

# Camera and photo rules
-keep class androidx.camera.** { *; }
-dontwarn androidx.camera.**

# Network and HTTP rules
-keep class okhttp3.** { *; }
-keep class retrofit2.** { *; }
-dontwarn okhttp3.**
-dontwarn retrofit2.**

# JSON and serialization rules
-keep class com.google.gson.** { *; }
-keep class * implements com.google.gson.TypeAdapterFactory
-keep class * implements com.google.gson.JsonSerializer
-keep class * implements com.google.gson.JsonDeserializer
-keepclassmembers,allowobfuscation class * {
  @com.google.gson.annotations.SerializedName <fields>;
}

# Model classes (keep all fields and methods)
-keep class com.austinfoodclub.app.models.** { *; }

# Keep native methods
-keepclassmembers class * {
    native <methods>;
}

# Keep enums
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# Keep Parcelable implementations
-keep class * implements android.os.Parcelable {
  public static final android.os.Parcelable$Creator *;
}

# Keep Serializable classes
-keepnames class * implements java.io.Serializable
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}

# Keep annotations
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes InnerClasses
-keepattributes EnclosingMethod

# Remove logging in release builds
-assumenosideeffects class android.util.Log {
    public static boolean isLoggable(java.lang.String, int);
    public static int v(...);
    public static int i(...);
    public static int w(...);
    public static int d(...);
    public static int e(...);
}

# Keep line numbers for crash reports
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile

# Optimize and obfuscate
-optimizations !code/simplification/arithmetic,!code/simplification/cast,!field/*,!class/merging/*
-optimizationpasses 5
-allowaccessmodification
-dontpreverify

# Don't warn about missing classes
-dontwarn javax.annotation.**
-dontwarn javax.inject.**
-dontwarn sun.misc.Unsafe

# Keep crashlytics (if using Firebase Crashlytics)
-keep class com.crashlytics.** { *; }
-dontwarn com.crashlytics.**

# SQLite rules
-keep class org.sqlite.** { *; }
-keep class org.sqlite.database.** { *; }

# Hive database rules
-keep class hive.** { *; }
-keep class * extends hive.HiveObject { *; }

# Connectivity rules
-keep class io.flutter.plugins.connectivity.** { *; }

# Permission handler rules
-keep class com.baseflow.permissionhandler.** { *; }

# Image picker rules
-keep class io.flutter.plugins.imagepicker.** { *; }

# URL launcher rules
-keep class io.flutter.plugins.urllauncher.** { *; }

# Share plus rules
-keep class dev.fluttercommunity.plus.share.** { *; }

# Local auth rules
-keep class io.flutter.plugins.localauth.** { *; }

# Path provider rules
-keep class io.flutter.plugins.pathprovider.** { *; }

# Specific app rules
-keep class com.austinfoodclub.app.** { *; }

# Keep BuildConfig
-keep class com.austinfoodclub.app.BuildConfig { *; }

# Keep Application class
-keep public class * extends android.app.Application

# Keep Activity classes
-keep public class * extends android.app.Activity
-keep public class * extends android.app.Service
-keep public class * extends android.content.BroadcastReceiver
-keep public class * extends android.content.ContentProvider

# WebView rules (if using webview)
-keepclassmembers class fqcn.of.javascript.interface.for.webview {
   public *;
}

# Keep custom exceptions
-keep public class * extends java.lang.Exception

