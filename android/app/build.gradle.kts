import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    // Add the Google services Gradle plugin
    id("com.google.gms.google-services") version "4.4.2"
}

// Resolve FACEBOOK_APP_ID from, in order of precedence:
// 1) Gradle property -PFACEBOOK_APP_ID, 2) local.properties, 3) env var, 4) fallback to empty
val resolvedFacebookAppId: String by lazy {
    // Check Gradle property
    val fromGradleProp = project.findProperty("FACEBOOK_APP_ID") as String?

    // Check local.properties
    val localProps = Properties()
    val localPropsFile = rootProject.file("local.properties")
    if (localPropsFile.exists()) {
        localPropsFile.inputStream().use { localProps.load(it) }
    }
    val fromLocal = localProps.getProperty("FACEBOOK_APP_ID")

    // Check environment
    val fromEnv = System.getenv("FACEBOOK_APP_ID")

    (fromGradleProp ?: fromLocal ?: fromEnv ?: "").trim()
}

android {
    namespace = "com.example.farm_agro_tech"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.harshal.farmagrotech"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = 23
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        // Inject Facebook App ID as Android string resources at build time
        resValue("string", "facebook_app_id", resolvedFacebookAppId)
        val fbScheme = if (resolvedFacebookAppId.isNotEmpty()) "fb$" + resolvedFacebookAppId else ""
        resValue("string", "fb_login_protocol_scheme", fbScheme)
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
    // Import the Firebase BoM
    implementation(platform("com.google.firebase:firebase-bom:32.7.0"))
    // Add the dependencies for Firebase products you want to use
    implementation("com.google.firebase:firebase-analytics")
    implementation("com.google.firebase:firebase-auth")
    
    // Core library desugaring for flutter_local_notifications
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
}
