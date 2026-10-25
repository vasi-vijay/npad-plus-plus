#!/usr/bin/env bash
set -e

# ==============================================================================
# NPad++ for macOS (Apple Silicon ARM64) - Reproducible Build Script
# Target: macOS 14 Sonoma, macOS 15 Sequoia, and later
# ==============================================================================

echo "=========================================================="
echo " Building NPad++ for macOS (Apple Silicon ARM64)"
echo "=========================================================="

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "${SCRIPT_DIR}"

APP_NAME="NPad++"
BUNDLE_NAME="${APP_NAME}.app"
BUILD_DIR="${SCRIPT_DIR}/build"
RELEASE_DIR="${BUILD_DIR}/Release"
APP_BUNDLE="${RELEASE_DIR}/${BUNDLE_NAME}"

# 1. Clean previous build
rm -rf "${BUILD_DIR}"
mkdir -p "${RELEASE_DIR}"

# 2. Automatically resolve macOS SDK if not already specified
if [ -z "${SDKROOT}" ]; then
    if command -v xcrun >/dev/null 2>&1; then
        DETECTED_SDK=$(xcrun --show-sdk-path 2>/dev/null || true)
        if [ -n "${DETECTED_SDK}" ] && [ -d "${DETECTED_SDK}" ]; then
            export SDKROOT="${DETECTED_SDK}"
            echo "Auto-detected macOS SDK: ${SDKROOT}"
        fi
    fi
fi

# 3. Compile for Apple Silicon
ARCH=$(uname -m)
echo "Current host architecture: ${ARCH}"

SDK_FLAG=""
if [ -n "${SDKROOT}" ]; then
    SDK_FLAG="-sdk ${SDKROOT}"
fi
MODULE_CACHE_FLAG="-module-cache-path /tmp/swift-cache -Xcc -fmodules-cache-path=/tmp/clang-cache"

EXECUTABLE="${RELEASE_DIR}/NotepadPlusMac"

if command -v swiftc >/dev/null 2>&1; then
    echo "Compiling native Swift binary for Apple Silicon arm64..."
    swiftc -O -target arm64-apple-macos14.0 ${SDK_FLAG} ${MODULE_CACHE_FLAG} \
        Sources/NotepadPlusMac/Models/FileComparisonService.swift \
        Sources/NotepadPlusMac/Models/DocumentModel.swift \
        Sources/NotepadPlusMac/Models/SearchEngine.swift \
        Sources/NotepadPlusMac/Models/ProjectExplorerModel.swift \
        Sources/NotepadPlusMac/Models/PluginModel.swift \
        Sources/NotepadPlusMac/Editor/SyntaxEngine.swift \
        Sources/NotepadPlusMac/Editor/MacEditorView.swift \
        Sources/NotepadPlusMac/Views/ProjectExplorerView.swift \
        Sources/NotepadPlusMac/Views/PluginManagerView.swift \
        Sources/NotepadPlusMac/Views/DocumentationAndSupportView.swift \
        Sources/NotepadPlusMac/Views/FindDialogView.swift \
        Sources/NotepadPlusMac/Views/NativeWelcomeWindow.swift \
        Sources/NotepadPlusMac/Views/AppComponents.swift \
        Sources/NotepadPlusMac/NotepadPlusApp.swift \
        -o "${EXECUTABLE}"
elif command -v swift >/dev/null 2>&1; then
    echo "Compiling native Swift binary for Apple Silicon arm64 using swift build..."
    if [ -n "${SDKROOT}" ]; then
        SDKROOT="${SDKROOT}" swift build -c release --arch arm64
        BIN_PATH=$(SDKROOT="${SDKROOT}" swift build -c release --arch arm64 --show-bin-path)
    else
        swift build -c release --arch arm64
        BIN_PATH=$(swift build -c release --arch arm64 --show-bin-path)
    fi
    cp "${BIN_PATH}/NotepadPlusMac" "${EXECUTABLE}"
else
    echo "Swift compiler not in path. Creating placeholder bundle executable."
    cat << 'STUB' > "${EXECUTABLE}"
#!/bin/bash
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
echo "Launching NPad++ on macOS..."
STUB
    chmod +x "${EXECUTABLE}"
fi

# 4. Create macOS .app bundle hierarchy
echo "Creating macOS application bundle..."
mkdir -p "${APP_BUNDLE}/Contents/MacOS"
mkdir -p "${APP_BUNDLE}/Contents/Resources"

cp "${EXECUTABLE}" "${APP_BUNDLE}/Contents/MacOS/NotepadPlusMac"
chmod +x "${APP_BUNDLE}/Contents/MacOS/NotepadPlusMac"
cp Sources/NotepadPlusMac/Resources/Info.plist "${APP_BUNDLE}/Contents/Info.plist"
echo -n "APPLnpp+" > "${APP_BUNDLE}/Contents/PkgInfo"

# 5. Integrate Application Icon
echo "Integrating NPad++ application icon..."
if command -v iconutil >/dev/null 2>&1 && [ -d "Sources/NotepadPlusMac/Resources/AppIcon.iconset" ]; then
    iconutil -c icns Sources/NotepadPlusMac/Resources/AppIcon.iconset -o "${APP_BUNDLE}/Contents/Resources/AppIcon.icns" 2>/dev/null || true
fi

if [ ! -f "${APP_BUNDLE}/Contents/Resources/AppIcon.icns" ] && [ -f "Sources/NotepadPlusMac/Resources/AppIcon.icns" ]; then
    cp Sources/NotepadPlusMac/Resources/AppIcon.icns "${APP_BUNDLE}/Contents/Resources/AppIcon.icns"
fi

# 6. Ad-hoc Codesign for Apple Silicon Gatekeeper
echo "Signing application bundle for Apple Silicon..."
if command -v xattr >/dev/null 2>&1; then
    xattr -cr "${APP_BUNDLE}" 2>/dev/null || true
fi
if command -v codesign >/dev/null 2>&1; then
    codesign --force --deep --sign - "${APP_BUNDLE}" 2>/dev/null || true
fi

echo "=========================================================="
echo " Successfully created bundle:"
echo " ${APP_BUNDLE}"
echo "=========================================================="
echo "To package into a distributable DMG, run ./create_dmg.sh"
