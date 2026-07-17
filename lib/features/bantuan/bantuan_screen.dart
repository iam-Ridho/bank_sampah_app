import 'package:flutter/material.dart';
import '../../shared/theme/app_theme.dart';

/// Satu topik bantuan — ikon + judul + langkah-langkah bernomor.
/// Sengaja PURE DATA terpisah dari widget, supaya konten mudah diedit
/// tanpa perlu menyentuh logic tampilan.
class _TopikBantuan {
  final IconData icon;
  final Color warna;
  final String judul;
  final List<String> langkah;

  const _TopikBantuan({
    required this.icon,
    required this.warna,
    required this.judul,
    required this.langkah,
  });
}

/// Daftar topik bantuan — EDIT DI SINI kalau perlu menambah/mengubah
/// panduan. Bahasa sengaja dibuat sangat sederhana dan langkah-per-langkah,
/// menghindari istilah teknis (sync, cache, dll) — cukup jelaskan APA
/// yang terjadi dan APA yang harus dilakukan pengguna.
const List<_TopikBantuan> _topikBantuan = [
  _TopikBantuan(
    icon: Icons.add_box_outlined,
    warna: AppColors.green800,
    judul: 'Cara Mencatat Setoran Baru',
    langkah: [
      'Buka tab "Input" di bagian atas.',
      'Ketuk kotak "Nasabah" untuk mencari nasabah yang datang. Kalau belum terdaftar, ketuk tombol "Baru" untuk mendaftarkan langsung.',
      'Ketuk tombol "Tambah Item" untuk tiap jenis barang yang dibawa nasabah (mis. Kardus, Botol Kaca, dst).',
      'Pilih jenisnya, lalu isi jumlahnya (kg atau buah, tergantung jenis barangnya). Nilai uangnya akan dihitung OTOMATIS sesuai harga saat ini.',
      'Ulangi "Tambah Item" untuk semua barang yang dibawa nasabah itu — bisa berkali-kali dalam satu kunjungan.',
      'Setelah semua barang tercatat, lihat total di bagian bawah layar, lalu ketuk "Simpan Setoran".',
      'Data akan tersimpan walaupun HP tidak ada sinyal internet — nanti otomatis terkirim saat ada sinyal.',
    ],
  ),
  _TopikBantuan(
    icon: Icons.groups_outlined,
    warna: AppColors.blue,
    judul: 'Cara Mengelola Data Nasabah',
    langkah: [
      'Buka tab "Nasabah" di bagian atas.',
      'Ketuk tombol (+) di pojok kanan bawah untuk mendaftarkan nasabah baru.',
      'Ketuk ikon pensil di sebelah nama untuk mengubah data nasabah (nama, alamat, no. HP).',
      'Geser (swipe) nama nasabah ke kiri untuk menghapusnya dari daftar — riwayat setoran yang sudah tercatat sebelumnya TIDAK ikut terhapus.',
      'Ketuk nama nasabah untuk membuka "Buku Tabungan"-nya — riwayat semua setoran dan total nilai yang pernah diterima nasabah itu.',
    ],
  ),
  _TopikBantuan(
    icon: Icons.edit_outlined,
    warna: AppColors.slate,
    judul: 'Cara Mengubah atau Menghapus Riwayat Setoran',
    langkah: [
      'Buka tab "Riwayat & Rekap".',
      'Untuk MENGUBAH setoran: ketuk (tap) kartu setoran yang ingin diubah — bisa ganti nasabah, tanggal, tambah/hapus item, atau ubah jumlahnya.',
      'Untuk MENGHAPUS SELURUH setoran: geser (swipe) kartu setoran ke arah kiri, lalu ketuk "Hapus" pada kotak konfirmasi.',
      'Data yang sudah dihapus TIDAK BISA dikembalikan — pastikan dulu sebelum menghapus.',
    ],
  ),
  _TopikBantuan(
    icon: Icons.repeat_outlined,
    warna: AppColors.green700,
    judul: 'Nasabah Pulang-Balik Ambil Sisa Barang',
    langkah: [
      'Kalau nasabah datang bawa sebagian barang, lalu pulang dulu mau ambil sisanya — TIDAK PERLU dibatalkan. Simpan saja dulu barang yang sudah dibawa seperti biasa.',
      'Sambil menunggu nasabah itu balik, nasabah LAIN yang datang bisa langsung dilayani di tab Input — tidak perlu menunggu.',
      'Saat nasabah pertama balik bawa sisa barangnya, pilih namanya lagi di tab Input seperti biasa.',
      'Aplikasi akan otomatis memberi tahu kalau nasabah itu sudah punya catatan hari ini, dan menawarkan untuk menambahkan sisa barangnya ke catatan yang sama.',
      'Pilih "Tambahkan ke Situ" supaya semua barang nasabah itu (dari kunjungan pertama dan kedua) tergabung jadi satu catatan yang rapi.',
    ],
  ),
  _TopikBantuan(
    icon: Icons.search,
    warna: AppColors.orange,
    judul: 'Cara Mencari Data',
    langkah: [
      'Buka tab "Riwayat & Rekap".',
      'Ketik kata kunci di kotak pencarian — bisa nama nasabah (mis. "Budi"), jenis barang (mis. "kardus"), atau catatan yang pernah diisi.',
      'Bisa juga ketuk salah satu tombol periode (Hari Ini, Minggu Ini, Bulan Ini, Semua) untuk mempersempit ke rentang waktu tertentu.',
      'Pencarian dan periode bisa dipakai BERSAMAAN untuk hasil yang lebih spesifik.',
    ],
  ),
  _TopikBantuan(
    icon: Icons.picture_as_pdf_outlined,
    warna: AppColors.red,
    judul: 'Cara Membuat dan Membagikan Laporan',
    langkah: [
      'Buka tab "Riwayat & Rekap" (boleh sambil aktif filter periode/pencarian tertentu).',
      'Ketuk tombol "Cetak" untuk langsung mencetak ke printer yang terhubung.',
      'Ketuk ikon berbagi (Share) untuk memilih "Bagikan PDF" atau "Export Excel".',
      'File berisi rekap per jenis barang, rekap per nasabah, dan rincian setiap setoran — bisa dibagikan lewat WhatsApp, email, atau disimpan ke HP.',
      'Semua proses ini BISA dilakukan tanpa sinyal internet — internet hanya dibutuhkan kalau ingin mengirim file ke orang lain.',
    ],
  ),
  _TopikBantuan(
    icon: Icons.sell_outlined,
    warna: AppColors.gold,
    judul: 'Cara Mengelola Jenis Barang dan Harga',
    langkah: [
      'Saat memilih jenis barang di tab Input, ketuk ikon gerigi (⚙️) di pojok kanan atas untuk membuka "Kelola Jenis Barang".',
      'Ketuk ikon pensil untuk mengubah nama, satuan (kg/buah), atau harga suatu jenis barang.',
      'PENTING: mengubah harga HANYA berlaku untuk setoran BARU ke depannya. Setoran yang SUDAH tercatat sebelumnya tetap memakai harga saat itu dicatat, tidak berubah.',
      'Harga jual di gudang biasanya berubah tiap minggu — perbarui harga di sini setiap kali ada perubahan, supaya perhitungan setoran baru selalu akurat.',
    ],
  ),
  _TopikBantuan(
    icon: Icons.wifi_off_outlined,
    warna: AppColors.gray500,
    judul: 'Memakai Aplikasi Tanpa Sinyal Internet',
    langkah: [
      'Aplikasi ini SENGAJA dirancang untuk bisa dipakai tanpa sinyal internet.',
      'Anda tetap bisa: mencatat setoran, mengelola nasabah, mengubah/menghapus data, dan membuat laporan PDF/Excel — semua tanpa internet.',
      'Yang BUTUH internet hanya: masuk/login pertama kali, dan mengirim file laporan ke WhatsApp/email.',
      'Kalau baru pertama kali memakai HP ini dan tidak ada sinyal sama sekali, data lama mungkin belum terlihat — sambungkan ke internet sebentar saja untuk mengunduh data yang sudah ada.',
    ],
  ),
];

/// Halaman Bantuan — diakses lewat ikon (?) di pojok kanan atas HomePage.
/// Tujuannya MENGURANGI beban pengelola aplikasi sebagai "tempat bertanya
/// 24 jam" — anggota kelompok tani bisa cari jawaban sendiri di sini
/// dulu sebelum bertanya langsung.
class BantuanScreen extends StatelessWidget {
  const BantuanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.gray100,
      appBar: AppBar(title: const Text('Bantuan')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: AppColors.green50,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: AppColors.green700.withValues(alpha: 0.2)),
            ),
            child: const Row(
              children: [
                Icon(Icons.tips_and_updates_outlined, color: AppColors.green800),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Ketuk salah satu judul di bawah untuk melihat panduan langkah demi langkah.',
                    style: TextStyle(fontSize: 13, color: AppColors.green900),
                  ),
                ),
              ],
            ),
          ),
          ..._topikBantuan.map((topik) => _KartuTopikBantuan(topik: topik)),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _KartuTopikBantuan extends StatelessWidget {
  final _TopikBantuan topik;

  const _KartuTopikBantuan({required this.topik});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.md),
        boxShadow: AppShadows.card,
      ),
      child: Theme(
        // Hilangkan divider bawaan ExpansionTile supaya menyatu rapi
        // dengan style card di atas, tanpa garis tambahan yang tidak perlu.
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          shape: const RoundedRectangleBorder(side: BorderSide.none),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: topik.warna.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(topik.icon, color: topik.warna, size: 20),
          ),
          title: Text(
            topik.judul,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          children: [
            ...topik.langkah.asMap().entries.map(
                  (entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 22,
                          height: 22,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: topik.warna.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '${entry.key + 1}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: topik.warna,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            entry.value,
                            style: const TextStyle(fontSize: 13, height: 1.4),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}
