plugins {
    id("com.android.application")
    kotlin("android")
}

android {
    namespace = "com.example.composedsl"
    compileSdk = 34

    defaultConfig {
        applicationId = "com.example.composedsl.sample"
        minSdk = 24
        targetSdk = 34
    }

    buildFeatures {
        compose = true
    }

    composeOptions {
        kotlinCompilerExtensionVersion = "1.5.1"
    }

    kotlinOptions {
        jvmTarget = "17"
    }
}

dependencies {
    implementation("androidx.activity:activity-compose:1.8.0")
    implementation("androidx.compose.material3:material3:1.1.2")
}
