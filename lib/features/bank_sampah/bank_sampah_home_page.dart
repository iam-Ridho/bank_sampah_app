import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../auth/auth_provider.dart';
import '../bantuan/bantuan_screen.dart';
import '../nasabah/nasabah_list_screen.dart';
import 'input_sampah_tab.dart';
import 'riwayat_rekap_tab.dart';

/// Halaman utama Bank Sampah — home widget utama aplikasi (lihat
/// main.dart). TIGA tab: Input (catat setoran baru), Riwayat & Rekap,
/// dan Nasabah (CRUD + akses buku tabungan). Nasabah ditambahkan
/// sebagai tab tersendiri (bukan cuma diakses lewat picker) karena
/// sekarang jadi entitas SENTRAL — setiap setoran wajib terhubung ke
/// nasabah, jadi mengelola daftar nasabah (tambah/edit/hapus, lihat
/// riwayat per orang) perlu jalur akses yang jelas & mandiri.
class BankSampahHomePage extends ConsumerStatefulWidget {
  const BankSampahHomePage({super.key});

  @override
  ConsumerState<BankSampahHomePage> createState() => _BankSampahHomePageState();
}

class _BankSampahHomePageState extends ConsumerState<BankSampahHomePage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bank Sampah'),
        actions: [
          IconButton(
            tooltip: 'Bantuan',
            icon: const Icon(Icons.help_outline),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const BantuanScreen()),
            ),
          ),
          IconButton(
            tooltip: 'Keluar',
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authControllerProvider.notifier).signOut(),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Input', icon: Icon(Icons.add_box_outlined)),
            Tab(text: 'Riwayat & Rekap', icon: Icon(Icons.bar_chart_outlined)),
            Tab(text: 'Nasabah', icon: Icon(Icons.groups_outlined)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          InputSampahTab(),
          RiwayatRekapTab(),
          NasabahListScreen(),
        ],
      ),
    );
  }
}
