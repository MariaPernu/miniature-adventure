import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../measurements/domain/measurement.dart';
import 'firebase_measurement_repository.dart';

class Repo {
  Repo._();
  static final instance =
      FirebaseMeasurementRepository(FirebaseFirestore.instance);

  static Future<String> ensureUser() async {
    final auth = FirebaseAuth.instance;
    if (auth.currentUser != null) return auth.currentUser!.uid;
    final cred = await auth.signInAnonymously();
    return cred.user!.uid;
  }

  static Future<String> addMeasurement(Measurement m) async {
    final uid = await ensureUser();
    return instance.add(uid, m);
  }
}
