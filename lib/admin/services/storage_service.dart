import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  final _storage = FirebaseStorage.instance;

  Future<String> uploadNewsImage({
    required String docId,
    required Uint8List bytes,
    String ext = 'jpg',
  }) async {
    final ref = _storage.ref().child('news_images/$docId.$ext');
    final task = await ref.putData(
      bytes,
      SettableMetadata(contentType: 'image/$ext', cacheControl: 'public, max-age=31536000'),
    );
    return await task.ref.getDownloadURL();
  }
}
