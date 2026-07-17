import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/jenis_barang_model.dart';
import '../../models/setoran_model.dart';
import '../nasabah/setoran_repository.dart';

/// Pilihan periode rekap — sesuai cara petugas mencatat di buku manual
/// (rekap harian/mingguan, lihat foto referensi awal).
enum PeriodeRekap { hariIni, mingguIni, bulanIni, semua }

extension PeriodeRekapLabel on PeriodeRekap {
  String get label {
    switch (this) {
      case PeriodeRekap.hariIni:
        return 'Hari Ini';
      case PeriodeRekap.mingguIni:
        return 'Minggu Ini';
      case PeriodeRekap.bulanIni:
        return 'Bulan Ini';
      case PeriodeRekap.semua:
        return 'Semua';
    }
  }
}

final selectedPeriodeRekapProvider = StateProvider<PeriodeRekap>((ref) => PeriodeRekap.mingguIni);

/// Kata kunci pencarian — dicocokkan ke NAMA NASABAH, jenis barang (di
/// dalam item-item setoran), atau catatan. Kosong berarti tidak ada
/// filter pencarian aktif.
final searchQuerySampahProvider = StateProvider<String>((ref) => '');

/// Public (bukan private `_dalamPeriode`) supaya bisa dipakai ulang di
/// nasabah_ledger_screen.dart — buku tabungan per nasabah butuh filter
/// periode yang SAMA persis logikanya dengan tab Riwayat & Rekap utama,
/// tidak masuk akal menduplikasi logic tanggal ini di dua tempat.
bool dalamPeriode(DateTime tanggal, PeriodeRekap periode) {
  final sekarang = DateTime.now();
  switch (periode) {
    case PeriodeRekap.hariIni:
      return tanggal.year == sekarang.year &&
          tanggal.month == sekarang.month &&
          tanggal.day == sekarang.day;
    case PeriodeRekap.mingguIni:
      final awalMinggu = sekarang.subtract(Duration(days: sekarang.weekday - 1));
      final awalMingguTanpaJam = DateTime(awalMinggu.year, awalMinggu.month, awalMinggu.day);
      return !tanggal.isBefore(awalMingguTanpaJam);
    case PeriodeRekap.bulanIni:
      return tanggal.year == sekarang.year && tanggal.month == sekarang.month;
    case PeriodeRekap.semua:
      return true;
  }
}

/// Provider TERPUSAT yang menggabungkan filter PERIODE + PENCARIAN atas
/// SETORAN (bukan lagi entri per-barang tunggal seperti sebelumnya) —
/// dipakai konsisten oleh: daftar Riwayat Setoran, Rekap per Jenis, DAN
/// laporan yang diekspor (PDF/Excel).
///
/// Pencarian mencocokkan ke NAMA NASABAH, JENIS BARANG (di dalam salah
/// satu item setoran itu), atau CATATAN — tiga hal yang paling mungkin
/// diingat petugas saat mencari kunjungan tertentu.
final filteredSetoranProvider = Provider<AsyncValue<List<SetoranModel>>>((ref) {
  final asyncResult = ref.watch(setoranStreamProvider);
  final periode = ref.watch(selectedPeriodeRekapProvider);
  final query = ref.watch(searchQuerySampahProvider).trim().toLowerCase();

  return asyncResult.whenData((result) {
    var items = result.items.where((s) => dalamPeriode(s.tanggal, periode)).toList();

    if (query.isNotEmpty) {
      items = items.where((s) {
        final namaCocok = s.nasabahNama.toLowerCase().contains(query);
        final catatanCocok = (s.catatan ?? '').toLowerCase().contains(query);
        final itemCocok = s.items.any((i) => i.jenisBarang.toLowerCase().contains(query));
        return namaCocok || catatanCocok || itemCocok;
      }).toList();
    }

    return items;
  });
});

/// Satu baris rekap: satu jenis barang dengan total pada periode+
/// pencarian yang dipilih, LENGKAP dengan satuannya (kg atau buah).
///
/// PENTING: dikelompokkan per (jenisBarang + satuan), BUKAN per
/// jenisBarang saja — supaya kg dan buah TIDAK PERNAH tercampur jadi
/// satu angka yang salah makna (lihat catatan lengkap di
/// setoran_model.dart soal denormalisasi satuan per item).
class RekapJenisBarang {
  final String jenisBarang;
  final SatuanBarang satuan;
  final double totalJumlah;
  final double totalNilai;

  const RekapJenisBarang({
    required this.jenisBarang,
    required this.satuan,
    required this.totalJumlah,
    required this.totalNilai,
  });
}

/// Rekap total per jenis barang — diturunkan dengan MERATAKAN (flatten)
/// semua item di dalam semua setoran yang lolos filter periode+
/// pencarian. Berguna untuk kebutuhan "jual ke pengepul" (total kg per
/// jenis, terlepas dari nasabah mana asalnya).
final rekapSampahProvider = Provider<AsyncValue<List<RekapJenisBarang>>>((ref) {
  final asyncSetoran = ref.watch(filteredSetoranProvider);

  return asyncSetoran.whenData((daftarSetoran) {
    final totalJumlahPerKombinasi = <String, double>{};
    final totalNilaiPerKombinasi = <String, double>{};
    final satuanPerKombinasi = <String, SatuanBarang>{};
    final namaPerKombinasi = <String, String>{};

    for (final setoran in daftarSetoran) {
      for (final item in setoran.items) {
        final key = '${item.jenisBarang}|${item.satuan.name}';
        totalJumlahPerKombinasi[key] = (totalJumlahPerKombinasi[key] ?? 0) + item.jumlah;
        totalNilaiPerKombinasi[key] = (totalNilaiPerKombinasi[key] ?? 0) + item.subtotal;
        satuanPerKombinasi[key] = item.satuan;
        namaPerKombinasi[key] = item.jenisBarang;
      }
    }

    final hasil = totalJumlahPerKombinasi.keys.map((key) {
      return RekapJenisBarang(
        jenisBarang: namaPerKombinasi[key]!,
        satuan: satuanPerKombinasi[key]!,
        totalJumlah: totalJumlahPerKombinasi[key]!,
        totalNilai: totalNilaiPerKombinasi[key]!,
      );
    }).toList();

    // Urut dari NILAI RUPIAH terbesar — paling relevan bagi pengurus
    // (jenis barang yang paling banyak menyumbang nilai, bukan cuma
    // yang paling banyak beratnya).
    hasil.sort((a, b) => b.totalNilai.compareTo(a.totalNilai));

    return hasil;
  });
});

/// Total keseluruhan NILAI RUPIAH pada periode+pencarian terpilih —
/// SATU angka (beda dari versi sebelumnya yang harus dipisah kg/buah),
/// karena Rupiah adalah satuan yang SAMA untuk semua jenis barang,
/// tidak seperti kg vs buah yang tidak bisa dijumlahkan langsung.
final totalNilaiPeriodeProvider = Provider<AsyncValue<double>>((ref) {
  final asyncRekap = ref.watch(rekapSampahProvider);
  return asyncRekap.whenData((daftar) => daftar.fold<double>(0, (sum, r) => sum + r.totalNilai));
});
