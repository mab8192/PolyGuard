#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NDK_PATH="/home/michael/Android/Sdk/ndk/android-ndk-r26d"

echo "=== Building FlowField GDExtension ==="

# 1. Linux x86_64
echo "--> Building Linux (x86_64)..."
flatpak run --devel --command=sh org.godotengine.Godot -c "cmake -B ${SCRIPT_DIR}/build -S ${SCRIPT_DIR} -DCMAKE_BUILD_TYPE=Release && cmake --build ${SCRIPT_DIR}/build -j\$(nproc)"

# 2. Android ARM64 (Debug & Release with 16KB alignment)
if [ -d "$NDK_PATH" ]; then
    echo "--> Building Android ARM64 (Debug)..."
    cmake -B "${SCRIPT_DIR}/build_android_debug" -S "${SCRIPT_DIR}" \
        -DCMAKE_TOOLCHAIN_FILE="${NDK_PATH}/build/cmake/android.toolchain.cmake" \
        -DANDROID_ABI=arm64-v8a \
        -DANDROID_PLATFORM=android-24 \
        -DCMAKE_BUILD_TYPE=Debug
    cmake --build "${SCRIPT_DIR}/build_android_debug" -j$(nproc)

    echo "--> Building Android ARM64 (Release)..."
    cmake -B "${SCRIPT_DIR}/build_android_release" -S "${SCRIPT_DIR}" \
        -DCMAKE_TOOLCHAIN_FILE="${NDK_PATH}/build/cmake/android.toolchain.cmake" \
        -DANDROID_ABI=arm64-v8a \
        -DANDROID_PLATFORM=android-24 \
        -DCMAKE_BUILD_TYPE=Release
    cmake --build "${SCRIPT_DIR}/build_android_release" -j$(nproc)
fi

# 3. Windows x86_64 (MinGW)
if which x86_64-w64-mingw32-g++ >/dev/null 2>&1; then
    echo "--> Building Windows x86_64 (Debug)..."
    cmake -B "${SCRIPT_DIR}/build_windows_debug" -S "${SCRIPT_DIR}" \
        -DCMAKE_SYSTEM_NAME=Windows \
        -DCMAKE_C_COMPILER=x86_64-w64-mingw32-gcc \
        -DCMAKE_CXX_COMPILER=x86_64-w64-mingw32-g++ \
        -DCMAKE_BUILD_TYPE=Debug
    cmake --build "${SCRIPT_DIR}/build_windows_debug" -j$(nproc)

    echo "--> Building Windows x86_64 (Release)..."
    cmake -B "${SCRIPT_DIR}/build_windows_release" -S "${SCRIPT_DIR}" \
        -DCMAKE_SYSTEM_NAME=Windows \
        -DCMAKE_C_COMPILER=x86_64-w64-mingw32-gcc \
        -DCMAKE_CXX_COMPILER=x86_64-w64-mingw32-g++ \
        -DCMAKE_BUILD_TYPE=Release
    cmake --build "${SCRIPT_DIR}/build_windows_release" -j$(nproc)
fi

echo "=== All Available Targets Compiled Successfully ==="
ls -lh "${SCRIPT_DIR}/bin"
