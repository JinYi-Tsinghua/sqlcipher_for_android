# sqlcipher_for_android
Bourne shellscript that builds OpenSSL and SQLCipher for Android. If you are building a C project for Android that utilizes SQLCipher, this is for you. Sets up android development environment if necessary.

Requirements: linux build system (OSX untested), internet access, wget, git, unzip

Syntax for this shellscript is ./build-sqlcipher.sh $ANDROID_API $SSL_ARCH. For example: ./build-sqlcipher.sh 21 android-arm64
Valid architectures are: android-arm64, android-arm, android-x86, android-x86_64

Outputs: libsqlcipher.so, etc

NOTE: By default it statically builds in libcrypto from OpenSSL. If you want this linkage to be dynamic (so you will have to also include libcrypto.so in your android APK), modify the shellscript to change static=1 to static=0.
