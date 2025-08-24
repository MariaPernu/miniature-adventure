import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/patient.dart';

class FirebasePatientRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _col(String uid) =>
      _db.collection('users').doc(uid).collection('patients');

  Future<String> add(String uid, Patient p) async {
    final doc = await _col(uid).add(p.toMap());
    return doc.id;
  }

  Future<void> delete(String uid, String id) => _col(uid).doc(id).delete();

  Stream<List<Patient>> streamAll(String uid) =>
      _col(uid).orderBy('displayName').snapshots().map(
            (s) => s.docs
                .map((d) => Patient.fromDoc(d.id, d.data()))
                .toList(),
          );
}
