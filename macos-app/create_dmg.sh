#!/usr/bin/env bash
set -e

# ==============================================================================
# NPad++ for macOS - Distributable DMG Creator
# Creates a drag-and-drop installer disk image with single .app bundle & /Applications symlink
# ==============================================================================

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "${SCRIPT_DIR}"

APP_NAME="NPad++"
BUNDLE_NAME="${APP_NAME}.app"
DMG_NAME="NPad++.dmg"
VOLUME_NAME="NPad++"
SOURCE_APP="${SCRIPT_DIR}/build/Release/${BUNDLE_NAME}"
STAGING_DIR="${SCRIPT_DIR}/build/dmg_staging"

if [ ! -d "${SOURCE_APP}" ]; then
    echo "App bundle not found! Building app first..."
    ./build.sh
fi

# 1. Cleanly detach any previous DMG mounts to prevent duplicate mounted volumes in Finder/Spotlight
if command -v hdiutil >/dev/null 2>&1; then
    for vol in /Volumes/NPad* /Volumes/N\ Pad* /Volumes/CodePad* /Volumes/Notepad*; do
        if [ -d "${vol}" ]; then
            echo "Detaching existing volume: ${vol}..."
            hdiutil detach -force "${vol}" 2>/dev/null || true
        fi
    done
fi

# 2. Clean staging and remove old DMG artifacts
echo "Creating clean DMG staging area..."
rm -rf "${STAGING_DIR}" "${DMG_NAME}" "${SCRIPT_DIR}/build/tmp_dmg" "${SCRIPT_DIR}/N Pad++.dmg" "${SCRIPT_DIR}/CodePad.dmg" "${SCRIPT_DIR}/CodePad++.dmg"
mkdir -p "${STAGING_DIR}"

# 3. Copy exactly ONE App bundle to staging
echo "Copying ${BUNDLE_NAME} to staging..."
cp -R "${SOURCE_APP}" "${STAGING_DIR}/${BUNDLE_NAME}"

# Clear quarantine and codesign the staged app
if command -v xattr >/dev/null 2>&1; then
    xattr -cr "${STAGING_DIR}/${BUNDLE_NAME}" 2>/dev/null || true
fi
if command -v codesign >/dev/null 2>&1; then
    codesign --force --deep --sign - "${STAGING_DIR}/${BUNDLE_NAME}" 2>/dev/null || true
fi

# 4. Create symbolic link to /Applications for standard macOS drag-and-drop installer
echo "Creating /Applications shortcut symlink..."
ln -s /Applications "${STAGING_DIR}/Applications"

# 5. Enforce strict assertions on staging directory before packaging
if [ ! -L "${STAGING_DIR}/Applications" ]; then
    echo "ERROR: Staging Applications is not a symbolic link!"
    exit 1
fi
LINK_TARGET=$(readlink "${STAGING_DIR}/Applications")
if [ "${LINK_TARGET}" != "/Applications" ]; then
    echo "ERROR: Applications symlink points to '${LINK_TARGET}', expected '/Applications'!"
    exit 1
fi

APP_COUNT=$(find "${STAGING_DIR}" -maxdepth 1 -name "*.app" | wc -l | tr -d ' ')
if [ "${APP_COUNT}" -ne 1 ]; then
    echo "ERROR: Staging directory contains ${APP_COUNT} .app bundles, expected exactly 1!"
    exit 1
fi

TOTAL_APP_COUNT=$(find "${STAGING_DIR}" -name "*.app" | wc -l | tr -d ' ')
if [ "${TOTAL_APP_COUNT}" -ne 1 ]; then
    echo "ERROR: Found ${TOTAL_APP_COUNT} total .app bundles in staging hierarchy, expected exactly 1!"
    exit 1
fi

echo "  ✓ Staging verified: exactly 1 .app bundle (${BUNDLE_NAME}) and 1 /Applications symlink."

# 6. Package DMG
if command -v hdiutil >/dev/null 2>&1; then
    echo "Creating NPad++ DMG image via hdiutil..."
    hdiutil create -volname "${VOLUME_NAME}" \
                   -srcfolder "${STAGING_DIR}" \
                   -ov \
                   -format UDZO \
                   "${DMG_NAME}"

    if command -v codesign >/dev/null 2>&1; then
        codesign --force --sign - "${DMG_NAME}" 2>/dev/null || true
    fi

    echo "Verifying DMG integrity..."
    hdiutil verify "${DMG_NAME}" 2>/dev/null || true

    # 7. Mount and verify the final DMG structure
    echo "Mounting and verifying DMG structure..."
    MOUNT_OUTPUT=$(hdiutil attach "${DMG_NAME}" -nobrowse -readonly 2>&1 || true)
    MOUNT_POINT=$(echo "${MOUNT_OUTPUT}" | grep -o '/Volumes/.*' | head -n 1)

    if [ -n "${MOUNT_POINT}" ] && [ -d "${MOUNT_POINT}" ]; then
        echo "Mounted at: ${MOUNT_POINT}"
        MOUNTED_APPS=$(find "${MOUNT_POINT}" -maxdepth 1 -name "*.app" | wc -l | tr -d ' ')
        if [ "${MOUNTED_APPS}" -ne 1 ]; then
            echo "ERROR: Mounted DMG contains ${MOUNTED_APPS} .app bundles! Expected exactly 1."
            hdiutil detach -force "${MOUNT_POINT}" 2>/dev/null || true
            exit 1
        fi

        if [ ! -L "${MOUNT_POINT}/Applications" ]; then
            echo "ERROR: Mounted DMG Applications item is not a symlink!"
            hdiutil detach -force "${MOUNT_POINT}" 2>/dev/null || true
            exit 1
        fi

        echo "  ✓ Verified mounted DMG layout:"
        echo "    - Bundle:   ${MOUNT_POINT}/${BUNDLE_NAME} (single copy)"
        echo "    - Symlink:  ${MOUNT_POINT}/Applications -> /Applications"

        hdiutil detach -force "${MOUNT_POINT}" 2>/dev/null || true
    fi

    # Clean up staging directory after successful DMG creation
    rm -rf "${STAGING_DIR}"

    echo "=========================================================="
    echo " Successfully generated verified disk image:"
    echo " ${SCRIPT_DIR}/${DMG_NAME}"
    echo "=========================================================="
else
    echo "Note: hdiutil is macOS-only. Staging folder prepared at ${STAGING_DIR}."
    echo "On your Mac, execute:"
    echo "  ./create_dmg.sh"
fi
