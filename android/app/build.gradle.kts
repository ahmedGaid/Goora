import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Release signing. The keystore and passwords never live in the repo: key.properties is read from
// $GOORA_KEY_PROPERTIES if set (e.g. D:/Secrets/Goora/key.properties), else android/key.properties
// (gitignored). With neither present the release build is signed with the debug key, so
// `flutter build apk --release` still works for anyone. See Docs/release/SIGNING.md.
val keyPropertiesPath: String? = System.getenv("GOORA_KEY_PROPERTIES")?.takeIf { it.isNotBlank() }
val keyPropertiesFile: File = keyPropertiesPath?.let { File(it) } ?: rootProject.file("key.properties")
val hasReleaseKey = keyPropertiesFile.exists()
if (keyPropertiesPath != null && !hasReleaseKey) {
    throw GradleException("GOORA_KEY_PROPERTIES points at a file that does not exist: $keyPropertiesPath")
}
val keyProperties = Properties()
if (hasReleaseKey) {
    keyPropertiesFile.inputStream().use { keyProperties.load(it) }
}

android {
    namespace = "app.goora.goora"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // Final store id (Docs/release/DECISIONS.md D5). It cannot change after the first upload.
        applicationId = "app.goora.goora"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = 24
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (hasReleaseKey) {
            create("release") {
                // A half-filled key.properties fails loudly instead of silently debug-signing a store build.
                fun required(name: String): String =
                    keyProperties.getProperty(name)?.takeIf { it.isNotBlank() }
                        ?: throw GradleException("$name is missing in ${keyPropertiesFile.path}")
                keyAlias = required("keyAlias")
                keyPassword = required("keyPassword")
                storeFile = rootProject.file(required("storeFile"))
                storePassword = required("storePassword")
            }
        }
    }

    buildTypes {
        release {
            signingConfig = if (hasReleaseKey) {
                signingConfigs.getByName("release")
            } else {
                // No key.properties: debug-signed. Fine for local runs, rejected by the Play Store.
                signingConfigs.getByName("debug")
            }
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
