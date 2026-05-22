# --- iLearnIt ProGuard / R8 rules ---
# Keep what Flutter, Firebase, and our plugins need at runtime.

# Flutter
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.embedding.**

# Firebase / Google Play Services
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**

# In-app purchase (Play Billing)
-keep class com.android.billingclient.** { *; }
-dontwarn com.android.billingclient.**

# OkHttp / Dio (Conscrypt is optional but commonly pulled in)
-dontwarn org.conscrypt.**
-dontwarn org.bouncycastle.**
-dontwarn org.openjsse.**

# Keep model classes annotated for JSON serialization (json_serializable + freezed)
-keepclassmembers class * {
    @com.google.gson.annotations.SerializedName <fields>;
}

# Keep Parcelable / Serializable
-keepnames class * implements android.os.Parcelable
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}

# Strip log calls from release builds (optional; comment out if you need them)
-assumenosideeffects class android.util.Log {
    public static int v(...);
    public static int d(...);
    public static int i(...);
}
