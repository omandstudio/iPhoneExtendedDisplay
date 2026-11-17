#!/bin/bash
# Start-iPhoneExtendedDisplay.command
# Klik 2x file ini di Finder untuk membuka iPhone Extended Display

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$DIR"

echo "=================================================="
echo "🚀 Memulai iPhone Extended Display (omandstudio)..."
echo "=================================================="

# Jalankan aplikasi native GUI
"$DIR/iPhone Extended Display.app/Contents/MacOS/iPhone Extended Display"

