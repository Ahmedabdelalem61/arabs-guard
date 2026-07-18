plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.arabsguard.arabs_guard"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion
    testBuildType = "release"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.arabsguard.arabs_guard"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        testInstrumentationRunner = "androidx.test.runner.AndroidJUnitRunner"
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    testImplementation("junit:junit:4.13.2")
    androidTestImplementation("androidx.test:core-ktx:1.7.0")
    androidTestImplementation("androidx.test.ext:junit-ktx:1.3.0")
    androidTestImplementation("androidx.test:runner:1.7.0")
    androidTestImplementation("com.google.errorprone:error_prone_annotations:2.50.0")
}
