import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:file_picker/file_picker.dart';

class PickedFileResult {
  final String     name;
  final String?    path;   // solo móvil/desktop
  final Uint8List? bytes;  // solo web
  final bool       isValid;

  const PickedFileResult({
    required this.name,
    this.path,
    this.bytes,
    this.isValid = true,
  });

  static const PickedFileResult empty = PickedFileResult(name: '', isValid: false);
}

Future<PickedFileResult> pickAttachmentFile() async {
  final result = await FilePicker.pickFiles(
    type: FileType.custom,
    allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'doc', 'docx'],
    withData: kIsWeb,
    withReadStream: false,
  );

  if (result == null || result.files.isEmpty) return PickedFileResult.empty;
  final file = result.files.first;

  if (kIsWeb) {
    if (file.bytes == null) return PickedFileResult.empty;
    return PickedFileResult(name: file.name, bytes: file.bytes);
  } else {
    if (file.path == null) return PickedFileResult.empty;
    return PickedFileResult(name: file.name, path: file.path);
  }
}