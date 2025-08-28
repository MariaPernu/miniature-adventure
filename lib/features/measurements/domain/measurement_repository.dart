import 'measurement.dart';

abstract class MeasurementRepository {
  Future<String> add(String uid, String patientId, Measurement m);
  Future<void> update(String uid, String patientId, Measurement m);
  Future<void> delete(String uid, String patientId, String id);
  Stream<List<Measurement>> streamAll(String uid, String patientId, {int? limit});
}
