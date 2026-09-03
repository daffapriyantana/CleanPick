# CleanPick

Aplikasi customer untuk layanan pengangkutan sampah, dibuat sebagai implementasi
**Milestone 3 (CPMK 3): State Management Modern & Arsitektur Clean Code**.

## Cara Menjalankan

Project ini dibuat dari Flutter project kosong dan siap dijalankan di komputer yang
sudah terpasang Flutter SDK (project ini **tidak** dijalankan/dites di lingkungan
pembuatan kode ini karena sandbox tidak memiliki akses ke Flutter SDK / pub.dev —
jalankan langkah di bawah ini di komputer Anda).

```bash
flutter pub get
flutter run
```

Menjalankan unit test:

```bash
flutter test
```

Login demo (data dummy):
- Email: `budi@email.com`
- Password: `password123`

Atau buat akun baru lewat halaman **Daftar**.

## Struktur Clean Architecture

```
lib/
├── core/            # error handling, constants, utils, theme (dipakai semua layer)
├── data/            # models (JSON-ready), datasources (in-memory), repository impl
├── domain/          # entities, repository interface, use cases (business logic murni)
└── presentation/    # pages, reusable widgets, BLoC/Cubit (state management)
```

Alur dependensi: `presentation -> domain <- data` (domain tidak bergantung pada
apa pun di luar `core`), sehingga datasource in-memory saat ini bisa diganti
dengan Firebase/REST API kapan pun tanpa mengubah use case atau UI.

## State Management (BLoC/Cubit)

Fitur **Pesanan** (`OrderCubit` + `OrderState`) adalah implementasi utama,
dengan state: `OrderInitial → OrderLoading → (Success state) | OrderFailure`,
persis mengikuti alur di spesifikasi milestone. Fitur **Auth** menggunakan pola
yang sama lewat `AuthCubit`.

## Business Logic & Validasi

- `CalculateOrderPrice`: perhitungan tarif murni (berat × tarif/kg + biaya
  kendaraan + biaya jarak), melempar `ValidationFailure` bila berat ≤ 0 atau
  melebihi kapasitas kendaraan.
- `CreateOrder`: memvalidasi jenis sampah, berat, alamat, dan tanggal sebelum
  meneruskan ke repository.

## Data Dummy

`OrderLocalDataSourceImpl` dan `AuthLocalDataSourceImpl` menyediakan data awal
(1 akun + 2 pesanan contoh) sehingga aplikasi bisa langsung didemokan tanpa
backend, sambil tetap melalui repository/data layer (tidak ditulis langsung
di widget).

## Unit Test

Ada di folder `test/`, mencakup 4 skenario minimum dari spesifikasi:

| # | Skenario | File |
|---|----------|------|
| 1 | Perhitungan tarif berhasil | `test/domain/usecases/calculate_order_price_test.dart` |
| 2 | Berat tidak valid → error | `test/domain/usecases/calculate_order_price_test.dart` |
| 3 | Data pesanan valid → dibuat | `test/domain/usecases/create_order_test.dart` |
| 4 | Data pesanan tidak valid → ditolak | `test/domain/usecases/create_order_test.dart` |

Ditambah `test/data/repositories/order_repository_impl_test.dart` untuk
memverifikasi repository menerjemahkan exception datasource menjadi `Failure`
domain dengan benar.

## Catatan

- Struktur ini menggunakan dependency injection manual sederhana di
  `main.dart` (`AppDependencies`) — bisa diganti `get_it`/`injectable` bila
  diinginkan.
- Karena batasan lingkungan pembuatan project ini, `flutter pub get` dan
  `flutter test` belum sempat dijalankan langsung di sini; jalankan kedua
  perintah tersebut di komputer Anda untuk memverifikasi sebelum
  dikumpulkan/didemokan.
