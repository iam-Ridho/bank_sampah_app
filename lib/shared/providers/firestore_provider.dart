import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider instance Firestore. Pusatkan di sini supaya kalau perlu
/// ganti setting (misal cache size) cukup ubah di satu tempat.
final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  final firestore = FirebaseFirestore.instance;

  // Persistence sudah default-on di mobile, tapi kita set eksplisit
  // supaya tidak ada ambiguitas — sesuai catatan di hasil analisis arsitektur.
  firestore.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );

  return firestore;
});

/// Reference ke koleksi utama `inventaris`.
final inventarisCollectionProvider = Provider<CollectionReference<Map<String, dynamic>>>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return firestore.collection('inventaris');
});
