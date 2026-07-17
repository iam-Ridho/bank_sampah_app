import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/jenis_barang_model.dart';
import '../../shared/providers/firestore_provider.dart';

final jenisBarangCollectionProvider = Provider<CollectionReference<Map<String, dynamic>>>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return firestore.collection('jenis_barang_sampah');
});

class JenisBarangListResult {
  final List<JenisBarangModel> items;
  final bool isFromCache;

  JenisBarangListResult({required this.items, required this.isFromCache});
}

/// Stream semua jenis barang, urut nama A-Z — daftar ini DINAMIS
/// (bertambah seiring petugas menambah jenis baru), beda dari daftar
/// sektor Gapoktan yang baku di field_config.dart.
final jenisBarangStreamProvider = StreamProvider<JenisBarangListResult>((ref) {
  final collection = ref.watch(jenisBarangCollectionProvider);

  return collection.orderBy('nama').snapshots(includeMetadataChanges: true).map((snapshot) {
    final items = snapshot.docs.map((doc) => JenisBarangModel.fromFirestore(doc)).toList();
    return JenisBarangListResult(items: items, isFromCache: snapshot.metadata.isFromCache);
  });
});

class JenisBarangRepository {
  final CollectionReference<Map<String, dynamic>> _collection;
  final CollectionReference<Map<String, dynamic>> _setoranCollection;

  JenisBarangRepository(this._collection, this._setoranCollection);

  /// Tambah jenis barang baru — dipanggil petugas lewat picker saat
  /// jenis yang dicari belum ada di daftar. `harga` WAJIB diisi sejak
  /// awal (beda dari versi sebelumnya) — tanpa harga, jenis itu tidak
  /// bisa dipakai untuk menghitung nilai setoran.
  Future<void> tambahJenisBarang(String nama, SatuanBarang satuan, double harga) async {
    final model = JenisBarangModel(
      id: '',
      nama: nama.trim(),
      satuan: satuan,
      harga: harga,
      createdAt: DateTime.now(),
    );
    await _collection.add(model.toFirestore());
  }

  /// Ubah nama, satuan, DAN/ATAU harga suatu jenis barang — dipanggil
  /// dari halaman Kelola Jenis Barang.
  ///
  /// KEPUTUSAN DESAIN PENTING (tiga field, perilaku berbeda):
  /// - NAMA yang diubah IKUT MENIMPA semua transaksi lama yang memakai
  ///   nama lama itu — perbaikan typo (mis. "Kadus" -> "Kardus") adalah
  ///   koreksi, bukan perubahan makna. TANPA propagasi ini, rekap tetap
  ///   pecah dua meski sudah "diperbaiki".
  /// - SATUAN dan HARGA yang diubah TIDAK menyentuh transaksi lama sama
  ///   sekali — keduanya sudah didenormalisasi ke tiap SetoranItem saat
  ///   dicatat (lihat setoran_model.dart). Harga KHUSUSNYA dikonfirmasi
  ///   berubah tiap minggu mengikuti harga pasar — mengubahnya
  ///   retroaktif akan salah secara faktual (transaksi minggu lalu
  ///   harus tetap bernilai sesuai harga minggu lalu).
  ///
  /// CATATAN TEKNIS PENTING: karena item transaksi EMBEDDED di dalam
  /// array pada setiap dokumen `setoran` (bukan field query-able
  /// langsung), Firestore TIDAK BISA melakukan `.where()` ke dalam isi
  /// array itu. Maka propagasi nama di sini mengambil SEMUA dokumen
  /// setoran, mencari kecocokan DI MEMORI, baru batch-update dokumen
  /// yang terdampak — konsisten dengan pola "filter di memori" yang
  /// sudah dipakai di seluruh aplikasi karena keterbatasan skema
  /// fleksibel Firestore yang sama.
  Future<void> ubahJenisBarang({
    required String id,
    required String namaLama,
    required String namaBaru,
    required SatuanBarang satuanBaru,
    required double hargaBaru,
  }) async {
    final namaBerubah = namaLama.trim() != namaBaru.trim();

    if (!namaBerubah) {
      // Hanya satuan/harga yang berubah (atau tidak ada perubahan) —
      // cukup update dokumen jenis barangnya sendiri, TANPA menyentuh
      // transaksi lama sama sekali.
      await _collection.doc(id).update({
        'nama': namaBaru.trim(),
        'satuan': satuanBaru.name,
        'harga': hargaBaru,
      });
      return;
    }

    // Nama berubah — ambil SEMUA setoran, cari yang punya item dengan
    // nama lama, perbaiki nama itemnya (harga/satuan item TIDAK ikut
    // diubah, tetap seperti saat dicatat), lalu batch-update.
    final batch = _collection.firestore.batch();
    batch.update(_collection.doc(id), {
      'nama': namaBaru.trim(),
      'satuan': satuanBaru.name,
      'harga': hargaBaru,
    });

    final semuaSetoran = await _setoranCollection.get();
    for (final doc in semuaSetoran.docs) {
      final data = doc.data();
      final itemsRaw = data['items'] as List<dynamic>? ?? [];
      var adaYangCocok = false;

      final itemsBaru = itemsRaw.map((item) {
        final itemMap = Map<String, dynamic>.from(item as Map);
        if (itemMap['jenisBarang'] == namaLama) {
          adaYangCocok = true;
          return {...itemMap, 'jenisBarang': namaBaru.trim()};
        }
        return itemMap;
      }).toList();

      if (adaYangCocok) {
        batch.update(doc.reference, {'items': itemsBaru});
      }
    }

    await batch.commit();
  }

  Future<void> hapusJenisBarang(String id) async {
    await _collection.doc(id).delete();
  }
}

final jenisBarangRepositoryProvider = Provider<JenisBarangRepository>((ref) {
  final collection = ref.watch(jenisBarangCollectionProvider);
  final firestore = ref.watch(firestoreProvider);
  return JenisBarangRepository(collection, firestore.collection('setoran'));
});
