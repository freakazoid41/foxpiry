plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

import java.io.FileInputStream

// Release keystore lives in android/key.properties (git-ignored).
// Falls back to debug keys when the file is missing so local
// `flutter run --release` never breaks on a fresh checkout.
fun foxKey(key: String): String? = try {
    rootProject.file("key.properties").readLines()
        .first { line -> line.startsWith("$key=") }
        .substringAfter("=")
} catch (e: Exception) {
    null
}

android {
    namespace = "com.foxpry.app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    signingConfigs {
        create("foxpiry") {
            keyAlias = foxKey("keyAlias") ?: "foxpiry"
            keyPassword = foxKey("keyPassword")
            storeFile = foxKey("storeFile")?.let { name -> rootProject.file(name) }
            storePassword = foxKey("storePassword")
        }
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.foxpry.app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        // google_mobile_ads needs min 23.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // Real keystore when key.properties exists, debug keys otherwise.
            signingConfig = if (foxKey("storePassword").isNullOrEmpty()) {
                signingConfigs.getByName("debug")
            } else {
                signingConfigs.getByName("foxpiry")
            }
            isMinifyEnabled = true
            isShrinkResources = false
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
