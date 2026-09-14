import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

import '../models/user_model.dart';
import 'export_data_builder.dart';

class ExportService {
  static Future<void> exportUserData(UserModel user) async {
    final jsonStr  = await buildExportJson(user);
    final bytes    = Uint8List.fromList(jsonStr.codeUnits);
    final filename = exportFilename();

    final blob = web.Blob(
      [bytes.toJS].toJS,
      web.BlobPropertyBag(type: 'application/json'),
    );
    final url = web.URL.createObjectURL(blob);

    (web.document.createElement('a') as web.HTMLAnchorElement)
      ..href     = url
      ..download = filename
      ..click();

    web.URL.revokeObjectURL(url);
  }
}
