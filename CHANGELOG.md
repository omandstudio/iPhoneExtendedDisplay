# 📋 Changelog

Semua perubahan penting pada proyek **iPhone Extended Display** dicatat di dokumen ini.

Format changelog ini mengacu pada [Keep a Changelog](https://keepachangelog.com/id/1.0.0/) dan menganut [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [1.0.0] - 2026-11-17

### 🎉 Rilis Perdana (Initial Release)
Rilis publik pertama dari **iPhone Extended Display** oleh **YoiKut.com** ([omandstudio/iPhoneExtendedDisplay](https://github.com/omandstudio/iPhoneExtendedDisplay)).

### ✨ Fitur Baru
- **Native macOS Control Window**:
  - Tampilan antarmuka grafis minimalis dan modern berbasis SwiftUI & AppKit.
  - Pemantau status server secara *real-time* (Aktif/Nonaktif, Port 8080 & 7789).
  - Tampilan alamat IP aktif secara otomatis (Kabel USB `192.168.2.1` dan Wi-Fi lokal).
  - Tombol 1-klik untuk menyalin URL akses (`Copy URL`).
  - Pemilih Frame Rate dinamis: **60 FPS** (Ultra Halus) & **30 FPS** (Hemat Daya).
  - Pengalih mode display: **Extended Monitor** (Layar Tambahan) & **Mirror Display** (Duplikasi Layar).
  - Footer informasi repositori resmi dan identitas aplikasi.

- **Dual-Pipeline Screen Capture Engine**:
  - Dukungan utama menggunakan Apple **ScreenCaptureKit** (macOS 12.3+) dengan akselerasi hardware Metal/GPU.
  - Fallback otomatis ke **CoreGraphics Display Stream API** untuk kompatibilitas macOS terdahulu.
  - Proteksi deteksi izin privasi macOS (*TCC Screen Recording Preflight check*) untuk mencegah crash saat izin belum diberikan.

- **Zero-Latency USB Streaming**:
  - Mengalirkan frame monitor melalui kabel Lightning / USB-C berkecepatan tinggi via virtual Ethernet bridge (`192.168.2.1`).
  - Latensi super rendah (< 16ms pada 60 FPS) tanpa lag.

- **Zero-Install Client (iOS Web App)**:
  - Tidak memerlukan instalasi aplikasi tambahan dari App Store pada iPhone/iPad.
  - Cukup dibuka melalui browser bawaan **Safari** di iOS (`http://192.168.2.1:8080`).
  - Dukungan penuh mode PWA (*Progressive Web App* / *Add to Home Screen*) untuk tampilan 100% fullscreen *edge-to-edge* tanpa bilah alamat atau navigasi browser.
  - Antarmuka web cerdas dengan fitur **Auto-Hide Control Bar**: badge FPS dan tombol aksi otomatis tersembunyi setelah 2 detik agar tidak menutupi konten monitor.
  - Tombol trigger gear (`⚙`) minimalis semi-transparan untuk memanggil kembali kontrol kapan saja.

- **Interactive Touch-to-Mouse Relay**:
  - Mengirimkan sentuhan layar (tap, drag, scroll) dari iPhone ke macOS melalui WebSocket berlatensi rendah.
  - Simulasi kursor dan event klik native macOS via `CGEvent`.

- **Standard GitHub & Developer Tools**:
  - **Standalone .DMG Drag-and-Drop Installer**:
    - Penyediaan installer mandiri berekstensi **`.dmg`** (`iPhoneExtendedDisplay-1.0.0.dmg`) dengan tautan pintasan ke folder `/Applications` untuk instalasi grafis cepat tanpa Terminal.
    - Skrip pengemasan lokal `package-dmg.sh` memanfaatkan utilitas native macOS `hdiutil`.
    - Otomasi CI/CD **GitHub Actions** (`.github/workflows/release.yml`) untuk kompilasi cloud dan publikasi otomatis aset `.dmg` ke GitHub Releases saat membuat tag versi.
  - Skrip build otomatis `build.sh` untuk kompilasi dan pembuatan bundle `.app` mandiri.
  - Peluncur 1-klik `Start-iPhoneExtendedDisplay.command` untuk pengguna non-teknis.
  - Template isu GitHub (Bug Report & Feature Request).
  - Dokumentasi instalasi, penggunaan, dan uninstalasi lengkap.

---

Dikembangkan dengan ❤️ oleh **[YoiKut.com](https://yoikut.com)**.

