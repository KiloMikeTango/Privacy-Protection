 -keep class io.flutter.** { *; }
-keep class com.shield.kilowares.MainActivity { *; }
-keep class com.protection.kilowares.mm.OverlayService { *; }
-keep class com.protection.kilowares.mm.ForegroundDetectorService { *; }

-keep class androidx.security.crypto.** { *; }
-keep class com.google.crypto.tink.** { *; }
-keep class com.google.protobuf.** { *; }

-dontwarn com.google.android.play.core.**
-dontwarn com.google.errorprone.annotations.**
-dontwarn javax.annotation.concurrent.**
-dontwarn org.checkerframework.**
