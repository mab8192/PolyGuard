#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NDK_PATH="/home/michael/Android/Sdk/ndk/android-ndk-r26d"
TARGET="${1:-linux}"

build_linux() {
    echo "--> Building Linux (x86_64)..."
    flatpak run --devel --command=sh org.godotengine.Godot -c "cmake -B ${SCRIPT_DIR}/build -S ${SCRIPT_DIR} -DCMAKE_BUILD_TYPE=Release && cmake --build ${SCRIPT_DIR}/build --target flowfield -j\$(nproc)"
}

build_android() {
    if [ -d "$NDK_PATH" ]; then
        echo "--> Building Android ARM64 (Release)..."
        cmake -B "${SCRIPT_DIR}/build_android_release" -S "${SCRIPT_DIR}" \
            -DCMAKE_TOOLCHAIN_FILE="${NDK_PATH}/build/cmake/android.toolchain.cmake" \
            -DANDROID_ABI=arm64-v8a \
            -DANDROID_PLATFORM=android-24 \
            -DCMAKE_BUILD_TYPE=Release
        cmake --build "${SCRIPT_DIR}/build_android_release" --target flowfield -j$(nproc)
    else
        echo "NDK path not found: $NDK_PATH"
    fi
}

build_windows() {
    if which x86_64-w64-mingw32-g++ >/dev/null 2>&1; then
        echo "--> Building Windows x86_64 (Release)..."
        cmake -B "${SCRIPT_DIR}/build_windows_release" -S "${SCRIPT_DIR}" \
            -DCMAKE_SYSTEM_NAME=Windows \
            -DCMAKE_C_COMPILER=x86_64-w64-mingw32-gcc \
            -DCMAKE_CXX_COMPILER=x86_64-w64-mingw32-g++ \
            -DCMAKE_BUILD_TYPE=Release
        cmake --build "${SCRIPT_DIR}/build_windows_release" --target flowfield -j$(nproc)
    else
        echo "MinGW compiler not found."
    fi
}

echo "=== Building FlowField GDExtension (Target: $TARGET) ==="

case "$TARGET" in
    linux)
        build_linux
        ;;
    android)
        build_android
        ;;
    windows)
        build_windows
        ;;
    all)
        build_linux
        build_android
        build_windows
        ;;
    *)
        echo "Unknown target '$TARGET'. Usage: ./build.sh [linux|android|windows|all]"
        exit 1
        ;;
esac

echo "=== Build Complete ==="
ls -lh "${SCRIPT_DIR}/bin"
