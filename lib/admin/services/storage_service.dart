import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  final _storage = FirebaseStorage.instance;

  // --- Your existing method (kept as-is) ---
  Future<String> uploadNewsImage({
    required String docId,
    required Uint8List bytes,
    String ext = 'jpg',
  }) async {
    final ref = _storage.ref().child('news_images/$docId.$ext');
    final task = await ref.putData(
      bytes,
      SettableMetadata(
        contentType: 'image/$ext',
        cacheControl: 'public, max-age=31536000',
      ),
    );
    return await task.ref.getDownloadURL();
  }

  // --- NEW: used by TeacherForm ---
  /// Lets admin pick an image file and uploads to `uploads/teachers/`.
  /// Returns the download URL or null if the user cancels.
  static Future<String?> pickAndUploadTeacherImage() async {
    // pick image (works on web & mobile)
    final res = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      type: FileType.image,
      withData: true, // important for web
    );
    if (res == null || res.files.isEmpty) return null;

    final file = res.files.first;
    final bytes = file.bytes; // on mobile/web with withData:true
    if (bytes == null) return null;

    final ext = (file.extension?.toLowerCase() ?? 'jpg');
    final fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.name}';
    final ref = FirebaseStorage.instance.ref('uploads/teachers/$fileName');

    await ref.putData(
      bytes,
      SettableMetadata(
        contentType: 'image/$ext',
        cacheControl: 'public, max-age=31536000',
      ),
    );

    return ref.getDownloadURL();
  }
}
