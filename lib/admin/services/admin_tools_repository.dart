import 'package:cloud_firestore/cloud_firestore.dart';
import '../../app/models/tool.dart';

class AdminToolsRepository {
  final _db = FirebaseFirestore.instance;
  static const _collectionPath = 'tools';

  Stream<List<Tool>> watchTools() {
    return _db
        .collection(_collectionPath)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map(
                (doc) => Tool.fromDoc(
                  doc as DocumentSnapshot<Map<String, dynamic>>,
                ),
              )
              .toList(),
        );
  }

  Future<void> upsertTool(Tool tool) async {
    final col = _db.collection(_collectionPath);
    final docRef = tool.id.isEmpty ? col.doc() : col.doc(tool.id);

    await docRef.set(
      tool.copyWith(id: docRef.id).toMap(),
      SetOptions(merge: true),
    );
  }

  Future<void> deleteTool(String id) {
    return _db.collection(_collectionPath).doc(id).delete();
  }
}
