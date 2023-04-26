import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:synchronized/synchronized.dart';

class PhraseDiskCache {
  final Lock _lockDisk = Lock();

  Future<String> get _folder async {
    final directory = await getApplicationDocumentsDirectory();
    return "${directory.path}/.phrase";
  }

  Future<void> write(String fn, String contents) =>
      _lockDisk.synchronized(() async {
        String folder = await _folder;
        File file = File("$folder/$fn");
        file.create(recursive: true).then((f) => f.writeAsString(contents));
      });

  Future<String?> read(String fn) => _lockDisk.synchronized(() async {
        String folder = await _folder;
        File file = File("$folder/$fn");
        if (await file.exists()) {
          return await file.readAsString();
        }
        return null;
      });
}
