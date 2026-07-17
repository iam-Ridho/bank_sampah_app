import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import '../../models/jenis_barang_model.dart';
import '../../models/setoran_model.dart';
import '../../shared/utils/currency_formatter.dart';
import 'rekap_sampah_provider.dart';

/// Generator PDF laporan Bank Sampah — untuk dilaporkan ke ketua.
/// Berisi TIGA bagian: (1) rekap total per jenis barang, (2) rekap
/// total per nasabah (akuntabilitas — siapa menerima berapa), dan
/// (3) rincian setiap setoran (kunjungan) pada periode terpilih.
class LaporanSampahPdfGenerator {
  static final _dateFormat = DateFormat('dd MMMM yyyy', 'id_ID');
  static final _dateTimeFormat = DateFormat('dd MMM yyyy HH:mm', 'id_ID');

  static Future<pw.Document> generateLaporan({
    required List<RekapJenisBarang> rekap,
    required List<SetoranModel> riwayat,
    required String labelPeriode,
    String? namaPenyusun,
  }) async {
    final pdf = pw.Document();
    final totalNilai = rekap.fold<double>(0, (sum, r) => sum + r.totalNilai);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => _buildHeader(labelPeriode, namaPenyusun, totalNilai),
        footer: (context) => _buildFooter(context),
        build: (context) => [
          pw.SizedBox(height: 12),
          _buildRekapJenisSection(rekap),
          pw.SizedBox(height: 20),
          _buildRekapNasabahSection(riwayat),
          pw.SizedBox(height: 20),
          _buildRiwayatSection(riwayat),
        ],
      ),
    );

    return pdf;
  }

  static pw.Widget _buildHeader(String labelPeriode, String? namaPenyusun, double totalNilai) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Laporan Bank Sampah - $labelPeriode',
          style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          'Total Nilai: ${formatRupiah(totalNilai)}',
          style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.green800),
        ),
        pw.SizedBox(height: 2),
        pw.Text(
          'Dicetak: ${_dateTimeFormat.format(DateTime.now())}'
          '${namaPenyusun != null ? ' oleh $namaPenyusun' : ''}',
          style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
        ),
        pw.Divider(thickness: 1),
      ],
    );
  }

  static pw.Widget _buildFooter(pw.Context context) {
    return pw.Container(
      alignment: pw.Alignment.centerRight,
      child: pw.Text(
        'Halaman ${context.pageNumber} dari ${context.pagesCount}',
        style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
      ),
    );
  }

  static pw.Widget _buildRekapJenisSection(List<RekapJenisBarang> rekap) {
    if (rekap.isEmpty) {
      return pw.Text(
        'Belum ada data pada periode ini.',
        style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
      );
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('Rekap per Jenis Barang',
            style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 6),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
          columnWidths: const {
            0: pw.FlexColumnWidth(2.5),
            1: pw.FlexColumnWidth(1.5),
            2: pw.FlexColumnWidth(1.5),
          },
          children: [
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey200),
              children: [
                _cell('Jenis Barang', bold: true),
                _cell('Jumlah', bold: true, alignRight: true),
                _cell('Nilai', bold: true, alignRight: true),
              ],
            ),
            ...rekap.map((r) => pw.TableRow(
                  children: [
                    _cell(r.jenisBarang),
                    _cell(
                      r.satuan == SatuanBarang.kg
                          ? '${r.totalJumlah.toStringAsFixed(1)} kg'
                          : r.satuan == SatuanBarang.liter
                              ? '${r.totalJumlah.toStringAsFixed(1)} liter'
                              : '${r.totalJumlah.toStringAsFixed(0)} buah',
                      alignRight: true,
                    ),
                    _cell(formatRupiah(r.totalNilai), alignRight: true),
                  ],
                )),
          ],
        ),
      ],
    );
  }

  /// Rekap per NASABAH — bagian BARU yang tidak ada di versi
  /// sebelumnya, penting untuk akuntabilitas: ketua bisa lihat siapa
  /// menerima nilai berapa dari total keseluruhan periode itu.
  static pw.Widget _buildRekapNasabahSection(List<SetoranModel> riwayat) {
    if (riwayat.isEmpty) return pw.SizedBox.shrink();

    final totalPerNasabah = <String, double>{};
    final jumlahSetoranPerNasabah = <String, int>{};
    for (final s in riwayat) {
      totalPerNasabah[s.nasabahNama] = (totalPerNasabah[s.nasabahNama] ?? 0) + s.totalNilai;
      jumlahSetoranPerNasabah[s.nasabahNama] = (jumlahSetoranPerNasabah[s.nasabahNama] ?? 0) + 1;
    }

    final entries = totalPerNasabah.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('Rekap per Nasabah',
            style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 6),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
          columnWidths: const {
            0: pw.FlexColumnWidth(2.5),
            1: pw.FlexColumnWidth(1),
            2: pw.FlexColumnWidth(1.5),
          },
          children: [
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey200),
              children: [
                _cell('Nasabah', bold: true),
                _cell('Kunjungan', bold: true, alignRight: true),
                _cell('Total Nilai', bold: true, alignRight: true),
              ],
            ),
            ...entries.map((e) => pw.TableRow(
                  children: [
                    _cell(e.key),
                    _cell('${jumlahSetoranPerNasabah[e.key]}x', alignRight: true),
                    _cell(formatRupiah(e.value), alignRight: true),
                  ],
                )),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildRiwayatSection(List<SetoranModel> riwayat) {
    if (riwayat.isEmpty) return pw.SizedBox.shrink();

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('Rincian Setoran',
            style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 6),
        ...riwayat.map((s) => pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 10),
              padding: const pw.EdgeInsets.all(8),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey400, width: 0.5),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(3)),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        '${s.nasabahNama} - ${_dateFormat.format(s.tanggal)}',
                        style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
                      ),
                      pw.Text(
                        formatRupiah(s.totalNilai),
                        style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 4),
                  ...s.items.map((item) => pw.Padding(
                        padding: const pw.EdgeInsets.only(left: 8, bottom: 2),
                        child: pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text(
                              '${item.jenisBarang} (${item.satuan == SatuanBarang.kg ? '${item.jumlah.toStringAsFixed(1)} kg' : item.satuan == SatuanBarang.liter ? '${item.jumlah.toStringAsFixed(1)} liter' : '${item.jumlah.toStringAsFixed(0)} buah'})',
                              style: const pw.TextStyle(fontSize: 8),
                            ),
                            pw.Text(formatRupiah(item.subtotal), style: const pw.TextStyle(fontSize: 8)),
                          ],
                        ),
                      )),
                  if (s.catatan != null && s.catatan!.isNotEmpty)
                    pw.Padding(
                      padding: const pw.EdgeInsets.only(top: 4),
                      child: pw.Text(
                        'Catatan: ${s.catatan}',
                        style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600, fontStyle: pw.FontStyle.italic),
                      ),
                    ),
                ],
              ),
            )),
      ],
    );
  }

  static pw.Widget _cell(String text, {bool bold = false, bool alignRight = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: pw.Text(
        text,
        textAlign: alignRight ? pw.TextAlign.right : pw.TextAlign.left,
        style: pw.TextStyle(
          fontSize: 9,
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }
}
