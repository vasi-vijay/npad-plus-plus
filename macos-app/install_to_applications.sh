#!/usr/bin/env bash
set -e

# ==============================================================================
# NPad++ Clean Installation Script for macOS Applications Folder
# Removes any old or stale application copies, installs the fresh Apple Silicon build,
# updates ad-hoc signatures, and forces LaunchServices to refresh.
# ==============================================================================

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "${SCRIPT_DIR}"

APP_NAME="NPad++"
BUNDLE_NAME="${APP_NAME}.app"
SOURCE_APP="${SCRIPT_DIR}/build/Release/${BUNDLE_NAME}"
DEST_APP="/Applications/${BUNDLE_NAME}"

echo "=========================================================="
echo " Installing NPad++ to /Applications (Apple Silicon arm64)"
echo "=========================================================="

# 1. Terminate running instances
echo "Terminating any existing NPad++ processes..."
pkill -9 -f NotepadPlusMac 2>/dev/null || true
pkill -9 -f "NPad++" 2>/dev/null || true
pkill -9 -f "N Pad++" 2>/dev/null || true
pkill -9 -f "CodePad++" 2>/dev/null || true
sleep 1

# 2. Check if freshly built app exists, or build it
if [ ! -d "${SOURCE_APP}" ]; then
    echo "Fresh build not found, building NPad++ now..."
    ./build.sh
fi

# 3. Remove old versions from /Applications
echo "Removing old application from /Applications..."
rm -rf "${DEST_APP}" "/Applications/N Pad++.app" /Applications/CodePad++.app /Applications/CodePad.app /Applications/Notepad++.app 2>/dev/null || true

# 4. Copy new build into /Applications
echo "Installing new version into ${DEST_APP}..."
cp -R "${SOURCE_APP}" "${DEST_APP}"

# 5. Clear quarantine and re-sign
if command -v xattr >/dev/null 2>&1; then
    xattr -cr "${DEST_APP}" 2>/dev/null || true
fi
if command -v codesign >/dev/null 2>&1; then
    codesign --force --deep --sign - "${DEST_APP}" 2>/dev/null || true
fi

# 6. Re-register with macOS LaunchServices
LSREGISTER="/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister"
if [ -x "${LSREGISTER}" ]; then
    echo "Refreshing macOS LaunchServices database..."
    "${LSREGISTER}" -f "${DEST_APP}" 2>/dev/null || true
fi

touch "${DEST_APP}"

echo "=========================================================="
echo " Successfully installed ${APP_NAME} to ${DEST_APP}!"
echo "=========================================================="
