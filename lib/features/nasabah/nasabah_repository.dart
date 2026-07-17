import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/nasabah_model.dart';
import '../../shared/providers/firestore_provider.dart';

final nasabahCollectionProvider = Provider<CollectionReference<Map<String, dynamic>>>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return firestore.collection('nasabah');
});

class NasabahListResult {
  final List<NasabahModel> items;
  final bool isFromCache;

  NasabahListResult({required this.items, required this.isFromCache});
}

/// Stream semua nasabah, urut nama A-Z — memudahkan pencarian visual
/// manual kalau daftar belum terlalu banyak.
final nasabahStreamProvider = StreamProvider<NasabahListResult>((ref) {
  final collection = ref.watch(nasabahCollectionProvider);

  return collection.orderBy('nama').snapshots(includeMetadataChanges: true).map((snapshot) {
    final items = snapshot.docs.map((doc) => NasabahModel.fromFirestore(doc)).toList();
    return NasabahListResult(items: items, isFromCache: snapshot.metadata.isFromCache);
  });
});

class NasabahRepository {
  final CollectionReference<Map<String, dynamic>> _collection;

  NasabahRepository(this._collection);

  Future<String> tambahNasabah({
    required String nama,
    String? alamat,
    String? noHp,
  }) async {
    final model = NasabahModel(
      id: '',
      nama: nama.trim(),
      alamat: alamat,
      noHp: noHp,
      createdAt: DateTime.now(),
    );
    final ref = await _collection.add(model.toFirestore());
    return ref.id;
  }

  Future<void> ubahNasabah(String id, Map<String, dynamic> data) async {
    await _collection.doc(id).update(data);
  }

  Future<void> hapusNasabah(String id) async {
    await _collection.doc(id).delete();
  }
}

final nasabahRepositoryProvider = Provider<NasabahRepository>((ref) {
  final collection = ref.watch(nasabahCollectionProvider);
  return NasabahRepository(collection);
});
