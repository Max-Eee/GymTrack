# LiteRT-LM - keep all LiteRT classes
-keep class com.google.ai.edge.** { *; }
-keep class com.google.android.gms.internal.** { *; }

# OkHttp
-keep class okhttp3.** { *; }
-keep interface okhttp3.** { *; }
-dontwarn okhttp3.**
-dontwarn okio.**

# Kotlin coroutines
-keep class kotlinx.coroutines.** { *; }
-dontwarn kotlinx.coroutines.**

# Keep the ModelDownloadService and MainActivity native methods
-keep class com.gymtrack.gym_track.** { *; }
