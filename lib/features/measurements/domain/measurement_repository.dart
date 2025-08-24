import 'measurement.dart';

abstract class MeasurementRepository {
  Future<String> add(String uid, Measurement m);
  Future<void> update(String uid, Measurement m);
  Future<void> delete(String uid, String id);
  Stream<List<Measurement>> streamAll(String uid, {int? limit});
}
