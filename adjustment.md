# Task List: Bug Fix & Feature Adjustment

> Kerjakan tiap task sesuai urutan. Tiap task punya: **Problem**, **Expected Fix**, **Acceptance Criteria**. Sesuaikan nama komponen/file dengan struktur codebase yang ada.

---

## 1. Tag Component

### 1.1 Warna teks tag saat active/pressed
- **Problem:** Saat tombol tag ditekan (active state), background berubah putih tapi teks tetap putih → teks tidak terbaca.
- **Fix:** Saat state active/pressed, ubah warna teks tag menjadi hitam (atau warna gelap yang kontras dengan background putih).
- **Acceptance Criteria:**
  - [ ] Tag dalam kondisi default: style tidak berubah.
  - [ ] Tag dalam kondisi active/pressed: teks berwarna hitam, tetap terbaca jelas.

### 1.2 Layout tag berantakan saat jumlah banyak
- **Problem:** Ketika tag banyak, tag bertabrakan/overlap dengan card. Selain itu, kontainer tag juga menutupi tombol "Filter Tag" dan "Manage Category" di navbar.
- **Fix:** Perbaiki container/wrapper tag list agar:
  - Tag wrap ke bawah dengan rapi (tidak overlap ke elemen lain).
  - Jika tag sangat banyak, container scrollable (bukan mendorong/menutupi elemen lain).
  - Tombol navbar (Filter Tag, Manage Category) tidak pernah tertutup oleh list tag, berapa pun jumlah tagnya.
- **Acceptance Criteria:**
  - [ ] Card dan tag tidak overlap meski tag banyak.
  - [ ] Navbar (Filter Tag, Manage Category) selalu terlihat & clickable.
  - [ ] Tag list bisa di-scroll jika melebihi container.

### 1.3 Scoping perhitungan jumlah tag per modul
- **Problem:** Filter tag di modul "Catatan" ikut menghitung penggunaan tag dari modul "Tugas" (dan sebaliknya). Contoh: tag "motor" hanya dipakai di Tugas, tapi masih muncul/terhitung di filter tag Catatan.
- **Fix:**
  - Filter tag di modul **Catatan** → hanya hitung penggunaan tag di data Catatan.
  - Filter tag di modul **Tugas** → hanya hitung penggunaan tag di data Tugas.
  - Jika suatu tag punya jumlah = 0 pada modul tertentu, tag tersebut **tidak ditampilkan** di dropdown/filter modul itu.
- **Acceptance Criteria:**
  - [ ] Tag hanya muncul di filter modul yang benar-benar memakainya.
  - [ ] Count tag di tiap modul independen satu sama lain.
  - [ ] Tag dengan count 0 di suatu modul otomatis hilang dari filter modul tersebut.

---

## 2. Category Filter (Menu Catatan)

- **Problem:** Filter category tersusun vertikal ke bawah; tombol "Tambah" ada di posisi paling akhir.
- **Fix:**
  - Ubah layout jadi horizontal (menyamping), dengan scroll horizontal jika item banyak.
  - Pindahkan tombol "Tambah" ke posisi paling awal (bukan akhir).
- **Acceptance Criteria:**
  - [ ] List category tersusun horizontal, scrollable ke samping.
  - [ ] Tombol "Tambah" berada di urutan pertama.

---

## 3. Finance Summary (Menu Finance)

- **Problem:**
  1. Jarak antara list card transaksi dan finance summary terlalu rapat.
  2. Style card finance summary di menu Finance berbeda dengan finance summary di Dashboard.
- **Fix:**
  1. Tambahkan spacing/margin yang cukup antara list transaksi dan finance summary.
  2. Samakan style card finance summary di menu Finance dengan style finance summary di Dashboard (gunakan komponen/style yang sama).
- **Acceptance Criteria:**
  - [ ] Ada jarak jelas antara list card dan finance summary.
  - [ ] Tampilan card finance summary di Finance identik dengan di Dashboard.

---

## 4. Kanban (Menu Tugas)

- **Problem:** Kanban belum mendukung drag-and-drop, dan kolom status tersusun horizontal (kurang cocok untuk mobile).
- **Fix:**
  - Tambahkan fitur drag-and-drop antar status/kolom.
  - Ubah susunan kolom status jadi vertikal (ke bawah), bukan horizontal.
- **Acceptance Criteria:**
  - [ ] Task bisa dipindah antar status via drag-and-drop.
  - [ ] Kolom status tersusun vertikal, layout nyaman digunakan di mobile.

---

## 5. Integrasi Tugas ↔ Anggaran (Finance)

- **Problem:** Belum ada relasi antara fitur Tugas dan Anggaran/Finance.
- **Fix — Saat membuat/edit tugas:**
  - Tambahkan toggle **"Anggaran"**.
  - Jika toggle **aktif**, tampilkan input tambahan:
    - Nominal biaya.
    - Tipe: **Expense** atau **Income**.
    - Jika **Expense** → pilih kategori anggaran tujuan.
- **Fix — Saat tugas ditandai "Done":**
  - Sistem otomatis membuat entry transaksi baru menggunakan data dari input tugas (nominal, tipe, kategori).
  - Transaksi ini mengurangi/menambah saldo anggaran terkait, sama seperti input transaksi manual.
- **Acceptance Criteria:**
  - [ ] Toggle "Anggaran" muncul saat create/edit tugas.
  - [ ] Saat toggle aktif, field nominal + tipe (+ kategori jika expense) wajib diisi.
  - [ ] Saat tugas di-set "Done", transaksi otomatis terbentuk di modul Finance.
  - [ ] Saldo anggaran ter-update sesuai transaksi otomatis tersebut (expense mengurangi, income menambah).
  - [ ] Tugas yang toggle-nya tidak aktif tidak membuat transaksi apa pun.

---

## Catatan Umum untuk Agent
- Prioritaskan konsistensi style dengan komponen/tema yang sudah ada di codebase (jangan buat style baru dari nol jika komponen serupa sudah ada).
- Untuk tiap perbaikan UI, pastikan tetap responsif di tampilan mobile.
- Untuk task 5, pastikan transaksi otomatis punya penanda/referensi ke task asal (misal `task_id`) agar bisa dilacak/di-audit.