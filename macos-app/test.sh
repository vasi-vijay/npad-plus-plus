#!/usr/bin/env bash
set -e

# ==============================================================================
# NPad++ for macOS - Test Suite Execution Script
# Works on all Apple Silicon Macs (both Command Line Tools & full Xcode)
# ==============================================================================

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "${SCRIPT_DIR}"

echo "=========================================================="
echo " Running NPad++ Test Suite (Apple Silicon arm64)"
echo "=========================================================="

# 1. Auto-detect macOS SDK if available
if [ -z "${SDKROOT}" ]; then
    if command -v xcrun >/dev/null 2>&1; then
        DETECTED_SDK=$(xcrun --show-sdk-path 2>/dev/null || true)
        if [ -n "${DETECTED_SDK}" ] && [ -d "${DETECTED_SDK}" ]; then
            export SDKROOT="${DETECTED_SDK}"
        fi
    fi
fi

# 2. Check if full Xcode XCTest framework exists
HAS_XCTEST=false
if [ -d "/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/Library/Frameworks/XCTest.framework" ]; then
    HAS_XCTEST=true
fi

if [ "$1" == "--xctest" ] || [ "${HAS_XCTEST}" = true ]; then
    echo "Xcode environment detected. Running via SPM swift test..."
    swift test
    exit 0
fi

# 3. Standalone Native Runner (optimized for Apple Command Line Tools)
echo "Compiling and running standalone test suite..."
mkdir -p build/tests

SDK_FLAG=""
if [ -n "${SDKROOT}" ]; then
    SDK_FLAG="-sdk ${SDKROOT}"
fi

MODULE_CACHE_FLAG="-module-cache-path /tmp/swift-cache -Xcc -fmodules-cache-path=/tmp/clang-cache"

swiftc -O -target arm64-apple-macos14.0 ${SDK_FLAG} ${MODULE_CACHE_FLAG} \
    Sources/NotepadPlusMac/Models/FileComparisonService.swift \
    Sources/NotepadPlusMac/Models/FileTypeSupport.swift \
    Sources/NotepadPlusMac/Models/DocumentModel.swift \
    Sources/NotepadPlusMac/Models/SearchEngine.swift \
    Sources/NotepadPlusMac/Models/ProjectExplorerModel.swift \
    Sources/NotepadPlusMac/Models/PluginModel.swift \
    Sources/NotepadPlusMac/Models/PluginStore.swift \
    Sources/NotepadPlusMac/Editor/SyntaxEngine.swift \
    Sources/NotepadPlusMac/Editor/MacEditorView.swift \
    Sources/NotepadPlusMac/Views/ProjectExplorerView.swift \
    Sources/NotepadPlusMac/Views/PluginManagerView.swift \
    Sources/NotepadPlusMac/Views/DocumentationAndSupportView.swift \
    Sources/NotepadPlusMac/Views/FindDialogView.swift \
    Sources/NotepadPlusMac/Views/NativeWelcomeWindow.swift \
    Sources/NotepadPlusMac/Views/AppComponents.swift \
    Tests/StandaloneRunner.swift \
    -o build/tests/npad_test_runner

./build/tests/npad_test_runner
