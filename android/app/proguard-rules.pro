# ============================================================================
# Reguli ProGuard / R8 release (Football 2026 Live).
# proguard-android.txt (NU -optimize) ca să nu strice plugin-urile cu reflexie.
# ============================================================================

# ---- Flutter ----
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.embedding.** { *; }
-dontwarn io.flutter.embedding.**

# ---- Entry point aplicație ----
-keep class ro.summersmile.football_live.** { *; }

# ---- Google Mobile Ads ----
-keep class com.google.android.gms.ads.** { *; }
-keep class com.google.ads.** { *; }
-keep class com.google.android.gms.common.** { *; }
-dontwarn com.google.android.gms.ads.**

# ---- Atribute reflexie / Gson intern ----
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes InnerClasses,EnclosingMethod
-keep class com.google.gson.** { *; }
-keepclassmembers enum * { *; }

# ---- Kotlin ----
-keep class kotlin.Metadata { *; }
-dontwarn kotlin.**
-dontwarn kotlinx.**
