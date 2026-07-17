# Bank Sampah App

Aplikasi Flutter untuk manajemen pendataan Bank Sampah — mencatat setoran sampah nasabah, mengelola jenis barang, dan mengekspor laporan ke PDF maupun Excel.

---

## Fitur

- 🔐 Login dengan Firebase Authentication (email & password)
- 👤 Manajemen data nasabah (tambah, edit, hapus)
- ♻️ Pencatatan setoran sampah per nasabah beserta riwayatnya
- 🗂️ Kelola jenis barang/sampah dan harga satuannya
- 📄 Ekspor laporan rekap ke **PDF** dan **Excel**
- 📤 Bagikan laporan langsung via Share
- 📶 Indikator koneksi online/offline
- 📍 Integrasi Geolocator (untuk keperluan lokasi)

---

## Tech Stack

| Kategori | Package |
|---|---|
| State Management | `flutter_riverpod ^2.5.1` |
| Backend / Auth | `firebase_core`, `firebase_auth`, `cloud_firestore` |
| Laporan | `pdf ^3.11.1`, `printing ^5.14.3`, `excel ^4.0.0` |
| Share | `share_plus ^10.0.0` |
| Lokasi | `geolocator ^14.0.2` |
| Koneksi | `connectivity_plus ^6.0.5` |
| UI | `google_fonts ^8.1.0`, `font_awesome_flutter ^11.0.0` |
| Utilitas | `intl ^0.19.0`, `path_provider ^2.0.14` |

---

## Setup untuk Kontributor Baru

### 1. Prasyarat

- Flutter SDK **>= 3.0.0** ([panduan instalasi](https://docs.flutter.dev/get-started/install))
- Android Studio atau VS Code dengan plugin Flutter/Dart
- Akun Firebase dengan project yang sudah dibuat

### 2. Clone & Install Dependencies

```bash
git clone <url-repo-ini>
cd bank_sampah_app
flutter pub get
```

### 3. Setup Firebase

File-file berikut **tidak ikut di-commit** karena berisi API key sensitif. Kamu harus membuatnya sendiri:

#### a. Buat project di Firebase Console

Masuk ke [console.firebase.google.com](https://console.firebase.google.com), buat project baru atau minta akses ke project yang ada.

#### b. Aktifkan layanan yang digunakan

- **Authentication** → Sign-in method → Email/Password → Enable
- **Firestore Database** → Create database (pilih region Asia Tenggara)

#### c. Generate file konfigurasi dengan FlutterFire CLI

```bash
# Install FlutterFire CLI (sekali saja)
dart pub global activate flutterfire_cli

# Generate firebase_options.dart dan google-services.json sekaligus
flutterfire configure
```

Perintah di atas akan otomatis membuat:
- `lib/firebase_options.dart`
- `android/app/google-services.json`

> **Alternatif manual:** Download `google-services.json` dari Firebase Console → Project Settings → Android apps, letakkan di `android/app/`.

### 4. Jalankan Aplikasi

```bash
flutter run
```

---

## Build Android

```bash
# Debug APK
flutter build apk --debug

# Release APK (pastikan signing config sudah diatur di build.gradle.kts)
flutter build apk --release
```

> Release build saat ini masih menggunakan debug signing key. Untuk distribusi, atur `signingConfig` di `android/app/build.gradle.kts`.

---

## File yang Tidak Di-commit (Sensitif)

| File | Keterangan |
|---|---|
| `lib/firebase_options.dart` | API key Firebase per platform |
| `android/app/google-services.json` | Konfigurasi Firebase Android |
| `android/local.properties` | Path SDK Android lokal |
| `.env` / `.env.*` | Variabel lingkungan |
| `key.properties` | Keystore signing Android |

---

## Catatan

- App ID Android: `com.ridho.bankSampahRM`
- Min SDK Android: 21 (Android 5.0)
- Ikon app di-generate dari `assets/icon/logo_banksampah.png` menggunakan `flutter_launcher_icons`
- State management menggunakan Riverpod — semua provider ada di file `*_provider.dart` atau `*_repository.dart` masing-masing fitur
