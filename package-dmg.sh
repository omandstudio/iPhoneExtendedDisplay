#!/bin/bash
# ==============================================================================
# iPhone Extended Display - DMG Packaging Script
# Author: YoiKut.com (https://yoikut.com)
# Repository: https://github.com/omandstudio/iPhoneExtendedDisplay
# ==============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

APP_NAME="iPhone Extended Display"
APP_BUNDLE="${APP_NAME}.app"
DMG_NAME="iPhoneExtendedDisplay-1.0.1.dmg"
VOL_NAME="iPhone Extended Display"
STAGING_DIR="./dist_dmg"

echo "=========================================================="
echo "  📦 Packaging ${APP_NAME} into ${DMG_NAME}"
echo "  Author: YoiKut.com"
echo "=========================================================="

if [ ! -d "${APP_BUNDLE}" ]; then
    echo "⚠️  ${APP_BUNDLE} tidak ditemukan! Menjalankan build.sh terlebih dahulu..."
    ./build.sh
fi

echo "==> Menyiapkan direktori installer..."
rm -rf "${STAGING_DIR}" "${DMG_NAME}"
mkdir -p "${STAGING_DIR}"

# Salin aplikasi ke folder staging
cp -R "${APP_BUNDLE}" "${STAGING_DIR}/"

# Buat shortcut symlink ke folder /Applications (Drag-and-Drop)
ln -s /Applications "${STAGING_DIR}/Applications"

echo "==> Membuat file .dmg menggunakan hdiutil..."
hdiutil create \
    -volname "${VOL_NAME}" \
    -srcfolder "${STAGING_DIR}" \
    -ov \
    -format UDZO \
    "${DMG_NAME}"

# Bersihkan direktori staging
rm -rf "${STAGING_DIR}"

echo "=========================================================="
echo "  ✅ Berhasil! File installer siap digunakan:"
echo "     👉 ${DMG_NAME}"
echo "=========================================================="

