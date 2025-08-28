import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/measurement.dart';
import '../domain/measurement_repository.dart';

class FirebaseMeasurementRepository implements MeasurementRepository {
  final FirebaseFirestore _db;
  FirebaseMeasurementRepository(this._db);

  CollectionReference<Map<String, dynamic>> _col(String uid, String patientId) =>
      _db.collection('users').doc(uid).collection('patients').doc(patientId).collection('measurements');

  @override
  Future<String> add(String uid, String patientId, Measurement m) async {
    final doc = await _col(uid, patientId).add(m.toMap());
    return doc.id;
  }

  @override
  Future<void> update(String uid, String patientId, Measurement m) async {
    await _col(uid, patientId).doc(m.id).update(m.toMap());
  }

  @override
  Future<void> delete(String uid, String patientId, String id) async {
    await _col(uid, patientId).doc(id).delete();
  }

  @override
  Stream<List<Measurement>> streamAll(String uid, String patientId, {int? limit}) {
    Query<Map<String, dynamic>> q =
        _col(uid, patientId).orderBy('timestamp', descending: true);
    if (limit != null) q = q.limit(limit);
    return q.snapshots().map((s) =>
        s.docs.map((d) => Measurement.fromDoc(d.id, d.data())).toList());
  }
}
