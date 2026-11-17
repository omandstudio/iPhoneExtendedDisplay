# iPhone Extended Display

[![macOS](https://img.shields.io/badge/macOS-12.0%2B-black?logo=apple)](https://apple.com)
[![iOS](https://img.shields.io/badge/iOS-12.0%2B-blue?logo=apple)](https://apple.com)
[![Version](https://img.shields.io/badge/version-1.0.1-green.svg)](https://github.com/omandstudio/iPhoneExtendedDisplay)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Author](https://img.shields.io/badge/author-YoiKut.com-orange.svg)](https://yoikut.com)

A native macOS application designed to transform your iPhone or iPad into an external secondary monitor (Extended Display) or duplicate screen (Mirror Display) via high-speed USB cable (zero latency) or wireless Wi-Fi, without Apple Sidecar hardware restrictions.

Aplikasi native macOS yang dirancang untuk mengubah iPhone atau iPad menjadi monitor eksternal tambahan (Extended Display) atau duplikasi layar (Mirror Display) melalui kabel USB berkecepatan tinggi (latensi nol) maupun Wi-Fi, tanpa batasan perangkat keras Apple Sidecar.

Official Repository: [https://github.com/omandstudio/iPhoneExtendedDisplay](https://github.com/omandstudio/iPhoneExtendedDisplay)  
Developed and maintained by **[YoiKut.com](https://yoikut.com)**.

---

## Language / Bahasa

- [English Documentation](#english)
- [Dokumentasi Bahasa Indonesia](#bahasa-indonesia)

---

<a name="english"></a>
# English

## Table of Contents
- [Key Features](#key-features)
- [System Requirements](#system-requirements)
- [Installation Guide](#installation-guide)
  - [Method 1: DMG Installer (Recommended)](#method-1-dmg-installer-recommended)
  - [Method 2: Pre-compiled Application Bundle](#method-2-pre-compiled-application-bundle)
  - [Method 3: Build from Source](#method-3-build-from-source)
- [macOS Permissions Setup](#macos-permissions-setup)
- [Usage Instructions](#usage-instructions)
  - [1. High-Speed USB Connection (Recommended)](#1-high-speed-usb-connection-recommended)
  - [2. Local Wi-Fi Connection](#2-local-wi-fi-connection)
  - [3. Fullscreen Edge-to-Edge Experience](#3-fullscreen-edge-to-edge-experience)
- [Uninstallation](#uninstallation)
- [Repository Structure](#repository-structure)
- [License](#license)

---

## Key Features

- **Native macOS Control Window**: Lightweight and responsive interface built with SwiftUI and AppKit to monitor server status in real time, view active network interfaces, copy access URLs, and toggle frame rates.
- **Dual Display Modes**:
  - **Extended Display Mode**: Functions as an independent secondary workspace to extend desktop real estate.
  - **Mirror Display Mode**: Duplicates the primary macOS desktop onto the iOS device.
- **Dynamic Frame Rate**: Switch dynamically between 60 FPS (ultra-smooth cursor movement) and 30 FPS (energy-saving profile).
- **High-Speed USB Streaming (Zero Latency)**: Leverages native macOS and iOS virtual Ethernet bridge tethering (`192.168.2.1`) to stream video frames with sub-16ms latency.
- **Wireless Wi-Fi Support**: Streams smoothly across any local Wi-Fi subnet without physical cables.
- **Zero-Install Client for iOS**: Runs straight through the native Safari browser on iPhone or iPad. No App Store downloads, side-loading, or developer certificates required.
- **True Fullscreen PWA Support**: Adding the web client to the iOS Home Screen removes browser address bars and navigation controls, creating a borderless 100% monitor experience.
- **Smart Auto-Hide HUD**: On-screen control widgets and FPS indicators automatically fade out after 2 seconds of inactivity, reappearing with a tap on the subtle gear control.
- **Interactive Touch-to-Mouse Relay**: Translates iOS touchscreen taps, gestures, and drags into macOS cursor movements and mouse clicks via low-latency WebSockets.

---

## System Requirements

### macOS (Host Machine)
- Operating System: macOS 12.0 Monterey, macOS 13 Ventura, macOS 14 Sonoma, macOS 15+ Sequoia.
- Architecture: Fully compatible with Apple Silicon (M1/M2/M3/M4) and 64-bit Intel processors.
- Permissions: Screen Recording permission is required.

### iOS (Display Device)
- Hardware: Any iPhone (iPhone 6s through iPhone 16 series) or iPad (Mini, Air, Pro, Standard).
- Operating System: iOS 12.0 through iOS 18+.
- Web Browser: Native Apple Safari.

---

## Installation Guide

### Method 1: DMG Installer (Recommended)
1. Download the latest installer package `iPhoneExtendedDisplay-1.0.1.dmg` from [GitHub Releases](https://github.com/omandstudio/iPhoneExtendedDisplay/releases).
2. Double-click the downloaded `.dmg` file to mount the disk image.
3. Drag the `iPhone Extended Display` application icon into the `Applications` shortcut folder.
4. Launch the application directly from your `Applications` folder, Launchpad, or Spotlight.

### Method 2: Pre-compiled Application Bundle
1. Clone the repository to your Mac:
   ```bash
   git clone https://github.com/omandstudio/iPhoneExtendedDisplay.git
   cd iPhoneExtendedDisplay
   ```
2. Double-click `iPhone Extended Display.app` or run `Start-iPhoneExtendedDisplay.command`.

### Method 3: Build from Source
1. Ensure Xcode Command Line Tools are installed:
   ```bash
   xcode-select --install
   ```
2. Run the automated build and packaging scripts:
   ```bash
   chmod +x build.sh package-dmg.sh
   ./build.sh          # Compiles Swift source files into .app bundle
   ./package-dmg.sh    # Creates a distributable .dmg installer
   ```

---

## macOS Permissions Setup

macOS requires explicit authorization for applications capturing screen content:
1. Open **System Settings** (or **System Preferences**).
2. Navigate to **Privacy & Security** > **Screen Recording**.
3. Toggle the switch next to **iPhone Extended Display** to enable permission.
4. If prompted to restart the application, click **Quit & Reopen**.

---

## Usage Instructions

### 1. High-Speed USB Connection (Recommended)
1. Connect your iPhone or iPad to your Mac using a Lightning or USB-C cable.
2. If prompted on your iOS device, select **Trust This Computer**.
3. Enable **Personal Hotspot** on iOS (via USB cable) to establish the direct virtual Ethernet bridge (`192.168.2.1`).
4. Launch `iPhone Extended Display` on your Mac.
5. On your iPhone or iPad, open Safari and navigate to:
   ```text
   http://192.168.2.1:8080
   ```

### 2. Local Wi-Fi Connection
1. Ensure both your Mac and iOS device are connected to the same Wi-Fi network.
2. Check the Wi-Fi IP address displayed inside the `iPhone Extended Display Control` window (for example: `http://192.168.1.50:8080`).
3. Open Safari on iOS and navigate to that address.

### 3. Fullscreen Edge-to-Edge Experience
1. Open the web interface in Safari on your iOS device.
2. Tap the Safari **Share** icon (square with an upward arrow).
3. Select **Add to Home Screen**.
4. Launch the app from the newly created Home Screen icon to enjoy an edge-to-edge monitor layout without browser chrome.

---

## Uninstallation

To remove the application from your Mac:
1. Quit the application if it is currently running.
2. Move `iPhone Extended Display.app` from `/Applications` to the Trash.
3. Reset screen capture authorization via Terminal if desired:
   ```bash
   tccutil reset ScreenCapture com.yoikut.iPhoneExtendedDisplay
   ```

---

<a name="bahasa-indonesia"></a>
# Bahasa Indonesia

## Daftar Isi
- [Fitur Utama](#fitur-utama)
- [Kebutuhan Sistem](#kebutuhan-sistem)
- [Panduan Instalasi](#panduan-instalasi)
  - [Metode 1: Installer .DMG (Rekomendasi)](#metode-1-installer-dmg-rekomendasi)
  - [Metode 2: Menjalankan Bundle Aplikasi Jadi (.app)](#metode-2-menjalankan-bundle-aplikasi-jadi-app)
  - [Metode 3: Kompilasi Mandiri dari Source Code](#metode-3-kompilasi-mandiri-dari-source-code)
- [Pengaturan Izin macOS](#pengaturan-izin-macos)
- [Petunjuk Penggunaan](#petunjuk-penggunaan)
  - [1. Menggunakan Kabel USB (Rekomendasi)](#1-menggunakan-kabel-usb-rekomendasi)
  - [2. Menggunakan Jaringan Wi-Fi](#2-menggunakan-jaringan-wi-fi)
  - [3. Tampilan Layar Penuh 100%](#3-tampilan-layar-penuh-100)
- [Penghapusan Aplikasi](#penghapusan-aplikasi)
- [Struktur Repositori](#struktur-repositori-1)
- [Lisensi](#lisensi)

---

## Fitur Utama

- **Jendela Kontrol Native macOS**: Antarmuka berbasis SwiftUI dan AppKit untuk memantau status server secara langsung, melihat alamat IP aktif, menyalin URL akses, dan mengatur frame rate.
- **Dua Mode Tampilan**:
  - **Extended Display (Layar Tambahan)**: Berfungsi sebagai monitor kedua mandiri untuk memperluas area multitasking.
  - **Mirror Display (Duplikasi Layar)**: Menduplikasi tampilan layar utama Mac ke perangkat iOS.
- **Pemilih Frame Rate Dinamis**: Beralih antara 60 FPS (kursor ultra halus) dan 30 FPS (profil hemat daya).
- **Streaming USB Berkecepatan Tinggi (Latensi Nol)**: Memanfaatkan jembatan jaringan virtual bawaan macOS dan iOS (`192.168.2.1`) dengan latensi di bawah 16ms tanpa lag.
- **Koneksi Nirkabel Wi-Fi**: Bekerja melalui jaringan Wi-Fi lokal yang sama tanpa kabel fisik.
- **Klien Tanpa Instalasi di iOS**: Cukup dibuka melalui browser bawaan Safari di iPhone atau iPad. Tanpa App Store, jailbreak, atau sertifikat pengembang.
- **Dukungan Fullscreen PWA**: Menambahkan web app ke Home Screen iOS untuk menghilangkan bilah alamat dan tab browser, memberikan pengalaman monitor penuh tanpa batas.
- **Smart Auto-Hide HUD**: Indikator FPS dan tombol kontrol otomatis tersembunyi setelah 2 detik tanpa interaksi untuk menjaga tampilan monitor tetap bersih.
- **Relay Sentuhan Interaktif**: Menerjemahkan sentuhan layar iPhone menjadi pergerakan kursor dan klik mouse native macOS via WebSocket.

---

## Kebutuhan Sistem

### macOS (Komputer Mac)
- Sistem Operasi: macOS 12.0 Monterey, macOS 13 Ventura, macOS 14 Sonoma, macOS 15+ Sequoia.
- Arsitektur: Kompatibel penuh dengan Apple Silicon (M1/M2/M3/M4) dan prosesor Intel 64-bit.
- Izin: Membutuhkan izin Perekaman Layar (Screen Recording).

### iOS (Perangkat Layar)
- Perangkat: Semua model iPhone (iPhone 6s hingga seri iPhone 16) dan iPad (Mini, Air, Pro, Standar).
- Sistem Operasi: iOS 12.0 hingga iOS 18+.
- Peramban: Apple Safari bawaan iOS.

---

## Panduan Instalasi

### Metode 1: Installer .DMG (Rekomendasi)
1. Unduh file installer `iPhoneExtendedDisplay-1.0.1.dmg` dari halaman [GitHub Releases](https://github.com/omandstudio/iPhoneExtendedDisplay/releases).
2. Klik ganda file `.dmg` yang telah diunduh.
3. Geser ikon aplikasi `iPhone Extended Display` ke dalam folder shortcut `Applications`.
4. Buka aplikasi dari folder `Applications`, Launchpad, atau Spotlight.

### Metode 2: Menjalankan Bundle Aplikasi Jadi (.app)
1. Salin repositori ke Mac Anda:
   ```bash
   git clone https://github.com/omandstudio/iPhoneExtendedDisplay.git
   cd iPhoneExtendedDisplay
   ```
2. Klik ganda pada `iPhone Extended Display.app` atau jalankan `Start-iPhoneExtendedDisplay.command`.

### Metode 3: Kompilasi Mandiri dari Source Code
1. Pastikan Command Line Tools Xcode terpasang:
   ```bash
   xcode-select --install
   ```
2. Jalankan skrip kompilasi dan pembuatan paket:
   ```bash
   chmod +x build.sh package-dmg.sh
   ./build.sh          # Mengompilasi kode sumber Swift menjadi .app bundle
   ./package-dmg.sh    # Membungkus aplikasi ke dalam installer .dmg
   ```

---

## Pengaturan Izin macOS

Sistem operasi macOS mewajibkan otorisasi manual untuk perekaman layar:
1. Buka **System Settings** (atau **System Preferences**).
2. Pilih menu **Privacy & Security** > **Screen Recording**.
3. Aktifkan centang atau toggle pada **iPhone Extended Display**.
4. Jika muncul konfirmasi, klik **Quit & Reopen** untuk menerapkan izin.

---

## Petunjuk Penggunaan

### 1. Menggunakan Kabel USB (Rekomendasi)
1. Hubungkan iPhone atau iPad ke Mac menggunakan kabel Lightning atau USB-C.
2. Pilih **Percayai Komputer Ini** (*Trust This Computer*) jika muncul notifikasi di iOS.
3. Aktifkan **Hotspot Pribadi** (*Personal Hotspot*) di iPhone melalui kabel USB agar jembatan Ethernet virtual (`192.168.2.1`) aktif.
4. Buka aplikasi `iPhone Extended Display` di Mac.
5. Pada iPhone atau iPad, buka Safari dan akses alamat:
   ```text
   http://192.168.2.1:8080
   ```

### 2. Menggunakan Jaringan Wi-Fi
1. Pastikan Mac dan iPhone terhubung pada jaringan Wi-Fi lokal yang sama.
2. Lihat alamat IP Wi-Fi yang tercantum pada jendela `iPhone Extended Display Control` (contoh: `http://192.168.1.50:8080`).
3. Buka Safari di iOS dan akses alamat tersebut.

### 3. Tampilan Layar Penuh 100%
1. Buka antarmuka web di Safari iOS.
2. Tekan tombol **Share** (kotak dengan panah ke atas).
3. Pilih opsi **Add to Home Screen** (*Tambah ke Layar Utama*).
4. Buka aplikasi melalui ikon di Layar Utama untuk menikmati tampilan monitor penuh tanpa bilah peramban.

---

## Penghapusan Aplikasi

Untuk menghapus aplikasi dari Mac Anda:
1. Tutup aplikasi jika sedang berjalan.
2. Pindahkan `iPhone Extended Display.app` dari folder `/Applications` ke Trash.
3. Reset izin perekaman layar melalui Terminal jika diperlukan:
   ```bash
   tccutil reset ScreenCapture com.yoikut.iPhoneExtendedDisplay
   ```

---

<a name="repository-structure"></a>
## Repository Structure / Struktur Repositori

```text
iPhoneExtendedDisplay/
├── .github/
│   ├── workflows/
│   │   └── release.yml                 # CI/CD automated build & DMG release
│   └── ISSUE_TEMPLATE/
│       ├── bug_report.md               # Bug report template
│       └── feature_request.md          # Feature request template
├── iPhone Extended Display.app/         # Pre-compiled native macOS application bundle
├── macOS/                              # Native macOS source code
│   ├── AppDelegate.swift               # Application lifecycle management
│   ├── ControlWindow.swift             # SwiftUI & AppKit user interface
│   ├── ExtendedDisplayService.swift    # Core pipeline server & virtual display logic
│   ├── WebServer.swift                 # HTTP & WebSocket server (port 8080)
│   ├── WebClientHTML.swift             # iOS web client (HTML5 canvas 60 FPS + auto-hide HUD)
│   ├── ScreenCaptureManager.swift      # ScreenCaptureKit engine & CoreGraphics fallback
│   ├── VirtualDisplayManager.swift     # Virtual display manager
│   ├── InputInjector.swift             # Touch-to-mouse event injection (CGEvent)
│   ├── NetworkServer.swift             # Native TCP server (port 7789)
│   ├── H264Encoder.swift               # VideoToolbox hardware-accelerated H.264 encoder
│   └── main.swift                      # Application entry point
├── iOS/                                # Optional native iOS client sources
├── Shared/                             # Shared binary protocols
├── .gitignore                          # macOS & Swift git ignore rules
├── build.sh                            # Native build script
├── package-dmg.sh                      # Automated DMG packaging script
├── Start-iPhoneExtendedDisplay.command # One-click launcher for macOS Finder
├── CHANGELOG.md                        # Version changelog history
├── CONTRIBUTING.md                     # Community contribution guide
├── LICENSE                             # MIT Open-Source License
└── README.md                           # Documentation (English & Bahasa Indonesia)
```

---

<a name="license"></a>
## License / Lisensi

This project is licensed under the **[MIT License](LICENSE)**.  
Proyek ini dilisensikan di bawah **[MIT License](LICENSE)**.

Copyright (c) 2026 **[YoiKut.com](https://yoikut.com)**.

If this project helps your daily workflow, consider giving it a star on GitHub:  
Jika proyek ini bermanfaat bagi Anda, dukung pengembangannya dengan memberikan bintang (Star) pada repositori resmi:  
**[https://github.com/omandstudio/iPhoneExtendedDisplay](https://github.com/omandstudio/iPhoneExtendedDisplay)**
