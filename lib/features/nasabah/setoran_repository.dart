import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/setoran_model.dart';
import '../../shared/providers/firestore_provider.dart';

/// Reference ke koleksi `setoran` — PENGGANTI koleksi lama `sampah_masuk`
/// (data lama di koleksi itu diabaikan/dianggap data uji coba, sesuai
/// keputusan saat redesain fitur nasabah+multi-item ini). Nama koleksi
/// baru dipilih agar mencerminkan konsep "satu kunjungan nasabah",
/// bukan "satu entri barang".
final setoranCollectionProvider = Provider<CollectionReference<Map<String, dynamic>>>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return firestore.collection('setoran');
});

class SetoranListResult {
  final List<SetoranModel> items;
  final bool isFromCache;

  SetoranListResult({required this.items, required this.isFromCache});
}

/// Stream SEMUA setoran (semua nasabah), urut tanggal terbaru dulu —
/// dipakai untuk tab Riwayat & Rekap (rekap keseluruhan bank sampah).
final setoranStreamProvider = StreamProvider<SetoranListResult>((ref) {
  final collection = ref.watch(setoranCollectionProvider);

  return collection
      .orderBy('tanggal', descending: true)
      .snapshots(includeMetadataChanges: true)
      .map((snapshot) {
    final items = snapshot.docs.map((doc) => SetoranModel.fromFirestore(doc)).toList();
    return SetoranListResult(items: items, isFromCache: snapshot.metadata.isFromCache);
  });
});

class SetoranRepository {
  final CollectionReference<Map<String, dynamic>> _collection;

  SetoranRepository(this._collection);

  /// Simpan satu setoran (satu kunjungan nasabah, bisa berisi banyak
  /// item sekaligus) sebagai SATU dokumen — atomik, konsisten dengan
  /// prinsip offline-first (lihat catatan lengkap di setoran_model.dart).
  Future<void> catatSetoran(SetoranModel setoran) async {
    await _collection.add(setoran.toFirestore());
  }

  Future<void> ubahSetoran(String id, Map<String, dynamic> data) async {
    await _collection.doc(id).update(data);
  }

  Future<void> hapusSetoran(String id) async {
    await _collection.doc(id).delete();
  }
}

final setoranRepositoryProvider = Provider<SetoranRepository>((ref) {
  final collection = ref.watch(setoranCollectionProvider);
  return SetoranRepository(collection);
});
