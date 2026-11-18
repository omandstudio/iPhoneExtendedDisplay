#!/bin/bash
# ==============================================================================
# Start-iPhoneExtendedDisplay.command
# Peluncur 1-Klik macOS Finder (omandstudio)
# ==============================================================================

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$DIR"

echo "=================================================="
echo "📱 iPhone Extended Display (omandstudio)"
echo "=================================================="

APP_PATH="$DIR/iPhone Extended Display.app"
BIN_NAME="iPhone Extended Display"

# Periksa apakah aplikasi saat ini sedang berjalan
APP_PID=$(pgrep -f "Contents/MacOS/${BIN_NAME}" || true)

if [ -n "$APP_PID" ]; then
    echo "⚠️  Aplikasi saat ini SUDAH BERJALAN (PID: $APP_PID)."
    echo ""
    echo "Pilih opsi yang ingin Anda lakukan:"
    echo "  [1] Matikan / Hentikan aplikasi sekarang"
    echo "  [2] Buka / Munculkan kembali jendela pop-up pengaturan"
    echo "  [3] Keluar dari terminal ini"
    echo ""
    read -p "Masukkan pilihan Anda [1/2/3]: " PILIHAN
    case "$PILIHAN" in
        1)
            echo "Menghentikan aplikasi iPhone Extended Display..."
            kill -TERM "$APP_PID" 2>/dev/null || kill -9 "$APP_PID" 2>/dev/null
            echo "✅ Aplikasi berhasil dimatikan."
            sleep 1
            exit 0
            ;;
        2)
            echo "Mengaktifkan jendela pengaturan..."
            open "$APP_PATH"
            echo "✅ Jendela pengaturan telah dimunculkan."
            sleep 1
            exit 0
            ;;
        *)
            exit 0
            ;;
    esac
fi

echo "🚀 Menjalankan iPhone Extended Display..."
open "$APP_PATH"

echo "✅ Aplikasi berhasil dijalankan!"
echo ""
echo "💡 PETUNJUK:"
echo "   - Jendela pop-up kontrol pengaturan telah muncul di layar Mac Anda."
echo "   - Untuk MEMATIKAN aplikasi: klik tombol merah 'Matikan & Keluar Aplikasi' di jendela pop-up,"
echo "     atau cukup tutup jendela tersebut (tombol merah X)."
echo "   - Aplikasi ini secara bawaan TIDAK AKAN berjalan saat Mac baru menyala (hemat daya & memori)."
echo "=================================================="
sleep 2
exit 0
