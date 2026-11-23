# Changelog

Semua perubahan penting pada DSM (DikNom System Monitor) dicatat di sini.

## [1.0] — 2026-11-23

Rilis publik pertama.

### Ditambahkan

- Dashboard **Performance** dengan grafik CPU total dan grafik terpisah untuk
  setiap core/thread, suhu package dan per core, frekuensi, governor, serta
  informasi cache CPU.
- Kartu **RAM**, **ZRAM**, dan **Swap** dengan grafik riwayat, kapasitas,
  rasio kompresi, dan rincian pemakaian.
- Panel **Disk** dan **Jaringan** dengan kecepatan baca/tulis, trafik,
  interface, IP, MAC, SSID, dan sinyal Wi-Fi.
- Panel **Baterai** di Performance dan kartu baterai lengkap di Hardware Info:
  persentase, status charger, sumber daya, kesehatan, kapasitas desain/penuh,
  daya, tegangan, siklus, teknologi, model, pabrikan, dan sisa waktu.
- Halaman **Hardware Info** untuk prosesor, memori, sistem/BIOS, penyimpanan,
  GPU, dan baterai.
- Halaman **Processes** dengan kolom CPU %, RAM, RAM %, thread, status,
  pencarian, sortir per kolom, dan tombol **Akhiri Tugas**.
- Halaman **Storage** dan **Network** untuk rincian partisi dan interface.
- **Settings** untuk interval pembaruan, panjang riwayat grafik, selalu di
  atas, filter thread kernel, ambang suhu, dan bahasa.
- Dukungan bahasa **Indonesia/English** dengan mode otomatis mengikuti locale.
- Deteksi hardware lintas OS: Linux (sysfs/DMI), Windows (WMI/PowerShell),
  dan macOS (`system_profiler`), dengan nilai `-` untuk sensor yang tidak
  tersedia.
- Pemasang `install.sh` lintas distro yang otomatis mendeteksi dan memasang
  dependensi (`apt`, `dnf`/`yum`, `pacman`, `zypper`, `apk`, `xbps-install`).
- Wrapper launcher yang memakai interpreter Python terverifikasi.
- Ikon aplikasi dan entri menu desktop Linux.
- Tangkapan layar Performance, Hardware Info, dan Processes untuk dokumentasi.

### Catatan

- Pengujian utama: Ubuntu 26.10 + XFCE pada Dynabook K50/FR (Intel Celeron
  N4020, 2 core/2 thread, RAM 4 GB, eMMC 64 GB).
- Fallback Windows/macOS sudah disediakan, tetapi belum diuji seluas Linux.
- Aplikasi tidak memerlukan root dan tidak mengirim data ke internet.

---

Developer: **DikNom**
