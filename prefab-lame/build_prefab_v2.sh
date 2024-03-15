#!/bin/sh

#参考文档
#https://developer.android.com/studio/build/native-dependencies?hl=zh-cn&buildsystem=ndk-build

bash build_lame.sh

#库名称：lib${LIB_NAME}.so
LIB_NAME=lame
#版本号：必须全数字
LIB_VERSION=3.100.0

#相关版本号配置
MIN_ABI=21
NDK_VERSION=25

ABIS=("arm64-v8a" "armeabi-v7a" "x86_64" "x86")

TARGET_BUILD_DIR=$(pwd)/../build

TARGET_ROOT_PREFAB_DIR=$(pwd)/../build/prefab-lame

rm -rf $TARGET_ROOT_PREFAB_DIR

TARGET_PREFAB_DIR=$TARGET_ROOT_PREFAB_DIR/prefab
mkdir -p $TARGET_PREFAB_DIR

#拷贝清单文件
MANIFEST_PATH=$(pwd)/src/main/AndroidManifest.xml

function copy_libs {
    TARGET_ABI=$1
    SUFFIX_NAME=$2  #后缀名
    STATIC=$3

    TARGET_ANDROID_ABI_DIR=$TARGET_PREFAB_DIR/modules/$LIB_NAME.$SUFFIX_NAME/libs/android.$TARGET_ABI
    mkdir -p $TARGET_ANDROID_ABI_DIR

    # 复制目标文件
    cp $TARGET_BUILD_DIR/libs/$TARGET_ABI/*.$SUFFIX_NAME \
      $TARGET_ANDROID_ABI_DIR/lib$LIB_NAME.$SUFFIX_NAME

    echo "TARGET_ABI => "$TARGET_BUILD_DIR/libs/$TARGET_ABI
    echo "TARGET_ANDROID_ABI_DIR => "$TARGET_ANDROID_ABI_DIR

    # 生成abi.json文件
    # 配置目录 prefab/modules/$libName/libs/android.$abi/abi.json
    pushd $TARGET_ANDROID_ABI_DIR
    echo "{
    \"abi\":\"$TARGET_ABI\",
    \"api\":$MIN_ABI,
    \"ndk\":$NDK_VERSION,
    \"stl\":\"c++_shared\",
    \"static\": $STATIC
    }" > $TARGET_ANDROID_ABI_DIR/abi.json
    popd
}

function generate_module_json {
    SUFFIX_NAME=$1
    # 生成module.json文件
    # 配置目录 prefab/modules/$libName/module.json
    pushd $TARGET_PREFAB_DIR/modules/$LIB_NAME.$SUFFIX_NAME
    echo "{
    \"export_libraries\": [],
    \"android\": {
      \"library_name\": \"lib$LIB_NAME\",
      \"export_libraries\": []
    }
    }" > module.json
    popd
}

function copy_so_libs {
    #生成目标目录
    CURRENT_LIB_DIR=$TARGET_PREFAB_DIR/modules/$LIB_NAME.so
    mkdir -p $CURRENT_LIB_DIR
    #生成目标module.json配置
    generate_module_json so
    #拷贝头文件
    cp -R $TARGET_BUILD_DIR/include $CURRENT_LIB_DIR
    #拷贝库文件
    for abi in ${ABIS[@]}
    do
        copy_libs $abi so false
    done
}

function copy_a_libs {
    #生成目标目录
    CURRENT_LIB_DIR=$TARGET_PREFAB_DIR/modules/$LIB_NAME.a
    mkdir -p $CURRENT_LIB_DIR
    #生成目标module.json配置
    generate_module_json a
    #拷贝头文件
    cp -R $TARGET_BUILD_DIR/include $CURRENT_LIB_DIR
    #拷贝库文件
    for abi in ${ABIS[@]}
    do
        copy_libs $abi a true
    done
}

function generate_prefab {
    # 生成prefab.json文件
    # 配置目录 prefab/prefab.json
    echo "{
    \"schema_version\": 2,
    \"name\": \"$LIB_NAME\",
    \"version\": \"$LIB_VERSION\",
    \"dependencies\": []
    }" > $TARGET_PREFAB_DIR/prefab.json

    # 复制清单文件
    cp $MANIFEST_PATH $TARGET_ROOT_PREFAB_DIR/AndroidManifest.xml
}

function package_library {
    #删除冗余的文件
    find . -name ".DS_Store" -delete

    zip -r output.aar . 2>/dev/null;
    zip -Tv output.aar 2>/dev/null;

    # Verify that the aar contents are correct (see output below to verify)
    result=$?; if [[ $result == 0 ]]; then
        echo "aar verified"
    else
        echo "aar verification failed"
        exit 1
    fi

    mkdir -p ../outputs
    mv output.aar ../outputs/$LIB_NAME-$LIB_VERSION.aar
}

# 进入prefab-lame目录

pushd $TARGET_ROOT_PREFAB_DIR

#生成基础配置和清单文件
generate_prefab

#拷贝动态库
copy_so_libs
#拷贝静态库
copy_a_libs

#打包库文件
package_library

popd
