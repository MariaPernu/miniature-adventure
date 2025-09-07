import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/measurement.dart';
import '../domain/measurement_repository.dart';

class FirebaseMeasurementRepository implements MeasurementRepository {
  final FirebaseFirestore _db;
  FirebaseMeasurementRepository(this._db);

  // YHTENÄINEN POLKU: sama kuin Withingsillä
  CollectionReference<Map<String, dynamic>> _col(String patientId) =>
      _db.collection('patients').doc(patientId).collection('measurements');

  @override
  Future<String> add(String uid, String patientId, Measurement m) async {
    // uid ei ole tarpeen tässä polussa – pidetään signatuuri yhteensopivuuden vuoksi
    final doc = await _col(patientId).add(m.toMap());
    return doc.id;
  }

  @override
  Future<void> update(String uid, String patientId, Measurement m) async {
    await _col(patientId).doc(m.id).update(m.toMap());
  }

  @override
  Future<void> delete(String uid, String patientId, String id) async {
    await _col(patientId).doc(id).delete();
  }

  @override
  Stream<List<Measurement>> streamAll(String uid, String patientId, {int? limit}) {
    Query<Map<String, dynamic>> q =
        _col(patientId).orderBy('timestamp', descending: true);
    if (limit != null) q = q.limit(limit);
    return q.snapshots().map(
      (s) => s.docs.map((d) => Measurement.fromDoc(d.id, d.data())).toList(),
    );
  }
}
