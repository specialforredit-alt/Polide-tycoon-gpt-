plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
}
android {
    namespace = "com.police.tycoon"
    compileSdk = 35
    defaultConfig {
        applicationId = "com.police.tycoon"
        minSdk = 23
        targetSdk = 34
        versionCode = 1
        versionName = "1.0"
    }
}
