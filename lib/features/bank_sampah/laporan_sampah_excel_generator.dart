import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import '../../models/jenis_barang_model.dart';
import '../../models/setoran_model.dart';
import 'rekap_sampah_provider.dart';

class LaporanSampahExcelGenerator {
  static final _dateFormat = DateFormat('dd/MM/yyyy', 'id_ID');

  // Helper konversi tipe data standar ke CellValue (Wajib untuk Excel 4.0.0+)
  static CellValue _getCellValue(Object? value) {
    if (value is String) return TextCellValue(value);
    if (value is double) return DoubleCellValue(value);
    if (value is int) return IntCellValue(value);
    return TextCellValue(value?.toString() ?? '');
  }

  static List<int> generateLaporan({
    required List<RekapJenisBarang> rekap,
    required List<SetoranModel> riwayat,
    required String labelPeriode,
  }) {
    final excel = Excel.createExcel();
    final defaultSheetName = excel.getDefaultSheet();

    _tulisSheetRekapJenis(excel['Rekap Jenis'], rekap);
    _tulisSheetRekapNasabah(excel['Rekap Nasabah'], riwayat);
    _tulisSheetRincian(excel['Rincian Setoran'], riwayat);

    const namaSheetBaru = ['Rekap Jenis', 'Rekap Nasabah', 'Rincian Setoran'];
    if (defaultSheetName != null && !namaSheetBaru.contains(defaultSheetName)) {
      excel.delete(defaultSheetName);
    }

    return excel.encode()!;
  }

  static void _tulisSheetRekapJenis(Sheet sheet, List<RekapJenisBarang> rekap) {
    // FIX: Gunakan ExcelColor.fromHexString
    final headerStyle = CellStyle(bold: true, backgroundColorHex: ExcelColor.fromHexString('#D9D9D9'));

    final headers = ['Jenis Barang', 'Satuan', 'Total Jumlah', 'Total Nilai (Rp)'];
    for (var col = 0; col < headers.length; col++) {
      final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: 0));
      // FIX: Gunakan TextCellValue
      cell.value = TextCellValue(headers[col]);
      cell.cellStyle = headerStyle;
    }

    for (var row = 0; row < rekap.length; row++) {
      final r = rekap[row];
      final rowIndex = row + 1;
      final values = [r.jenisBarang, r.satuan.label, r.totalJumlah.toDouble(), r.totalNilai.toDouble()];
      for (var col = 0; col < values.length; col++) {
        // FIX: Wrap dynamic values menggunakan _getCellValue
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: rowIndex)).value =
            _getCellValue(values[col]);
      }
    }

    // FIX: setColWidth berubah menjadi setColumnWidth di versi 4.0.0+
    sheet.setColumnWidth(0, 24.0);
    sheet.setColumnWidth(1, 12.0);
    sheet.setColumnWidth(2, 14.0);
    sheet.setColumnWidth(3, 16.0);
  }

  static void _tulisSheetRekapNasabah(Sheet sheet, List<SetoranModel> riwayat) {
    final headerStyle = CellStyle(bold: true, backgroundColorHex: ExcelColor.fromHexString('#D9D9D9'));

    final headers = ['Nasabah', 'Jumlah Kunjungan', 'Total Nilai (Rp)'];
    for (var col = 0; col < headers.length; col++) {
      final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: 0));
      cell.value = TextCellValue(headers[col]);
      cell.cellStyle = headerStyle;
    }

    final totalPerNasabah = <String, double>{};
    final jumlahPerNasabah = <String, int>{};
    for (final s in riwayat) {
      totalPerNasabah[s.nasabahNama] = (totalPerNasabah[s.nasabahNama] ?? 0) + s.totalNilai;
      jumlahPerNasabah[s.nasabahNama] = (jumlahPerNasabah[s.nasabahNama] ?? 0) + 1;
    }

    final entries = totalPerNasabah.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    for (var row = 0; row < entries.length; row++) {
      final e = entries[row];
      final rowIndex = row + 1;
      final values = [e.key, jumlahPerNasabah[e.key]!.toDouble(), e.value.toDouble()];
      for (var col = 0; col < values.length; col++) {
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: rowIndex)).value =
            _getCellValue(values[col]);
      }
    }

    sheet.setColumnWidth(0, 24.0);
    sheet.setColumnWidth(1, 16.0);
    sheet.setColumnWidth(2, 16.0);
  }

  static void _tulisSheetRincian(Sheet sheet, List<SetoranModel> riwayat) {
    final headerStyle = CellStyle(bold: true, backgroundColorHex: ExcelColor.fromHexString('#D9D9D9'));

    final headers = [
      'Tanggal',
      'Nasabah',
      'Jenis Barang',
      'Jumlah',
      'Satuan',
      'Harga Satuan (Rp)',
      'Subtotal (Rp)',
      'Catatan',
    ];
    for (var col = 0; col < headers.length; col++) {
      final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: 0));
      cell.value = TextCellValue(headers[col]);
      cell.cellStyle = headerStyle;
    }

    var rowIndex = 1;
    for (final s in riwayat) {
      for (final item in s.items) {
        final values = [
          _dateFormat.format(s.tanggal),
          s.nasabahNama,
          item.jenisBarang,
          item.jumlah.toDouble(),
          item.satuan.label,
          item.harga.toDouble(),
          item.subtotal.toDouble(),
          s.catatan ?? '-',
        ];
        for (var col = 0; col < values.length; col++) {
          sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: rowIndex)).value =
              _getCellValue(values[col]);
        }
        rowIndex++;
      }
    }

    sheet.setColumnWidth(0, 14.0);
    sheet.setColumnWidth(1, 20.0);
    sheet.setColumnWidth(2, 18.0);
    sheet.setColumnWidth(3, 10.0);
    sheet.setColumnWidth(4, 10.0);
    sheet.setColumnWidth(5, 16.0);
    sheet.setColumnWidth(6, 16.0);
    sheet.setColumnWidth(7, 20.0);
  }
}