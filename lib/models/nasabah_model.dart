import 'package:cloud_firestore/cloud_firestore.dart';

/// Nasabah (warga penyetor sampah) — data master untuk mengaitkan
/// setiap setoran ke identitas nasabah yang menyetor.
///
/// Skema TETAP (bukan atribut fleksibel) — sengaja diminimalkan sesuai
/// kebutuhan konkret: identitas nasabah untuk mengaitkan setoran,
/// bukan database kependudukan lengkap.
class NasabahModel {
  final String id;
  final String nama;
  final String? alamat;
  final String? noHp;
  final DateTime createdAt;

  NasabahModel({
    required this.id,
    required this.nama,
    this.alamat,
    this.noHp,
    required this.createdAt,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'nama': nama,
      'alamat': alamat,
      'noHp': noHp,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory NasabahModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return NasabahModel(
      id: doc.id,
      nama: data['nama'] as String? ?? '',
      alamat: data['alamat'] as String?,
      noHp: data['noHp'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
