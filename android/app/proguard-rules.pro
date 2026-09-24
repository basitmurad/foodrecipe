# WorkManager (pulled in by Google Mobile Ads) creates its Room database by
# reflection. Without these rules R8 strips the generated constructor and the
# release build crashes on launch.
-keep class * extends androidx.room.RoomDatabase { <init>(); }
-keep class androidx.work.impl.** { *; }
