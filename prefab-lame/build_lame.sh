#!/bin/sh

CURRENT_DIR=$(pwd)
BUILD_DIR=$CURRENT_DIR/build
SOURCE_CODE_DIR=$BUILD_DIR/lame-3.100

if [ "`ls -A $SOURCE_CODE_DIR`" = "" ]; then
    echo "$SOURCE_CODE_DIR is empty"
    rm -rf $SOURCE_CODE_DIR
    mkdir -p $SOURCE_CODE_DIR
    # 克隆代码到build目录下
    git clone https://github.com/open-source-mirrors/lame.git -b 3.100 $SOURCE_CODE_DIR
else
    echo "$SOURCE_CODE_DIR is not empty"
fi

cd $SOURCE_CODE_DIR

function build_library {
    ABI=$1
    HOST=$2
    
    BUILD_DIR=$CURRENT_DIR/../build/
    mkdir -p $BUILD_DIR
    
    export CFLAGS="-fPIE -fPIC"
    export LDFLAGS="-pie"

    make clear
    
    ./configure \
    --host=$HOST \
    --prefix=$BUILD_DIR \
    --bindir=$BUILD_DIR/bin \
    --libdir=$BUILD_DIR/libs/$ABI \
    --disable-frontend \
    --enable-shared=yes \
    --enable-static=yes
    
    #构建并安装
    make -j4 install
    #去掉符号信息
    $STRIP -s $BUILD_DIR/libs/$ABI/libmp3lame.so
}

#ABI_LIST=("arm64-v8a" "armeabi-v7a" "x86_64" "x86")
#HOST_LIST=("aarch64-linux-android" "armv7a-linux-androideabi" "x86_64-linux-android" "i686-linux-android")

ABI_LIST="arm64-v8a armeabi-v7a x86_64 x86"
abiArray=(${ABI_LIST// / })

for currentAbi in ${abiArray[@]}
do
   echo $currentAbi
   source $CURRENT_DIR/../setup-ndk-env.sh $currentAbi
   build_library $currentAbi $TOOL_NAME_BASE
done