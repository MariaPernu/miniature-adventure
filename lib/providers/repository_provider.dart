import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/measurements/data/firebase_measurement_repository.dart';
import '../features/measurements/domain/measurement_repository.dart';

final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

final measurementRepositoryProvider = Provider<MeasurementRepository>((ref) {
  final db = ref.watch(firestoreProvider);
  return FirebaseMeasurementRepository(db);
});
