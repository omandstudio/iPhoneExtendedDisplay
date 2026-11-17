# 📱 iPhone Extended Display

[![macOS](https://img.shields.io/badge/macOS-12.0%2B-black?logo=apple)](https://apple.com)
[![iOS](https://img.shields.io/badge/iOS-12.0%2B-blue?logo=apple)](https://apple.com)
[![Version](https://img.shields.io/badge/version-1.0.0-green.svg)](https://github.com/omandistudio/iPhoneExtendedDisplay)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Author](https://img.shields.io/badge/author-YoiKut.com-orange.svg)](https://yoikut.com)

Aplikasi standar native macOS profesional untuk menjadikan **iPhone dan iPad** sebagai **Monitor Tambahan (Extended Display)** atau **Duplikasi Layar (Mirror Display)** bagi Mac Anda, baik melalui **Kabel USB (Latensi Nol)** maupun **Nirkabel (Wi-Fi)**, tanpa batasan perangkat keras Apple Sidecar.

> Dikembangkan & dikelola secara resmi oleh **[YoiKut.com](https://yoikut.com)**  
> Repositori GitHub: **[omandistudio/iPhoneExtendedDisplay](https://github.com/omandistudio/iPhoneExtendedDisplay)**

---

## 📑 Daftar Isi
- [✨ Fitur Unggulan](#-fitur-unggulan)
- [💻 Kebutuhan Sistem](#-kebutuhan-sistem)
- [📥 Panduan Instalasi](#-panduan-instalasi)
  - [Metode 1: Menjalankan Aplikasi Jadi (.app)](#metode-1-menjalankan-aplikasi-jadi-app)
  - [Metode 2: Kompilasi Mandiri dari Source Code (build.sh)](#metode-2-kompilasi-mandiri-dari-source-code-buildsh)
- [🔒 Pengaturan Izin macOS (Wajib)](#-pengaturan-izin-macos-wajib)
- [📱 Panduan Penggunaan](#-panduan-penggunaan)
  - [1. Menggunakan Kabel USB (Rekomendasi - Latensi Nol)](#1-menggunakan-kabel-usb-rekomendasi---latensi-nol)
  - [2. Menggunakan Jaringan Wi-Fi (Nirkabel)](#2-menggunakan-jaringan-wi-fi-nirkabel)
  - [3. Trik Tampilan Penuh 100% Layar (Edge-to-Edge Fullscreen)](#3-trik-tampilan-penuh-100-layar-edge-to-edge-fullscreen)
- [🗑️ Panduan Uninstalasi](#️-panduan-uninstalasi)
  - [Menghapus Aplikasi dari macOS](#menghapus-aplikasi-dari-macos)
  - [Membersihkan Izin Sistem macOS](#membersihkan-izin-sistem-macos)
  - [Menghapus Web App dari iPhone / iPad](#menghapus-web-app-dari-iphone--ipad)
- [❓ FAQ & Troubleshooting](#-faq--troubleshooting)
- [📂 Struktur Repositori](#-struktur-repositori)
- [📄 Lisensi & Kontribusi](#-lisensi--kontribusi)

---

## ✨ Fitur Unggulan

- 🖥️ **Native Control Window (AppKit & SwiftUI)**:
  Jendela kontrol minimalis dan modern di macOS untuk memantau status streaming real-time, melihat IP aktif, menyalin URL sekali klik, serta mengatur frame rate (30 / 60 FPS).
- ⚡ **Dua Mode Tampilan**:
  - **Extended Display (Layar Tambahan)**: Berfungsi sebagai monitor kedua mandiri untuk memperluas ruang kerja multitasking Anda.
  - **Mirror Display (Duplikasi Layar)**: Menduplikasi tampilan layar utama Mac ke iPhone.
- 🔌 **Koneksi Kabel USB Berkecepatan Tinggi**:
  Memanfaatkan tethering virtual bridge Ethernet bawaan macOS & iOS untuk mengalirkan frame hingga 60 FPS dengan latensi mendekati 0ms (tanpa lag kursor).
- 📶 **Koneksi Nirkabel Wi-Fi**:
  Bekerja secara nirkabel di dalam jaringan Wi-Fi lokal yang sama tanpa perlu kabel.
- 📲 **Zero-Install di iPhone (Tanpa Aplikasi App Store)**:
  Cukup buka browser bawaan **Safari** di iPhone atau iPad. Tidak perlu mendaftar Apple Developer Account atau menginstal aplikasi pihak ketiga di iOS.
- 🔲 **Tampilan Fullscreen Tanpa Batas (PWA)**:
  Mendukung fitur iOS *Add to Home Screen* untuk menghilangkan URL bar dan bilah tab Safari, memberikan pengalaman monitor sejati 100% edge-to-edge.
- 👁️ **Smart Auto-Hide HUD**:
  Badge FPS dan tombol aksi kontrol di iPhone otomatis menyembunyikan diri dalam 2 detik agar tidak menutupi tampilan layar kerja Anda.
- 🖱️ **Relay Sentuhan Interaktif (Touch-to-Mouse)**:
  Sentuhan jari di layar iPhone diteruskan secara instan sebagai kontrol kursor dan klik pada Mac Anda.

---

## 💻 Kebutuhan Sistem

### macOS (Host Mac):
- **Sistem Operasi**: macOS 12.0 Monterey, macOS 13 Ventura, macOS 14 Sonoma, macOS 15+ Sequoia.
- **Arsitektur**: Mendukung penuh **Apple Silicon (M1/M2/M3/M4)** dan **Intel Core 64-bit**.
- **Izin**: Memerlukan izin *Screen Recording* (Perekaman Layar).

### iOS (Perangkat Layar):
- **Perangkat**: Semua model iPhone (iPhone 6s s/d iPhone 16 Pro Max) dan iPad (Air, Mini, Pro, Reguler).
- **Sistem Operasi**: iOS 12.0 hingga iOS 18+.
- **Browser**: Safari (Bawaan iOS).

---

## 📥 Panduan Instalasi

### Metode 1: Menjalankan Aplikasi Jadi (.app)
1. Unduh atau clone repositori ini ke Mac Anda:
   ```bash
   git clone https://github.com/omandistudio/iPhoneExtendedDisplay.git
   cd iPhoneExtendedDisplay
   ```
2. Anda dapat langsung membuka aplikasi bundle:
   - Klik ganda (**Double-click**) pada file **`iPhone Extended Display.app`**.
   - Atau klik ganda pada file shortcut: **`Start-iPhoneExtendedDisplay.command`**.
3. Jendela **iPhone Extended Display Control** akan muncul di layar Mac Anda.

---

### Metode 2: Kompilasi Mandiri dari Source Code (build.sh)
Bagi pengembang yang ingin memodifikasi atau mengompilasi ulang source code sendiri:
1. Pastikan Command Line Tools Xcode telah terpasang di Mac Anda (`xcode-select --install`).
2. Jalankan skrip build otomatis yang disediakan:
   ```bash
   chmod +x build.sh
   ./build.sh
   ```
3. Skrip ini akan mengompilasi seluruh modul Swift native, membundel aset ke dalam `iPhone Extended Display.app`, dan melakukan ad-hoc code signing secara otomatis.

---

## 🔒 Pengaturan Izin macOS (Wajib)

Agar aplikasi dapat membaca layar Mac dan mengalirkannya ke iPhone, macOS mewajibkan izin keamanan *Screen Recording*:

1. Buka menu **Apple ()** di pojok kiri atas > **System Settings** (Pengaturan Sistem).
2. Masuk ke menu **Privacy & Security** (Privasi & Keamanan) > **Screen Recording** (Perekaman Layar).
3. Cari **iPhone Extended Display** (atau Terminal / Runner yang Anda gunakan).
4. Geser sakelar ke posisi **ON** (Aktif / Centang Biru).
5. Jika aplikasi sedang terbuka saat Anda memberikan izin, tutup dan buka kembali aplikasinya agar token izin baru terbaca oleh sistem.

---

## 📱 Panduan Penggunaan

### 1. Menggunakan Kabel USB (Rekomendasi - Latensi Nol)
1. Hubungkan iPhone ke Mac menggunakan kabel Lightning atau USB-C.
2. Di iPhone Anda, pastikan opsi **Hotspot Pribadi (Personal Hotspot)** aktif (pilih mode *Hanya USB* bila ditanya).
3. Buka **iPhone Extended Display.app** di Mac.
4. Buka browser **Safari** di iPhone, lalu ketik alamat IP USB:
   ```
   http://192.168.2.1:8080
   ```
5. Ketuk tombol biru **"Mulai Layar Tambahan"**.
6. Layar monitor Mac Anda akan langsung mengalir secara instan ke iPhone!

---

### 2. Menggunakan Jaringan Wi-Fi (Nirkabel)
1. Pastikan Mac dan iPhone Anda terhubung ke jaringan Wi-Fi lokal yang sama.
2. Buka **iPhone Extended Display.app** di Mac.
3. Lihat alamat IP Wi-Fi yang tertera pada jendela Control Window (misalnya: `http://192.168.0.xxx:8080`).
4. Buka Safari di iPhone dan buka alamat IP tersebut.
5. Ketuk **"Mulai Layar Tambahan"**.

---

### 3. Trik Tampilan Penuh 100% Layar (Edge-to-Edge Fullscreen)
Browser Safari di iOS memiliki bilah alamat dan bilah tab bawah yang membatasi ruang layar. Untuk menjadikannya monitor sejati tanpa bilah apapun:
1. Di Safari iPhone, buka alamat tampilan (`http://192.168.2.1:8080`).
2. Ketuk tombol **Share** di Safari (ikon kotak dengan panah mengarah ke atas).
3. Gulir ke bawah dan pilih **"Tambah ke Layar Utama" (Add to Home Screen)**.
4. Beri nama (misalnya: *Extended Display*), lalu ketuk **Tambah (Add)**.
5. Sebuah ikon baru akan muncul di Home Screen iPhone Anda.
6. Buka melalui ikon tersebut: Tampilan akan terbuka dalam mode **Web App Layar Penuh (Edge-to-Edge)** tanpa bilah browser sama sekali!

---

## 🗑️ Panduan Uninstalasi

Jika Anda ingin menghapus aplikasi ini dari perangkat Anda secara bersih:

### Menghapus Aplikasi dari macOS
1. Tutup aplikasi **iPhone Extended Display** jika sedang berjalan.
2. Hapus bundle aplikasi dari Mac Anda:
   ```bash
   rm -rf "iPhone Extended Display.app"
   ```
   Atau cukup pindahkan folder proyek ke **Trash (Tong Sampah)** dan kosongkan Trash.

### Membersihkan Izin Sistem macOS
1. Buka **System Settings** > **Privacy & Security** > **Screen Recording**.
2. Pilih **iPhone Extended Display**, lalu klik ikon minus (**-**) di bagian bawah daftar untuk mencabut dan menghapus entri izin dari database TCC macOS.

### Menghapus Web App dari iPhone / iPad
1. Pada Home Screen iPhone Anda, tekan dan tahan (long press) ikon **Extended Display**.
2. Pilih **Hapus Bookmark (Delete Bookmark)** / **Hapus dari Layar Utama**.
3. Bersihkan riwayat Safari bila diperlukan melalui **Pengaturan** > **Safari** > **Bersihkan Riwayat dan Data Situs Web**.

---

## ❓ FAQ & Troubleshooting

### Q: Mengapa di Safari iPhone hanya muncul layar hitam / peringatan izin?
**Jawab**: Hal ini terjadi jika macOS belum mengizinkan *Screen Recording*. Ikuti langkah pada bagian [Pengaturan Izin macOS](#-pengaturan-izin-macos-wajib). Setelah mengaktifkan sakelar izin, **pastikan menutup aplikasi dan membukanya kembali** agar izin baru diterapkan.

### Q: Port 8080 sudah digunakan oleh aplikasi lain?
**Jawab**: Jika port 8080 sedang digunakan oleh aplikasi lain (misalnya server lokal Node.js / Docker), Anda dapat memeriksa proses mana yang menggunakannya melalui Terminal:
```bash
lsof -i :8080
kill -9 <PID_PROSES>
```

### Q: Alamat USB `192.168.2.1` tidak bisa dibuka di iPhone?
**Jawab**:
1. Pastikan kabel data USB berfungsi dengan baik (bukan hanya kabel charger daya).
2. Pada iPhone, pastikan Anda telah memilih **"Percayai Komputer Ini" (Trust This Computer)** saat menghubungkan kabel.
3. Pastikan fitur **Hotspot Pribadi** aktif di iPhone agar interface jaringan USB Ethernet (`bridge100`) terbentuk antara Mac dan iPhone.

---

## 📂 Struktur Repositori

```text
iPhoneExtendedDisplay/
├── .github/
│   └── ISSUE_TEMPLATE/
│       ├── bug_report.md               # Template Laporan Bug
│       └── feature_request.md          # Template Permintaan Fitur
├── iPhone Extended Display.app/         # 🚀 Bundle Aplikasi Native macOS Siap Pakai
├── macOS/                              # Source Code Backend & GUI macOS
│   ├── AppDelegate.swift               # Manajemen Siklus Hidup Aplikasi Native
│   ├── ControlWindow.swift             # Antarmuka Pengaturan SwiftUI & AppKit
│   ├── ExtendedDisplayService.swift    # Core Pipeline Server & Virtual Display
│   ├── WebServer.swift                 # Server WebSocket & HTTP Port 8080
│   ├── WebClientHTML.swift             # Frontend Web iOS (HTML5 Canvas 60 FPS + Auto-Hide)
│   ├── ScreenCaptureManager.swift      # ScreenCaptureKit & CoreGraphics Fallback
│   ├── VirtualDisplayManager.swift     # Manajemen Virtual Monitor
│   ├── InputInjector.swift             # Simulasi Sentuhan ke Kursor macOS
│   ├── NetworkServer.swift             # Server Komunikasi Native TCP Port 7789
│   ├── H264Encoder.swift               # Akselerasi Hardware VideoToolbox
│   └── main.swift                      # Entry Point Aplikasi
├── iOS/                                # Client Source Code Native iOS (Opsional)
├── Shared/                             # Shared Binary Protocol
├── .gitignore                          # Standard macOS & Swift Git Ignore
├── build.sh                            # Skrip Kompilasi Otomatis macOS App
├── Start-iPhoneExtendedDisplay.command # Peluncur 1-Klik macOS Finder
├── CHANGELOG.md                        # Catatan Rilis & Riwayat Perubahan
├── CONTRIBUTING.md                     # Panduan Kontribusi Komunitas
├── LICENSE                             # Lisensi Open-Source MIT
└── README.md                           # Dokumentasi Lengkap Proyek
```

---

## 📄 Lisensi & Kontribusi

Proyek ini dilisensikan di bawah **[MIT License](LICENSE)**.

Hak Cipta © 2026 **[YoiKut.com](https://yoikut.com)**.

Jika proyek ini bermanfaat bagi produktivitas kerja Anda, dukung pengembangannya dengan memberikan bintang (⭐ Star) pada repositori **[omandistudio/iPhoneExtendedDisplay](https://github.com/omandistudio/iPhoneExtendedDisplay)**!
