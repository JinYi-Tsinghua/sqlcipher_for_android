#!/bin/sh

ANDROID_API=$1		## Android API version. Recomended 21.
SSL_ARCH=$2		## Choose from android-arm64, android-arm, android-x86, android-x86_64
SQLCIPHER_ARCH=""	## Will be set automatically
CLANG_BINARY=""		## Will be set automatically
static=1		## Set to 1 for static build, 0 for dynamic. IMPORTANT: This effects whether libcrypto.so must be included in your android build.
proxy_cmd=""
cores=8			## CPU cores

if [ "$ANDROID_NDK_HOME" = "" ]; then
	echo "ANDROID_NDK_HOME is not set. Downloading it and setting it (if not already downloaded)"
	$proxy_cmd wget --quiet -c https://dl.google.com/android/repository/android-ndk-r25b-linux.zip &&
	unzip -q -n android-ndk-r25b-linux.zip &&
	export ANDROID_NDK_HOME=$(pwd)/android-ndk-r25b/
fi

case $SSL_ARCH in
	"android-arm64")
	SQLCIPHER_ARCH="aarch64-linux-android"
	CLANG_BINARY="aarch64-linux-android$ANDROID_API-clang"
	;;
        "android-arm")
        SQLCIPHER_ARCH="arm-linux-androideabi"
	CLANG_BINARY="armv7a-linux-androideabi$ANDROID_API-clang"
        ;;
        "android-x86")
        SQLCIPHER_ARCH="i686-linux-android"
	CLANG_BINARY="i686-linux-android$ANDROID_API-clang"
        ;;
        "android-x86_64")
        SQLCIPHER_ARCH="x86_64-linux-android"
	CLANG_BINARY="x86_64-linux-android$ANDROID_API-clang"
        ;;
	*)
	echo "Error: Syntax for this shellscript is ./<script.sh> \$ANDROID_API \$SSL_ARCH. For example: ./script.sh 21 android-arm64"
	echo "Error: Valid architectures are: android-arm64, android-arm, android-x86, android-x86_64"
	exit 1
	;;
esac

export PATH=$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/linux-x86_64/bin/:$PATH
export CC=clang

########################### BELOW IS OPENSSL ##########################

rm -rf openssl &&
$proxy_cmd git clone --depth=1 -b OpenSSL_1_1_1-stable https://github.com/openssl/openssl &&
cd openssl &&

if [ "$SSL_ARCH" = "android-arm64" ] || [ "$SSL_ARCH" = "android-x86_64" ]; then
	./Configure ${SSL_ARCH} -D__ANDROID_API__=$ANDROID_API zlib-dynamic shared no-tests no-external-tests no-fuzz-libfuzzer no-fuzz-afl enable-ec_nistp_64_gcc_128
else
	./Configure ${SSL_ARCH} -D__ANDROID_API__=$ANDROID_API zlib-dynamic shared no-tests no-external-tests no-fuzz-libfuzzer no-fuzz-afl
fi

make -j$cores SHLIB_VERSION_NUMBER= SHLIB_EXT=_1_1.so build_libs &&

########################## BELOW IS SQLCIPHER #########################

export CC=$CLANG_BINARY

cd ..
rm -rf sqlcipher &&
$proxy_cmd git clone --depth=1 -b v4.5.3 https://github.com/sqlcipher/sqlcipher &&
cd sqlcipher &&

if [ $static != 0 ]; then ## Static, to point of link failure
	./configure --host=${SQLCIPHER_ARCH} LDFLAGS="../openssl/libcrypto.a -llog" CFLAGS="-DSQLITE_HAS_CODEC -DSQLCIPHER_CRYPTO_OPENSSL -I../openssl/include" --with-crypto-lib=none --enable-tempstore=yes
else ## Dynamic, to point of link failure
	./configure --host=${SQLCIPHER_ARCH} LDFLAGS="../openssl/libcrypto_1_1.so -llog" CFLAGS="-DSQLITE_HAS_CODEC -DSQLCIPHER_CRYPTO_OPENSSL -I../openssl/include" --with-crypto-lib=none --enable-tempstore=yes
fi

make -j$cores
