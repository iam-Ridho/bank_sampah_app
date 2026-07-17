import 'package:printing/printing.dart';
import '../../models/setoran_model.dart';
import '../../shared/excel/excel_saver.dart'
    if (dart.library.html) '../../shared/excel/excel_saver_web.dart'
    if (dart.library.io) '../../shared/excel/excel_saver_io.dart';
import 'laporan_sampah_excel_generator.dart';
import 'laporan_sampah_pdf_generator.dart';
import 'rekap_sampah_provider.dart';

/// Service cetak & export laporan Bank Sampah — memakai
/// `shared/excel/excel_saver.dart` (conditional import web/mobile untuk
/// export Excel yang aman di kedua platform), utilitas independen yang
/// dipakai bersama oleh fitur laporan mana pun di aplikasi ini.
///
/// Tetap 100% OFFLINE untuk generate & tulis file lokal — internet
/// hanya dibutuhkan kalau user pilih "bagikan ke WhatsApp/email" dari
/// share sheet OS setelahnya.
class LaporanSampahService {
  /// Cetak langsung — membuka dialog pemilihan printer dari OS.
  static Future<bool> cetakLaporan({
    required List<RekapJenisBarang> rekap,
    required List<SetoranModel> riwayat,
    required String labelPeriode,
    String? namaPenyusun,
  }) async {
    final pdf = await LaporanSampahPdfGenerator.generateLaporan(
      rekap: rekap,
      riwayat: riwayat,
      labelPeriode: labelPeriode,
      namaPenyusun: namaPenyusun,
    );

    return Printing.layoutPdf(
      onLayout: (format) => pdf.save(),
      name: 'Laporan Bank Sampah - $labelPeriode',
    );
  }

  /// Preview PDF sebelum cetak/bagikan — berguna untuk verifikasi data
  /// sebelum benar-benar dicetak fisik atau dikirim ke ketua.
  static Future<void> previewLaporan({
    required List<RekapJenisBarang> rekap,
    required List<SetoranModel> riwayat,
    required String labelPeriode,
    String? namaPenyusun,
  }) async {
    final pdf = await LaporanSampahPdfGenerator.generateLaporan(
      rekap: rekap,
      riwayat: riwayat,
      labelPeriode: labelPeriode,
      namaPenyusun: namaPenyusun,
    );

    await Printing.layoutPdf(onLayout: (format) => pdf.save());
  }

  /// Simpan/bagikan PDF — fallback paling aman kalau printer tidak
  /// tersedia; ketua bisa terima file PDF lewat WhatsApp langsung.
  static Future<void> simpanPdfLokal({
    required List<RekapJenisBarang> rekap,
    required List<SetoranModel> riwayat,
    required String labelPeriode,
    String? namaPenyusun,
  }) async {
    final pdf = await LaporanSampahPdfGenerator.generateLaporan(
      rekap: rekap,
      riwayat: riwayat,
      labelPeriode: labelPeriode,
      namaPenyusun: namaPenyusun,
    );

    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: 'Laporan_Bank_Sampah_${labelPeriode.replaceAll(' ', '_')}.pdf',
    );
  }

  /// Export & bagikan Excel — tiga sheet (Rekap Jenis, Rekap Nasabah, Rincian).
  static Future<void> exportExcel({
    required List<RekapJenisBarang> rekap,
    required List<SetoranModel> riwayat,
    required String labelPeriode,
  }) async {
    final bytes = LaporanSampahExcelGenerator.generateLaporan(
      rekap: rekap,
      riwayat: riwayat,
      labelPeriode: labelPeriode,
    );

    final filename = 'Laporan_Bank_Sampah_${labelPeriode.replaceAll(' ', '_')}.xlsx';
    final judul = 'Laporan Bank Sampah - $labelPeriode';

    await saveAndShareExcel(bytes: bytes, filename: filename, judulLaporan: judul);
  }
}
