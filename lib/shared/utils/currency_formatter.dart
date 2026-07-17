import 'package:intl/intl.dart';

/// Formatter Rupiah terpusat — dipakai di semua tempat yang menampilkan
/// nilai uang (buku tabungan nasabah, form input setoran, laporan
/// PDF/Excel). Satu implementasi, supaya format konsisten di seluruh
/// aplikasi (titik ribuan, tanpa desimal karena Rupiah tidak lazim
/// pakai sen).
final _format = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);

String formatRupiah(double nilai) => _format.format(nilai);
