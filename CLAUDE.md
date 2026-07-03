# CLAUDE.md — LifeHub

Memori project untuk Claude Code. Dibaca otomatis di awal setiap sesi.

## 📋 Overview

**LifeHub** — aplikasi manajemen pribadi untuk **Catatan (Notes)**, **Keuangan (Finance)**, dan **Tugas (Tasks)**. Dibangun dengan Flutter, Material 3, bahasa UI Bahasa Indonesia.

- **Package:** `com.example.lifehub`
- **Versi:** 1.0.0+2
- **SDK:** Flutter `^3.10.4`
- **Platform target:** Android (utama), juga punya folder ios/web/windows/linux/macos

## 🚀 Perintah Penting

```bash
# Jalankan app
flutter run

# Generate kode Isar (WAJIB setelah ubah model di lib/data/models/*.dart)
dart run build_runner build --delete-conflicting-outputs

# Cek error
flutter analyze --no-pub

# Build APK
flutter build apk
```

> **PENTING:** Setelah mengubah model Isar (file `_model.dart`), **selalu** jalankan `build_runner`. Lalu butuh **full restart** app (bukan hot reload) karena schema Isar di-cache di memory native.

## 🛠️ Tech Stack

| Teknologi | Versi | Kegunaan |
|-----------|-------|----------|
| Flutter | ^3.10.4 | Framework |
| flutter_riverpod | ^2.5.1 | State management |
| isar | ^3.1.0+1 | Database lokal NoSQL |
| google_fonts | ^8.1.0 | Font Plus Jakarta Sans |
| fl_chart | ^0.68.0 | Grafik keuangan |
| intl | ^0.20.2 | Format tanggal & currency (locale `id_ID`) |
| shared_preferences | ^2.2.3 | Settings (theme, currency) |
| flutter_local_notifications | ^17.2.2 | Reminder tugas (belum dipakai) |
| local_auth | ^2.3.0 | Biometric (belum dipakai) |

## 🏗️ Arsitektur

```
lib/
├── core/
│   ├── theme/app_theme.dart        # AppColors + ThemeData (light & dark)
│   ├── utils/helpers.dart          # CurrencyFormatter, DateHelper, ColorHelper, mood helpers
│   └── widgets/                    # Widget reusable
│       ├── category_picker.dart        # CategoryPicker + CategoryColorPicker (12 preset)
│       └── tag_autocomplete_field.dart # Input tag dgn autocomplete
├── data/
│   ├── models/                     # Isar @collection models (+ .g.dart auto-generated)
│   └── providers/                  # Riverpod providers & Notifiers
└── features/
    ├── dashboard/                  # Beranda
    ├── finance/                    # Keuangan
    ├── notes/                      # Catatan
    └── tasks/                      # Tugas
└── main.dart                       # Entry point + MainShell (bottom nav 4 tab)
```

**Pola state management:**
- `StreamProvider` → data reactive (auto-update via Isar `.watch(fireImmediately: true)`)
- `FutureProvider` → data one-time
- `Notifier` / `AsyncNotifier` → mutations (save/delete/update)
- Provider di-invalidate manual setelah mutation agar UI refresh

## 📊 Data Models (Isar Collections)

**Tasks** (`task_model.dart`): `Task`, `Project`
**Finance** (`finance_model.dart`): `Transaction`, `Wallet`, `FinanceCategory`, `SavingsGoal`
**Notes** (`note_model.dart`): `Note`, `NoteCategoryCustom`, `NoteTag`

> Detail setiap model lihat langsung di file `_model.dart`. Semua pakai `Id id = Isar.autoIncrement`.

## ✅ Status Fitur

### Notes (Catatan) — fokus pengembangan terbaru
- ✅ CRUD catatan + journal (dengan mood tracker)
- ✅ **Custom category penuh** (add/edit/delete) via layar "Kelola Kategori"
  - Hanya 1 default: **'Umum'** (`isDefault = true`, tidak bisa dihapus, bisa diubah)
  - Reference via `Note.categoryId` (int? nullable, null = Umum)
  - Helper `resolveCategory()` di `notes_provider.dart` untuk lookup display
- ✅ **Smart tag** dgn autocomplete (`TagAutocompleteField`):
  - Search saat mengetik, prevent duplikasi, add new otomatis
  - Tracking `usageCount` untuk sorting popularitas
- ✅ Filter: search + kategori + **multiple tags** (toggle via ikon tag di AppBar)
- 🔲 Belum: edit kategori lewat long-press chip (opsional)

### Finance (Keuangan)
- ✅ Transaksi income/expense, wallet (cash/bank/ewallet), kategori dgn budget
- ✅ Ringkasan bulanan, budget alerts, savings goals
- 🔲 Belum: recurring transactions (field sudah ada di model)

### Tasks (Tugas)
- ✅ Tugas harian (group by priority) + proyek + Kanban board
- 🔲 Belum: notifikasi reminder (dependency sudah ada)

### Dashboard
- ✅ Ringkasan keuangan, tugas hari ini, catatan terbaru, budget alerts

## ⚠️ Gotchas & Konvensi

1. **Schema Isar berubah → reset DB.** Jika mengubah/menghapus field model, database lama di device bisa bentrok. Reset via `adb shell pm clear com.example.lifehub` atau uninstall app. Fungsi `_migrateNoteCategories()` di `database_provider.dart` jadi contoh pola migrasi idempotent.

2. **Seeding pakai pola "jika kosong".** Tapi untuk perubahan breaking, gunakan fungsi migrasi seperti `_migrateNoteCategories` (selalu jalan, idempotent).

3. **UI style:** chip pakai `AnimatedContainer` + `withOpacity(0.15)` saat selected. Border radius 12 (input) / 14-16 (card) / 20 (chip). Font `plusJakartaSans`. Warna utama `AppColors.primary = #6366F1`.

4. **Currency:** format Rupiah via `CurrencyFormatter.format()` / `formatCompact()` (Rp, jt, rb). Locale `id_ID`.

5. **Helper kategori:** untuk menampilkan kategori catatan di UI, pakai `ref.watch(categoryMapProvider)` lalu `resolveCategory(note.categoryId, map)`.

6. **Repo Git:** sudah di-init (branch `main`). Remote GitHub belum diset — beri URL ke user lalu `git remote add origin <url>` + `git push -u origin main`. `.gitignore` mengecualikan `**/build/`, `.dart_tool/`, dan `.claude/settings.local.json`. File generated (`.g.dart`, `generated_plugin_registrant.*`) **di-commit** karena dibutuhkan build.

## 📝 Log Progress

- **2026-07-03:** Refactor kategori catatan → pure custom (hapus enum `NoteCategory`, ganti `Note.categoryId`). Tambah layar "Kelola Kategori" (`category_management_screen.dart`) untuk CRUD penuh. Migrasi otomatis `_migrateNoteCategories` untuk cleanup kategori lama.
- **2026-07-02:** Implementasi awal custom category + tag autocomplete untuk Notes. Tambah widget `category_picker.dart` & `tag_autocomplete_field.dart`.
- **Project awal:** Struktur feature-based, dashboard, finance, tasks, notes dasar.

## 💬 Catatan Komunikasi

- User berkomunikasi dalam **Bahasa Indonesia** → balas dalam Bahasa Indonesia.
- User sedang aktif mengembangkan fitur catatan; sering iterasi UI.
- Preferensi user: UI simpel (icon saja tanpa label berlebih), preset palette (bukan color picker custom), tanpa emoji picker (text/color saja).
