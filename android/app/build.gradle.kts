plugins {
    id("com.android.application")

    // Firebase
    id("com.google.gms.google-services")

    id("org.jetbrains.kotlin.android")

    // Flutter plugin
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.matchly"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    defaultConfig {
        applicationId = "com.example.matchly"

        // Firebase requires at least 23
        minSdk = flutter.minSdkVersion

        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}
