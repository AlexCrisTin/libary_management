import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:image/image.dart' as img;

const int _maxDatabaseImageLength = 60000;

Future<String?> pickLocalImageAsDataUri() async {
  final result = await FilePicker.platform.pickFiles(
    type: FileType.image,
    allowMultiple: false,
    withData: true,
  );
  if (result == null) return null;

  final bytes = result.files.single.bytes;
  if (bytes == null || bytes.isEmpty) {
    throw const FormatException('Không đọc được nội dung ảnh đã chọn.');
  }

  final decoded = img.decodeImage(bytes);
  if (decoded == null) {
    throw const FormatException('Định dạng ảnh không được hỗ trợ.');
  }

  var current = img.bakeOrientation(decoded);
  if (current.width > 520 || current.height > 780) {
    current = img.copyResize(
      current,
      width: current.width >= current.height ? 520 : null,
      height: current.height > current.width ? 780 : null,
      interpolation: img.Interpolation.average,
    );
  }

  for (final quality in [72, 60, 48, 36]) {
    final encoded = Uint8List.fromList(
      img.encodeJpg(current, quality: quality),
    );
    final dataUri = 'data:image/jpeg;base64,${base64Encode(encoded)}';
    if (dataUri.length <= _maxDatabaseImageLength) return dataUri;
  }

  current = img.copyResize(current, width: 320);
  final encoded = Uint8List.fromList(img.encodeJpg(current, quality: 35));
  final dataUri = 'data:image/jpeg;base64,${base64Encode(encoded)}';
  if (dataUri.length > _maxDatabaseImageLength) {
    throw const FormatException('Ảnh quá lớn. Vui lòng chọn ảnh khác.');
  }
  return dataUri;
}

Uint8List? decodeDataImage(String? value) {
  if (value == null || !value.startsWith('data:image/')) return null;
  final comma = value.indexOf(',');
  if (comma < 0) return null;
  try {
    return base64Decode(value.substring(comma + 1));
  } catch (_) {
    return null;
  }
}
