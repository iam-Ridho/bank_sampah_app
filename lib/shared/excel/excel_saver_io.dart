import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

Future<void> saveAndShareExcel({
  required List<int> bytes,
  required String filename,
  required String judulLaporan,
}) async {
  final tempDir = await getTemporaryDirectory();
  final file = File('${tempDir.path}/$filename');
  await file.writeAsBytes(bytes);
  
  await Share.shareXFiles([XFile(file.path)], text: judulLaporan);
}
