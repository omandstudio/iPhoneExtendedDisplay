# 📋 Changelog

Semua perubahan penting pada proyek **iPhone Extended Display** dicatat di dokumen ini.

Format changelog ini mengacu pada [Keep a Changelog](https://keepachangelog.com/id/1.0.0/) dan menganut [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [1.0.2] - 2026-11-18

### Ditambahkan (Added)
- **Ikon Aplikasi Resmi macOS-iPhone (`AppIcon.icns`)**:
  - Penambahan ikon grafis resmi bergaya *macOS squircle* beresolusi tinggi (Retina hingga 1024x1024) yang menggambarkan MacBook terhubung dengan iPhone melalui transmisi energi bercahaya.
  - Pemasangan otomatis ikon pada bundle aplikasi `.app`, jendela kontrol pop-up, serta installer `.dmg`.
- **Manajemen Mulai Otomatis (Launch at Startup/Login)**:
  - Aplikasi secara bawaan (*default*) berstatus **Nonaktif** saat macOS baru pertama kali dinyalakan untuk menghemat baterai dan memori.
  - Penambahan toggle switch di jendela pengaturan pop-up untuk mematikan atau mengaktifkan fitur buka otomatis saat login.
- **Tombol Matikan & Keluar Aplikasi (Power Management)**:
  - Penambahan tombol khusus berwarna merah **"Matikan & Keluar Aplikasi"** pada jendela kontrol pop-up untuk menghentikan server dan menutup aplikasi secara instan dan bersih.
  - Penambahan tombol **"Jeda Layanan / Aktifkan Layanan"** untuk menghentikan sementara penyiaran tanpa menutup aplikasi.
  - Penyesuaian `applicationShouldTerminateAfterLastWindowClosed = true` sehingga menutup jendela pop-up (tombol merah X) otomatis mematikan aplikasi seutuhnya.
- **Pendeteksi Proses Cerdas pada [Start-iPhoneExtendedDisplay.command](Start-iPhoneExtendedDisplay.command)**:
  - Kemampuan mendeteksi instans aplikasi yang sedang berjalan dengan opsi menu Terminal untuk mematikan proses, memunculkan kembali jendela pop-up, atau keluar.

### Diubah (Changed)
- Peningkatan versi aplikasi dan bundle identitas menjadi `1.0.2` (Build 3).
- Pembaruan paket installer mandiri menjadi `iPhoneExtendedDisplay-1.0.2.dmg`.

---

## [1.0.1] - 2026-11-17

### Ditambahkan (Added)
- **Paket Distribusi .DMG Mandiri**:
  - Penyediaan installer berekstensi `.dmg` (`iPhoneExtendedDisplay-1.0.1.dmg`) dengan shortcut ke folder `/Applications` untuk instalasi *drag-and-drop* tanpa Terminal.
  - Skrip pengemasan lokal `package-dmg.sh` berbasis utilitas native macOS `hdiutil`.
  - Otomasi alur kerja CI/CD GitHub Actions (`.github/workflows/release.yml`) dengan trigger `release: [published]` dan `permissions: contents: write` untuk pembuatan dan unggah otomatis aset `.dmg` ke GitHub Releases.

### Diubah (Changed)
- Koreksi tautan repositori resmi menjadi `https://github.com/omandstudio/iPhoneExtendedDisplay`.
- Penyempurnaan dokumentasi README menjadi bilingual (English & Bahasa Indonesia) dengan format redaksional yang bersih dan rapi tanpa emoji pada penunjuk poin.
- Pembaruan versi aplikasi dan bundle identitas menjadi `1.0.1`.

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
  - Skrip build otomatis `build.sh` untuk kompilasi dan pembuatan bundle `.app` mandiri.
  - Peluncur 1-klik `Start-iPhoneExtendedDisplay.command` untuk pengguna non-teknis.
  - Template isu GitHub (Bug Report & Feature Request).
  - Dokumentasi instalasi, penggunaan, dan uninstalasi lengkap.

---

Dikembangkan dengan ❤️ oleh **[YoiKut.com](https://yoikut.com)**.

