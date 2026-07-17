import 'package:cloud_firestore/cloud_firestore.dart';

/// Satuan pencatatan untuk satu jenis barang. Sebagian besar sampah
/// ditimbang (kg), tapi beberapa lebih wajar dihitung per BUAH/BIJI
/// (mis. botol kaca utuh) atau per LITER (mis. minyak jelantah) —
/// memaksa semuanya jadi kg akan menghasilkan angka aneh atau petugas
/// jadi malas mencatat barang yang tidak biasa ditimbang.
enum SatuanBarang { kg, buah, liter }

extension SatuanBarangLabel on SatuanBarang {
  String get label {
    switch (this) {
      case SatuanBarang.kg:
        return 'kg';
      case SatuanBarang.buah:
        return 'buah';
      case SatuanBarang.liter:
        return 'liter';
    }
  }

  static SatuanBarang fromString(String? value) {
    switch (value) {
      case 'buah':
        return SatuanBarang.buah;
      case 'liter':
        return SatuanBarang.liter;
      default:
        return SatuanBarang.kg;
    }
  }
}

/// Satu jenis barang/sampah (mis. "PET Biru", "Kardus", "Botol Kaca").
///
/// BERBEDA PENTING dari sektor di Gapoktan (`field_config.dart`), yang
/// daftarnya BAKU/tetap di kode (developer yang menentukan). Di sini,
/// petugas bank sampah BISA MENAMBAH jenis baru sendiri kapan saja
/// lewat aplikasi — makanya daftar ini disimpan sebagai DATA di
/// Firestore (koleksi `jenis_barang_sampah`), bukan konstanta di Dart.
///
/// `satuan` ditentukan SEKALI saat jenis barang pertama kali dibuat
/// (lewat picker) — supaya konsisten setiap kali jenis itu dipakai.
/// Kalau salah pilih di awal, bisa diubah lewat halaman kelola jenis
/// barang (edit) — TIDAK memengaruhi transaksi lama (lihat catatan di
/// SetoranModel soal denormalisasi).
///
/// `harga` (Rp per satuan) BOLEH DIUBAH KAPAN SAJA — dikonfirmasi harga
/// jual di gudang berubah tiap minggu tergantung pasar. Setiap kali
/// harga diubah di sini, HANYA memengaruhi transaksi BARU ke depannya;
/// transaksi lama menyimpan harga-nya sendiri saat itu dicatat (lihat
/// SetoranItemModel), supaya nilai transaksi lama tidak berubah
/// retroaktif hanya karena harga pasar sekarang berbeda.
class JenisBarangModel {
  final String id;
  final String nama;
  final SatuanBarang satuan;
  final double harga; // Rp per kg, per buah, atau per liter — tergantung `satuan`
  final DateTime createdAt;

  JenisBarangModel({
    required this.id,
    required this.nama,
    required this.satuan,
    required this.harga,
    required this.createdAt,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'nama': nama,
      'satuan': satuan.name,
      'harga': harga,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory JenisBarangModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return JenisBarangModel(
      id: doc.id,
      nama: data['nama'] as String? ?? '',
      // Backward-compatible: jenis barang yang dibuat SEBELUM field
      // satuan/harga ada akan bernilai null di Firestore -> default ke
      // 'kg' dan harga 0 (petugas WAJIB isi harga lewat Kelola Jenis
      // Barang sebelum jenis itu bisa dipakai transaksi baru — lihat
      // validasi di setoran_form_screen.dart).
      satuan: SatuanBarangLabel.fromString(data['satuan'] as String?),
      harga: (data['harga'] as num?)?.toDouble() ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  JenisBarangModel copyWith({String? nama, SatuanBarang? satuan, double? harga}) {
    return JenisBarangModel(
      id: id,
      nama: nama ?? this.nama,
      satuan: satuan ?? this.satuan,
      harga: harga ?? this.harga,
      createdAt: createdAt,
    );
  }
}
