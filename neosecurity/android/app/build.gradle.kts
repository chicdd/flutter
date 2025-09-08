plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.neo.neosecurity"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    buildFeatures {
        buildConfig = true   // ← 이 줄을 꼭 추가
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.neo.neosecurity"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }


    flavorDimensions += "company-class"

    productFlavors {
        create("seodaemun") {
            dimension = "company-class"
            applicationId = "com.neo.seodaemunPocom"
            manifestPlaceholders["appName"] = "서대문포콤"
            buildConfigField("String", "APP_NAME", "\"서대문포콤\"")
            buildConfigField("String", "GAETONG_CODE", "\"02111112\"")
        }
        create("C1") {
            dimension = "company-class"
            applicationId = "com.neo.C1"
            manifestPlaceholders["appName"] = "순천씨원"
            buildConfigField("String", "APP_NAME", "\"순천씨원\"")
            buildConfigField("String", "GAETONG_CODE", "\"61062298\"")
        }
        create("Kone") {
            dimension = "company-class"
            applicationId = "com.neo.Kone"
            manifestPlaceholders["appName"] = "한국안전시스템"
            buildConfigField("String", "APP_NAME", "\"한국안전시스템\"")
            buildConfigField("String", "GAETONG_CODE", "\"53220129\"")
        }
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
