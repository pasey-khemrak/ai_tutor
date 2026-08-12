import 'dart:async';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

Future<Uint8List?> pickLocalProfileImage() async {
  final input = web.HTMLInputElement()
    ..type = 'file'
    ..accept = 'image/*'
    ..multiple = false;

  final changeCompleter = Completer<void>();
  late JSFunction changeListener;
  changeListener = ((web.Event event) {
    input.removeEventListener('change', changeListener);
    changeCompleter.complete();
  }).toJS;

  input.addEventListener('change', changeListener);
  input.click();
  await changeCompleter.future;

  final files = input.files;
  if (files == null || files.length == 0) return null;

  final file = files.item(0);
  if (file == null) return null;

  final buffer = await file.arrayBuffer().toDart;
  return buffer.toDart.asUint8List();
}
