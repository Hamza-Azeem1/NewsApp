import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/tool.dart';

class ToolsRepository {
  ToolsRepository._();
  static final instance = ToolsRepository._();

  final _db = FirebaseFirestore.instance;
  static const _collectionPath = 'tools';

  /// Live stream of tools (sorted by newest first)
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

  /// One-time fetch, if you ever need it
  Future<List<Tool>> fetchOnce() async {
    final snap = await _db
        .collection(_collectionPath)
        .orderBy('createdAt', descending: true)
        .get();

    return snap.docs
        .map(
          (doc) => Tool.fromDoc(
            doc as DocumentSnapshot<Map<String, dynamic>>,
          ),
        )
        .toList();
  }

  /// Create or update a tool
  Future<void> setTool(Tool tool) async {
    final col = _db.collection(_collectionPath);
    final docRef = tool.id.isEmpty ? col.doc() : col.doc(tool.id);

    await docRef.set(
      tool.copyWith(id: docRef.id).toMap(),
      SetOptions(merge: true),
    );
  }

  /// Delete tool
  Future<void> deleteTool(String id) {
    return _db.collection(_collectionPath).doc(id).delete();
  }
}
