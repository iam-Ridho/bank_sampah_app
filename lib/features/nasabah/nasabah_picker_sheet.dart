import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/nasabah_model.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/app_state_widgets.dart';
import 'nasabah_form_sheet.dart';
import 'nasabah_repository.dart';

/// Bottom sheet pencarian + pilih nasabah — dipakai saat mulai input
/// setoran. Petugas bisa CARI nasabah lama, atau langsung TAMBAH BARU
/// dari sini kalau warga yang datang belum pernah terdaftar (sesuai
/// kebutuhan: "yang baru menjadi nasabah bisa tambah baru").
Future<NasabahModel?> showNasabahPickerSheet(BuildContext context) {
  return showModalBottomSheet<NasabahModel>(
    context: context,
    isScrollControlled: true,
    builder: (context) => const _NasabahPickerSheet(),
  );
}

class _NasabahPickerSheet extends ConsumerStatefulWidget {
  const _NasabahPickerSheet();

  @override
  ConsumerState<_NasabahPickerSheet> createState() => _NasabahPickerSheetState();
}

class _NasabahPickerSheetState extends ConsumerState<_NasabahPickerSheet> {
  String _kataKunci = '';

  Future<void> _tambahBaru() async {
    final hasil = await showNasabahFormSheet(context);
    if (hasil != null && mounted) Navigator.of(context).pop(hasil);
  }

  @override
  Widget build(BuildContext context) {
    final asyncResult = ref.watch(nasabahStreamProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
              child: Row(
                children: [
                  const Text('Pilih Nasabah',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: const InputDecoration(
                        hintText: 'Cari nama nasabah...',
                        prefixIcon: Icon(Icons.search, size: 20),
                        isDense: true,
                      ),
                      onChanged: (v) => setState(() => _kataKunci = v),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: _tambahBaru,
                    icon: const Icon(Icons.person_add_outlined, size: 18),
                    label: const Text('Baru'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: asyncResult.when(
                loading: () => const AppLoadingState(),
                error: (_, __) => const AppErrorState(message: 'Gagal memuat daftar nasabah.'),
                data: (result) {
                  final query = _kataKunci.trim().toLowerCase();
                  final items = query.isEmpty
                      ? result.items
                      : result.items.where((n) => n.nama.toLowerCase().contains(query)).toList();

                  if (items.isEmpty) {
                    return AppEmptyState(
                      icon: Icons.person_search_outlined,
                      message: query.isEmpty
                          ? 'Belum ada nasabah terdaftar.\nTekan "Baru" untuk mendaftarkan.'
                          : 'Tidak ditemukan nasabah bernama "$_kataKunci".\nTekan "Baru" untuk mendaftarkan.',
                    );
                  }

                  return ListView.builder(
                    controller: scrollController,
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final nasabah = items[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppColors.green100,
                          child: Text(
                            nasabah.nama.isNotEmpty ? nasabah.nama[0].toUpperCase() : '?',
                            style: const TextStyle(
                              color: AppColors.green900,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(nasabah.nama),
                        subtitle: nasabah.noHp != null && nasabah.noHp!.isNotEmpty
                            ? Text(nasabah.noHp!, style: const TextStyle(fontSize: 12))
                            : null,
                        onTap: () => Navigator.of(context).pop(nasabah),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
