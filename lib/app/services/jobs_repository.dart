import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/job.dart';

class JobsRepository {
  JobsRepository._();
  static final JobsRepository instance = JobsRepository._();

  final _db = FirebaseFirestore.instance;
  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('jobs');

  Stream<List<Job>> watchJobs() {
    return _col
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(Job.fromDoc).toList());
  }

  Future<void> upsertJob(Job job) async {
    final data = job.toMap();
    if (job.id.isEmpty) {
      // new
      await _col.add(data);
    } else {
      await _col.doc(job.id).set(data, SetOptions(merge: true));
    }
  }

  Future<void> deleteJob(String id) async {
    await _col.doc(id).delete();
  }
}
