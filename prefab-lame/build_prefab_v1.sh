#!/bin/sh

# Check out the source.

#参考文档
#https://developer.android.com/studio/build/native-dependencies?hl=zh-cn&buildsystem=ndk-build

bash build_lame.sh

#库名称：lib${LIB_NAME}.so
LIB_NAME=lame
#版本号：必须全数字
LIB_VERSION=3.100.0

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
  SUFFIX_NAME=$2

  TARGET_ANDROID_ABI_DIR=$TARGET_PREFAB_DIR/modules/$LIB_NAME/libs/android.$TARGET_ABI
  mkdir -p $TARGET_ANDROID_ABI_DIR

  # 复制目标文件
  cp $TARGET_BUILD_DIR/libs/$TARGET_ABI/*.$SUFFIX_NAME \
      $TARGET_ANDROID_ABI_DIR/lib$LIB_NAME.$SUFFIX_NAME

  # 生成abi.json文件
  # 配置目录 prefab/modules/$libName/libs/android.$abi/abi.json
  pushd $TARGET_ANDROID_ABI_DIR
  echo "{
    \"abi\":\"$TARGET_ABI\",
    \"api\":21,
    \"ndk\":21,
    \"stl\":\"c++_shared\"
    }" >$TARGET_ANDROID_ABI_DIR/abi.json
  popd
}

function generate_module_headers {
  # 复制头文件
  cp -R $TARGET_BUILD_DIR/include $TARGET_PREFAB_DIR/modules/$LIB_NAME

  # 生成module.json文件
  # 配置目录 prefab/modules/$libName/module.json
  pushd $TARGET_PREFAB_DIR/modules/$LIB_NAME
  echo "{
    \"export_libraries\": [],
    \"library_name\": null,
    \"android\": {
      \"export_libraries\": [],
      \"library_name\": null
    }
    }" >module.json
  popd
}

function generate_prefab {
  mkdir -p $TARGET_PREFAB_DIR/modules/$LIB_NAME

  # 生成prefab.json文件
  # 配置目录 prefab/prefab.json
  echo "{
    \"schema_version\": 1,
    \"name\": \"$LIB_NAME\",
    \"version\": \"$LIB_VERSION\",
    \"dependencies\": []
    }" >$TARGET_PREFAB_DIR/prefab.json

  # 复制清单文件
  cp $MANIFEST_PATH $TARGET_ROOT_PREFAB_DIR/AndroidManifest.xml
}

function package_library {
  #删除冗余的文件
  find . -name ".DS_Store" -delete

  echo 当前目录是：""$(pwd)

  zip -r output.aar . 2>/dev/null
  zip -Tv output.aar 2>/dev/null

  # Verify that the aar contents are correct (see output below to verify)
  result=$?
  if [[ $result == 0 ]]; then
    echo "aar verified"
  else
    echo "aar verification failed"
    exit 1
  fi

  mkdir -p ../outputs
  mv output.aar ../outputs/$LIB_NAME-$LIB_VERSION.aar
}

# 进入build-prefab目录

pushd $TARGET_ROOT_PREFAB_DIR

generate_prefab

generate_module_headers

for abi in ${ABIS[@]}; do
  copy_libs $abi so
  #copy_libs $abi a
done

package_library

popd
