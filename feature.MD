# 📋 Daftar Fitur LifeHub

**LifeHub** — aplikasi manajemen pribadi untuk **Catatan (Notes)**, **Keuangan (Finance)**, dan **Tugas (Tasks)**. Berikut daftar lengkap fitur yang tersedia di aplikasi.

---

## 🏠 Dashboard (Beranda)

Halaman utama yang menampilkan ringkasan semua aktivitas.

- **Sapaan dinamis** berdasarkan waktu (`Selamat Pagi/Siang/Sore/Malam`)
- **Tanggal lengkap** dengan locale Bahasa Indonesia (`EEEE, d MMMM yyyy`)
- **Avatar profil** dengan badge merah jumlah tugas terlewat
- **Menu profil** (bottom sheet) → akses ke Profil & Notifikasi
- **Kartu ringkasan keuangan** (glassmorphism): total Pemasukan, Pengeluaran & Saldo bulan berjalan
- **Section peringatan anggaran** — tampil otomatis saat kategori hampir limit / melebihi batas (dengan progress bar)
- **Section tugas hari ini** — progres penyelesaian (%), status Diproses/Belum Dikerjakan
- **Section catatan terbaru** — horizontal scroll card dengan ikon mood untuk jurnal
- **Background image** dengan overlay gelap

---

## 📝 Catatan (Notes)

Modul pencatatan dengan dukungan jurnal & mood tracker.

- **CRUD catatan** (buat, baca, edit, hapus)
- **Mode Jurnal** dengan **mood tracker** (ikon mood)
- **Pin / unpin** catatan penting
- **Kategori kustom** (CRUD penuh via layar "Kelola Kategori")
  - 1 kategori default: **Umum** (tidak bisa dihapus, bisa diubah)
  - Referensi via `Note.categoryId`
- **Smart tag** dengan autocomplete (`TagAutocompleteField`)
  - Pencarian saat mengetik
  - Cegah duplikasi tag
  - Tracking `usageCount` untuk sorting popularitas
- **Filter gabungan**:
  - Pencarian teks (judul + konten)
  - Filter berdasarkan kategori
  - **Multiple tag filter** (toggle via ikon tag di AppBar)
  - Mode jurnal only
- **Salin catatan** (long-press menu → clipboard)
- **Swipe-to-delete** dengan konfirmasi dialog
- **Indikator pin & mood** pada list card

---

## 💰 Keuangan (Finance)

Modul manajemen keuangan dengan transaksi, anggaran, dan tabungan.

### Tab Transaksi
- **Navigasi bulan** (bulan sebelumnya / berikutnya)
- **Ringkasan bulanan** (Pemasukan, Pengeluaran, Saldo)
- **Tambah transaksi** income/expense
- **Sumber dana** (wallet): cash, bank, e-wallet
- **Kategori transaksi** (dengan budget)
- **Alokasi otomatis ke tabungan** dari pemasukan
- **Pakai tabungan** sebagai sumber pengeluaran
- **Swipe-to-delete** transaksi

### Anggaran (Budget)
- Layar overview anggaran per kategori
- Tambah / edit / hapus anggaran
- **Indikator status**: aman, hampir limit, melebihi batas (warna berbeda)
- Progress bar real-time vs pengeluaran aktual

### Statistik
- **Pie chart** pengeluaran per kategori (`fl_chart`)
- **Rincian pengeluaran** dengan progress bar per kategori
- Legenda warna kategori

### Tab Tabungan (Savings)
- **Kategori tabungan** dengan target nominal
- **Progress bar** menuju target
- Badge **"Tercapai"** saat target tercapai
- **Detail tabungan** dengan ledger mutasi (riwayat setoran & penarikan)
- **Kelola kategori tabungan** (CRUD)
- **Kelola sumber dana** (CRUD wallet)

---

## ✅ Tugas (Tasks)

Modul manajemen tugas harian & proyek.

- **4 tab status**: Semua, To Do, In Progress, Done
- **Group by prioritas** (Tinggi / Sedang / Rendah) dengan label berwarna
- **Indikator prioritas** (titak warna pada card)
- **Pencarian** tugas (judul + deskripsi)
- **Filter multiple tag** (toggle via ikon tag)
- **Filter prioritas** (dropdown)
- **Tag dengan autocomplete**
- **Due date** dengan indikator **"Lewat!"** untuk tugas overdue
- **Toggle complete** (lingkaran checklist)
- **Integrasi anggaran** — tautkan tugas ke kategori finance + nominal
- **Flag reminder** (field sudah ada)
- **Proyek** — kelompokkan tugas terkait
- **Kanban Board** — drag-and-drop antar kolom status (To Do / In Progress / Done)
- **Swipe-to-delete** tugas

---

## 👤 Profil

- **Avatar** dari galeri (`image_picker`, resize ke 512px)
- **Nama** dan **Bio**
- Mode edit dengan tombol Simpan/Batal
- Avatar disimpan ke app directory lokal

---

## 🔔 Notifikasi

- Daftar **tugas terlewat** (missed tasks)
- Jumlah hari keterlambatan
- Badge counter sinkron dengan avatar di dashboard
- Empty state "Semua tugas sudah selesai!"

---

## ⚙️ Settings / Konfigurasi

- **Theme mode**: System / Light / Dark (Material 3)
- **Simbol mata uang** (default `Rp`)
- **Toggle PIN** (`hasPinEnabled`)
- State lock (`isLocked`)
- Persist via `shared_preferences`

---

## 🎨 Global UI / UX

- **Material 3** + custom `AppTheme` (light & dark)
- Font **Plus Jakarta Sans** (`google_fonts`)
- **Glassmorphism cards** (`GlassCard`, `GlassCardPro`) + flat dark card
- **Bottom navigation 4 tab**: Beranda, Catatan, Keuangan, Tugas
- **Radial Add Button** (tombol + melayang di navbar)
  - Di Dashboard: tekan & tahan → menu radial fan (Catatan / Keuangan / Tugas)
  - Di tab lain: tap langsung → buka form tambah sesuai modul aktif
- **Locale `id_ID`** untuk format tanggal & angka
- **Format Rupiah** via `CurrencyFormatter` (`format()` / `formatCompact()` — Rp, jt, rb)
- Palette warna utama: `#6366F1` (indigo)
- Border radius konsisten: 12 (input) / 14–16 (card) / 20 (chip)

---

## 🏗️ Arsitektur & Tech Stack (singkat)

- **State management**: `flutter_riverpod` (StreamProvider, FutureProvider, AsyncNotifier)
- **Database lokal**: `isar` (NoSQL, reactive via `.watch()`)
- **Struktur**: feature-based (`lib/features/<module>/presentation/screens/`)
- **Helper reusable**: `CurrencyFormatter`, `DateHelper`, `ColorHelper`, mood helpers
- **Widget reusable**: `CategoryPicker`, `TagAutocompleteField`, `GlassCard`, `IconBox`, `AppAlert`

---

## 🔲 Fitur yang Belum Tersedia (Roadmap)

- ❌ Notifikasi reminder tugas terjadwal (dependency sudah ada, belum dipakai)
- ❌ Biometric authentication (dependency `local_auth` sudah ada, belum dipakai)
- ❌ Recurring transactions (field sudah ada di model, UI belum)
- ❌ Edit kategori catatan via long-press chip (opsional)
