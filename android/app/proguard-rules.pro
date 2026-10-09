# Foxpiry release shrink rules — MLKit ships optional language packs
# referenced via reflection. Silence R8, keep the core.
-keep class com.google.mlkit.** { *; }
-keep class com.google.android.gms.internal.mlkit.** { *; }
-dontwarn com.google.mlkit.**
-dontwarn com.google.android.gms.**
-dontwarn com.google.mlkit.vision.text.japanese.**
-dontwarn com.google.mlkit.vision.text.korean.**
-dontwarn com.google.mlkit.vision.text.chinese.**
-dontwarn com.google.mlkit.vision.text.devanagari.**

# flutter_local_notifications + Gson need generics signature kept —
# R8 strips it → "Missing type parameter" crash in cancelAll on cold start.
-keepattributes *Annotation*, Signature, InnerClasses, EnclosingMethod
-keep class com.dexterous.flutterlocalnotifications.** { *; }
-keep class androidx.core.app.NotificationCompat* { *; }
-keep class androidx.core.app.NotificationManagerCompat* { *; }
-keep class com.google.gson.** { *; }
-keep class * implements com.google.gson.TypeAdapterFactory
-keep class * implements com.google.gson.JsonSerializer
-keep class * implements com.google.gson.JsonDeserializer
