import 'package:cloud_firestore/cloud_firestore.dart';
import 'jenis_barang_model.dart';

/// Satu baris item dalam satu setoran — mis. "Botol Kaca, 4 buah,
/// @Rp250 = Rp1.000". EMBEDDED di dalam SetoranModel (bukan
/// subcollection Firestore terpisah) — supaya satu kunjungan nasabah
/// (yang bisa berisi banyak jenis barang sekaligus, sesuai skenario
/// "Pak Budi bawa 4 jenis barang") tersimpan sebagai SATU dokumen,
/// SATU operasi tulis yang atomik. Ini penting untuk offline-first:
/// kalau item-item itu disimpan sebagai dokumen terpisah, ada risiko
/// sebagian tersimpan sebagian tidak kalau koneksi terputus di
/// tengah proses — dengan embedded, satu `add()` mencakup semuanya.
///
/// `harga` DIDENORMALISASI (disalin dari JenisBarangModel.harga SAAT
/// baris ini dicatat) — BUKAN di-lookup ulang setiap ditampilkan. Ini
/// PENTING: harga jual di gudang berubah tiap minggu, kalau harga
/// diubah minggu depan, transaksi MINGGU LALU harus tetap menampilkan
/// harga minggu lalu, bukan ikut berubah retroaktif — sama seperti
/// pola denormalisasi `satuan` yang sudah dipakai sebelumnya.
class SetoranItem {
  final String jenisBarang;
  final SatuanBarang satuan;
  final double jumlah;
  final double harga; // Rp per satuan, SAAT transaksi ini dicatat

  const SetoranItem({
    required this.jenisBarang,
    required this.satuan,
    required this.jumlah,
    required this.harga,
  });

  double get subtotal => jumlah * harga;

  Map<String, dynamic> toMap() {
    return {
      'jenisBarang': jenisBarang,
      'satuan': satuan.name,
      'jumlah': jumlah,
      'harga': harga,
    };
  }

  factory SetoranItem.fromMap(Map<String, dynamic> map) {
    return SetoranItem(
      jenisBarang: map['jenisBarang'] as String? ?? '',
      satuan: SatuanBarangLabel.fromString(map['satuan'] as String?),
      jumlah: (map['jumlah'] as num?)?.toDouble() ?? 0,
      harga: (map['harga'] as num?)?.toDouble() ?? 0,
    );
  }
}

/// Satu SETORAN = satu kunjungan nasabah membawa satu tumpukan barang
/// (bisa berisi banyak jenis sekaligus, lihat SetoranItem di atas).
/// Ini PENGGANTI konsep lama "satu entri = satu jenis barang tanpa
/// identitas" — sekarang setiap setoran WAJIB terhubung ke nasabah.
///
/// `nasabahNama` didenormalisasi (disalin dari NasabahModel saat
/// setoran dicatat) — supaya kode tampilan/laporan tidak perlu JOIN
/// setiap saat. `nasabahId` tetap disimpan untuk relasi (mis. menyusun
/// riwayat per nasabah di halaman detail nasabah).
///
/// `totalNilai` DIHITUNG SEKALI saat setoran dibuat dan DISIMPAN
/// (bukan dihitung ulang setiap ditampilkan) — murni optimisasi supaya
/// daftar riwayat tidak perlu iterasi semua item tiap render, TAPI
/// tetap konsisten karena `items` juga disimpan lengkap sehingga bisa
/// diverifikasi/dihitung ulang kapan saja kalau diperlukan.
class SetoranModel {
  final String id;
  final String nasabahId;
  final String nasabahNama;
  final DateTime tanggal;
  final List<SetoranItem> items;
  final double totalNilai;
  final String? catatan;
  final String createdBy;
  final String? createdByEmail;
  final DateTime createdAt;

  SetoranModel({
    required this.id,
    required this.nasabahId,
    required this.nasabahNama,
    required this.tanggal,
    required this.items,
    required this.totalNilai,
    this.catatan,
    required this.createdBy,
    this.createdByEmail,
    required this.createdAt,
  });

  /// Helper membuat SetoranModel baru dari daftar item — totalNilai
  /// dihitung otomatis dari subtotal tiap item, supaya pemanggil
  /// (form input) tidak perlu menghitung manual dan berisiko salah.
  factory SetoranModel.baru({
    required String nasabahId,
    required String nasabahNama,
    required DateTime tanggal,
    required List<SetoranItem> items,
    String? catatan,
    required String createdBy,
    String? createdByEmail,
  }) {
    final total = items.fold<double>(0, (sum, item) => sum + item.subtotal);
    return SetoranModel(
      id: '',
      nasabahId: nasabahId,
      nasabahNama: nasabahNama,
      tanggal: tanggal,
      items: items,
      totalNilai: total,
      catatan: catatan,
      createdBy: createdBy,
      createdByEmail: createdByEmail,
      createdAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'nasabahId': nasabahId,
      'nasabahNama': nasabahNama,
      'tanggal': Timestamp.fromDate(tanggal),
      'items': items.map((i) => i.toMap()).toList(),
      'totalNilai': totalNilai,
      'catatan': catatan,
      'createdBy': createdBy,
      'createdByEmail': createdByEmail,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory SetoranModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final itemsRaw = data['items'] as List<dynamic>? ?? [];
    return SetoranModel(
      id: doc.id,
      nasabahId: data['nasabahId'] as String? ?? '',
      nasabahNama: data['nasabahNama'] as String? ?? '',
      tanggal: (data['tanggal'] as Timestamp?)?.toDate() ?? DateTime.now(),
      items: itemsRaw.map((i) => SetoranItem.fromMap(Map<String, dynamic>.from(i))).toList(),
      totalNilai: (data['totalNilai'] as num?)?.toDouble() ?? 0,
      catatan: data['catatan'] as String?,
      createdBy: data['createdBy'] as String? ?? '',
      createdByEmail: data['createdByEmail'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
