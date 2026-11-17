# Panduan Kontribusi (Contributing Guide)

Terima kasih atas ketertarikan Anda untuk berkontribusi pada **iPhone Extended Display**! Proyek open-source ini dikembangkan dan dikelola oleh **[YoiKut.com](https://yoikut.com)** di repositori **[omandstudio/iPhoneExtendedDisplay](https://github.com/omandstudio/iPhoneExtendedDisplay)**.

---

## 🛠️ Alur Kontribusi

1. **Fork Repositori**: Buat salinan repositori ini ke akun GitHub Anda.
2. **Buat Branch Fitur / Perbaikan**:
   ```bash
   git checkout -b feature/nama-fitur-baru
   # atau
   git checkout -b fix/nama-perbaikan-bug
   ```
3. **Lakukan Perubahan & Uji Coba**:
   - Pastikan perubahan kode Anda rapi dan mematuhi konvensi Swift / macOS native.
   - Uji kompilasi menggunakan skrip:
     ```bash
     ./build.sh
     ```
   - Jalankan dan uji coba baik pada Mac maupun perangkat iPhone/iPad fisik.
4. **Commit Perubahan**:
   ```bash
   git commit -m "feat: Menambahkan dukungan resolusi kustom"
   ```
5. **Push ke GitHub & Buat Pull Request (PR)**:
   - Kirimkan branch Anda ke GitHub fork Anda.
   - Buka Pull Request ke branch `main` repositori resmi `omandstudio/iPhoneExtendedDisplay`.
   - Jelaskan secara detail masalah yang diselesaikan atau fitur baru yang ditambahkan.

---

## 🐞 Melaporkan Bug atau Masukan Fitur

Jika Anda menemukan kendala atau memiliki ide fitur baru:
- Periksa daftar [GitHub Issues](https://github.com/omandstudio/iPhoneExtendedDisplay/issues) terlebih dahulu untuk memastikan topik belum pernah dilaporkan.
- Gunakan template **Bug Report** atau **Feature Request** yang tersedia saat membuat issue baru.
- Sertakan versi macOS, model iPhone, versi iOS, dan log error yang relevan.

---

## 📜 Lisensi
Dengan berkontribusi pada proyek ini, Anda menyetujui bahwa kontribusi Anda akan dilisensikan di bawah lisensi [MIT License](LICENSE).

