import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Release signing credentials live OUTSIDE version control in
// android/key.properties (see android/key.properties.example for the exact
// format and android/KEYSTORE_SETUP.md for how to generate the keystore).
// Google Play Console refuses to accept an app signed with the debug
// keystore at all — there is no way to "test" a debug-signed release build
// on Play, it simply won't upload. So this reads a real signing config when
// key.properties exists, and only falls back to debug signing (with a
// build-time warning) when it doesn't, so `flutter run`/local testing still
// works without a keystore on hand.
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
val hasReleaseSigning = keystorePropertiesFile.exists()
if (hasReleaseSigning) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.smroyalcircle.app"
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.smroyalcircle.app"

        // minSdk 23 is REQUIRED, not arbitrary: the native splash
        // (res/drawable/launch_background.xml) positions the brand mark with
        // android:width/height/gravity on plain layer-list <item> elements,
        // which only works from API 23 up. Lowering this would silently break
        // the splash layout on old devices.
        minSdk = 23
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (hasReleaseSigning) {
            create("release") {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        release {
            if (hasReleaseSigning) {
                signingConfig = signingConfigs.getByName("release")
            } else {
                // No key.properties yet — falls back to the debug keystore so
                // local builds still work, but this build is NOT
                // Play-Console-uploadable. See android/KEYSTORE_SETUP.md.
                logger.warn(
                    "⚠️  android/key.properties not found — this release build is " +
                    "signed with the DEBUG keystore and CANNOT be uploaded to " +
                    "Google Play. See android/KEYSTORE_SETUP.md."
                )
                signingConfig = signingConfigs.getByName("debug")
            }

            isMinifyEnabled = true
            isShrinkResources = true
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
