import io.github.byhook.prefab.task.GeneratePrefabTask
import org.jetbrains.kotlin.gradle.plugin.mpp.pm20.util.archivesName
import org.jetbrains.kotlin.gradle.tasks.KotlinCompile
import java.nio.file.Paths

plugins {
    alias(libs.plugins.androidLibrary)
    alias(libs.plugins.jetbrainsKotlinAndroid)
    id("io.github.byhook.prefab")
    id("maven-publish")
}

android {
    namespace = "io.github.byhook.prefab.lame"
    compileSdk = 34

    defaultConfig {
        minSdk = 21

        testInstrumentationRunner = "androidx.test.runner.AndroidJUnitRunner"
        consumerProguardFiles("consumer-rules.pro")
    }

    buildTypes {
        release {
            isMinifyEnabled = false
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        }
    }
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_1_8
        targetCompatibility = JavaVersion.VERSION_1_8
    }
    kotlinOptions {
        jvmTarget = "1.8"
    }
}

dependencies {
    implementation(libs.androidx.core.ktx)
    implementation(libs.androidx.appcompat)
    implementation(libs.material)
    testImplementation(libs.junit)
    androidTestImplementation(libs.androidx.junit)
    androidTestImplementation(libs.androidx.espresso.core)
}

generatePrefab {
    val rootBuildDir = rootProject.layout.buildDirectory
    prefabName = "lame"
    prefabVersion = "3.100.0"
    prefabArtifactDir = rootBuildDir.dir("outputs")
    prefabDir = rootBuildDir.dir("prefab-generate")
    abiList = mutableListOf("arm64-v8a", "armeabi-v7a", "x86_64", "x86")
    manifestFile = layout.projectDirectory
        .dir("src")
        .dir("main")
        .file("AndroidManifest.xml")
        .asFile
    module("lame.so", false) {
        this.libraryName = "libmp3lame"
        this.libraryFileName = "libmp3lame.so"
        this.libsDir = rootProject.layout.buildDirectory.dir("libs")
        this.includeDir = rootProject.layout.buildDirectory.dir("include")
    }
    module("lame.a", true) {
        this.libraryName = "libmp3lame"
        this.libraryFileName = "libmp3lame.a"
        this.libsDir = rootProject.layout.buildDirectory.dir("libs")
        this.includeDir = rootProject.layout.buildDirectory.dir("include")
    }
}

tasks.register<Exec>("buildPrefab") {
    val targetFile = File(project.projectDir, "build_prefab_v2.sh")
    println("buildPrefab ===========================>${targetFile.exists()}")
    commandLine = mutableListOf("bash", targetFile.absolutePath)
}

tasks.register<Copy>("packagePrefab") {
    println("packagePrefab ===========================>")
    dependsOn(tasks.withType(GeneratePrefabTask::class.java))
    val targetFile = File(rootDir, "build/outputs/lame-3.100.0.aar")
    outputs.file(targetFile.absolutePath)
}

tasks.register<Zip>("buildArtifact") {
    println("buildArtifact ===========================>")
    dependsOn(tasks.withType(GeneratePrefabTask::class.java))
    archivesName = "lame-3.100.0"
    archiveExtension = "aar"
    from(rootProject.layout.buildDirectory.dir("prefab-generate"))
    destinationDirectory = rootProject.layout.buildDirectory.dir("outputs")
}

publishing {
    publications {
        register<MavenPublication>("release") {
            groupId = "io.github.byhook"
            artifactId = "prefab-lame"
            version = "3.100.0.5"
            afterEvaluate {
                artifact(tasks.named("generatePrefabTask"))
            }
        }
    }
}