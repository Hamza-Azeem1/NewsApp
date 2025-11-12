import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/ebook.dart';

class EbooksRepository {
  final _col = FirebaseFirestore.instance.collection('ebooks');
  Stream<List<Ebook>> watchAll() {
    return _col.snapshots().map((s) => s.docs.map((d) => Ebook.fromMap(d.id, d.data())).toList());
  }
}
