import io.github.byhook.prefab.extension.PrefabLibraryType
import org.jetbrains.kotlin.fir.declarations.builder.buildScript

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

val targetAbiList by lazy {
    mutableListOf("arm64-v8a", "armeabi-v7a", "x86_64", "x86")
}

tasks.register<Exec>("crossCompile") {
    //配置环境变量-设置构建目标的abi列表
    environment["TARGET_ABI_LIST"] = targetAbiList.joinToString(" ")
    //指定NDK版本，例如：25.2.9519653 / 22.1.7171670
    environment["NDK_VERSION"] = targetAbiList.joinToString("22.1.7171670")
    //直接交叉编译脚本
    val targetFile = File(project.projectDir, "build_lame.sh")
    commandLine = mutableListOf("bash", targetFile.absolutePath)
}

generatePrefab {
    //前置依赖交叉构建完成
    dependsOn("crossCompile")
    //配置基础信息
    val rootBuildDir = rootProject.layout.buildDirectory
    //交叉编译生成的库目录
    sourceLibsDir = rootBuildDir.dir("libs").get()
    //交叉编译生成的头文件目录
    sourceIncsDir = rootBuildDir.dir("include").get()
    //生成预构建库的临时目录
    prefabBuildDir = rootBuildDir.dir("prefab-build").get()
    //最终打包完整的aar文件的产物目录
    prefabArtifactDir = rootBuildDir.dir("prefab-artifact").get()
    //指定预构建库的名字
    prefabName = "lame"
    //指定预构建库的版本号
    prefabVersion = "3.100.0"
    //预构建库支持abi的列表
    abiList = targetAbiList
    //生成的aar文件里包含的清单文件
    manifestFile = layout.projectDirectory
        .dir("src")
        .dir("main")
        .file("AndroidManifest.xml")
        .asFile
    //包含的库详情
    module("lame", "mp3lame", PrefabLibraryType.ALL) {
        includeSubDirName = "lame"
    }
}

publishing {
    publications {
        register<MavenPublication>("release") {
            groupId = "io.github.byhook"
            artifactId = "prefab-lame"
            version = "3.100.0.7"
            afterEvaluate {
                artifact(tasks.named("generatePrefabTask"))
            }
        }
    }
}