import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

// Release signing credentials live in android/key.properties, which is
// gitignored — it is never committed and holds no default. See
// https://flutter.dev/to/reference-keystore
val keystorePropertiesFile = rootProject.file("key.properties")
val hasReleaseKeystore = keystorePropertiesFile.exists()
val keystoreProperties =
    Properties().apply {
        if (hasReleaseKeystore) {
            keystorePropertiesFile.inputStream().use { load(it) }
        }
    }

android {
    namespace = "com.daivajna.daivajna_census"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        // Required by flutter_local_notifications (it uses java.time APIs
        // that need desugaring to run on Android versions below API 26).
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.daivajna.daivajna_census"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        // Firebase Auth requires minSdk 23.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        // Only declared when key.properties is present, so debug and profile
        // builds work on a machine that has no upload keystore at all.
        if (hasReleaseKeystore) {
            create("release") {
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
                storePassword = keystoreProperties.getProperty("storePassword")
                // Absolute paths are used as-is; relative ones resolve against
                // the android/ directory next to key.properties.
                storeFile = keystoreProperties.getProperty("storeFile")?.let { rootProject.file(it) }
            }
        }
    }

    buildTypes {
        release {
            // Never fall back to the debug keys here: Play rejects
            // debug-signed artifacts, and a silent fallback would only
            // surface at upload time. The task-graph check below fails the
            // build up front instead.
            signingConfig = if (hasReleaseKeystore) signingConfigs.getByName("release") else null
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // The library isCoreLibraryDesugaringEnabled above pulls in.
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}

// Fail a release build immediately, with an actionable message, when signing
// credentials are absent or incomplete. Debug and profile builds are
// untouched, so `flutter run` keeps working without a keystore.
gradle.taskGraph.whenReady {
    val buildsRelease = allTasks.any { it.project == project && it.name.endsWith("Release") }
    if (!buildsRelease) return@whenReady

    if (!hasReleaseKeystore) {
        throw GradleException(
            "Release build requires signing credentials, but\n\n" +
                "  ${keystorePropertiesFile.path}\n\n" +
                "does not exist. Create it with keyAlias, keyPassword, storePassword " +
                "and storeFile pointing at your upload keystore. " +
                "See https://flutter.dev/to/reference-keystore",
        )
    }

    val missing =
        listOf("keyAlias", "keyPassword", "storePassword", "storeFile")
            .filter { keystoreProperties.getProperty(it).isNullOrBlank() }
    if (missing.isNotEmpty()) {
        throw GradleException(
            "${keystorePropertiesFile.path} is missing required values: " + missing.joinToString(", "),
        )
    }

    val storeFile = rootProject.file(keystoreProperties.getProperty("storeFile"))
    if (!storeFile.exists()) {
        throw GradleException(
            "Upload keystore not found at ${storeFile.path} (storeFile in ${keystorePropertiesFile.path}).",
        )
    }
}
