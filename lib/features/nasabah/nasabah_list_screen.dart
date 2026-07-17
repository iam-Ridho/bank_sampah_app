import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/nasabah_model.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/app_state_widgets.dart';
import 'nasabah_form_sheet.dart';
import 'nasabah_ledger_screen.dart';
import 'nasabah_repository.dart';

/// Halaman Daftar Nasabah — CRUD lengkap (tambah/edit/hapus), TAP satu
/// nasabah untuk buka "buku tabungan"-nya (riwayat setoran + total
/// nilai yang pernah diterima, lihat nasabah_ledger_screen.dart).
///
/// CATATAN: TIDAK punya AppBar sendiri — dipakai sebagai TAB di dalam
/// BankSampahHomePage yang sudah punya AppBar sendiri ("Bank Sampah").
/// Scaffold di sini tetap dipakai (tanpa `appBar:`) khusus supaya
/// FloatingActionButton tetap terposisi benar di dalam area tab ini.
class NasabahListScreen extends ConsumerStatefulWidget {
  const NasabahListScreen({super.key});

  @override
  ConsumerState<NasabahListScreen> createState() => _NasabahListScreenState();
}

class _NasabahListScreenState extends ConsumerState<NasabahListScreen> {
  String _kataKunci = '';

  @override
  Widget build(BuildContext context) {
    final asyncResult = ref.watch(nasabahStreamProvider);

    return Scaffold(
      backgroundColor: AppColors.gray100,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Cari nama nasabah...',
                prefixIcon: Icon(Icons.search, size: 20),
                isDense: true,
              ),
              onChanged: (v) => setState(() => _kataKunci = v),
            ),
          ),
          Expanded(
            child: asyncResult.when(
              loading: () => const AppLoadingState(),
              error: (_, __) => const AppErrorState(message: 'Gagal memuat data nasabah.'),
              data: (result) {
                final query = _kataKunci.trim().toLowerCase();
                final items = query.isEmpty
                    ? result.items
                    : result.items.where((n) => n.nama.toLowerCase().contains(query)).toList();

                if (items.isEmpty) {
                  return AppEmptyState(
                    icon: Icons.groups_outlined,
                    message: result.items.isEmpty
                        ? 'Belum ada nasabah terdaftar.\nTekan tombol + untuk menambah nasabah pertama.'
                        : 'Tidak ada nasabah yang cocok dengan pencarian ini.',
                  );
                }

                return ListView.builder(
                  padding: EdgeInsets.fromLTRB(
                    12,
                    0,
                    12,
                    // Padding bawah aman + ruang ekstra untuk FAB, supaya
                    // item terakhir tidak tertutup navigation bar sistem
                    // maupun FloatingActionButton — pola sama dengan
                    // layar lain di aplikasi ini.
                    72 + MediaQuery.paddingOf(context).bottom,
                  ),
                  itemCount: items.length,
                  itemBuilder: (context, index) => _NasabahListItem(nasabah: items[index]),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showNasabahFormSheet(context),
        tooltip: 'Tambah Nasabah',
        child: const Icon(Icons.person_add_outlined),
      ),
    );
  }
}

class _NasabahListItem extends ConsumerWidget {
  final NasabahModel nasabah;

  const _NasabahListItem({required this.nasabah});

  Future<bool> _konfirmasiHapus(BuildContext context) async {
    final hasil = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Nasabah?'),
        content: Text(
          'Data nasabah "${nasabah.nama}" akan dihapus permanen. '
          'Riwayat setoran yang sudah tercatat sebelumnya TIDAK ikut terhapus.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Batal')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.red),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    return hasil ?? false;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Dismissible(
      key: ValueKey(nasabah.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) => _konfirmasiHapus(context),
      onDismissed: (_) async {
        await ref.read(nasabahRepositoryProvider).hapusNasabah(nasabah.id);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('"${nasabah.nama}" dihapus dari daftar nasabah')),
          );
        }
      },
      background: Container(
        color: AppColors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.md),
          boxShadow: AppShadows.card,
        ),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: AppColors.green100,
            child: Text(
              nasabah.nama.isNotEmpty ? nasabah.nama[0].toUpperCase() : '?',
              style: const TextStyle(color: AppColors.green900, fontWeight: FontWeight.bold),
            ),
          ),
          title: Text(nasabah.nama, style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: nasabah.noHp != null && nasabah.noHp!.isNotEmpty
              ? Text(nasabah.noHp!, style: const TextStyle(fontSize: 12))
              : null,
          trailing: IconButton(
            icon: const Icon(Icons.edit_outlined, size: 20),
            onPressed: () => showNasabahFormSheet(context, existing: nasabah),
          ),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => NasabahLedgerScreen(nasabah: nasabah)),
          ),
        ),
      ),
    );
  }
}
