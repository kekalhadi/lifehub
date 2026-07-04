# Task: Ubah Layout Kanban dari Horizontal ke Vertikal

## Referensi
- **Before:** 3 kolom status (`TO DO`, `On Progress`, `Done`) tersusun berdampingan secara horizontal.
- **After:** Kolom status tersusun bertumpuk vertikal ke bawah, masing-masing dengan scroll internal sendiri.

---

## Kondisi Sekarang (Before)
- 3 kolom status (`TO DO`, `On Progress`, `Done`) tersusun **berdampingan secara horizontal**.
- Tiap kolom punya tinggi penuh, task card disusun vertikal di dalam masing-masing kolom.

## Kondisi yang Diinginkan (After)
- Ketiga kolom status disusun **bertumpuk vertikal dari atas ke bawah** dalam satu container full-width (urutan: `TO DO` → `On Progress` → `Done`), menyesuaikan lebar layar mobile.
- Tiap section status jadi **card/container tersendiri** dengan:
  - Header nama status di bagian atas.
  - List task card di dalamnya.
- **Setiap section status punya scroll vertikal independen** untuk daftar card-nya (bukan cuma scroll di level halaman). Jadi kalau section `TO DO` isinya banyak, section itu bisa di-scroll sendiri tanpa membuat section `On Progress`/`Done` ikut terdorong terlalu jauh ke bawah. Berikan `max-height` pada tiap section, dan internal scroll (`overflow-y: auto` / setara) untuk list card-nya.
- Drag-and-drop antar status (dari task list sebelumnya) tetap harus berfungsi normal meski arah layoutnya berubah jadi vertikal.

---

## Acceptance Criteria
- [ ] Section status tersusun vertikal (TO DO di atas, On Progress di tengah, Done di bawah), full width mengikuti lebar layar.
- [ ] Tiap section punya header + list card sendiri.
- [ ] Tiap section bisa di-scroll secara independen saat card di dalamnya melebihi tinggi maksimal section.
- [ ] Drag-and-drop task antar status tetap berfungsi setelah perubahan layout.
- [ ] Layout nyaman & tidak terpotong di lebar layar mobile standar (±360–430px).