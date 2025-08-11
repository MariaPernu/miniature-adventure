// lib/features/measurements/data/app_database.dart
import 'package:drift/drift.dart';
import 'dart:io';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import '../../measurements/domain/enums.dart';

part 'app_database.g.dart';

/// ---------- Enum-konvertterit (talletetaan enumit kantaan tekstinä) ----------
class _EnumConverter<T extends Enum> extends TypeConverter<T, String> {
  final List<T> values;
  final T? orElse;
  const _EnumConverter(this.values, {this.orElse});

  @override
  T? mapToDart(String? fromDb) {
    if (fromDb == null) return null;
    for (final v in values) {
      if (v.name == fromDb) return v;
    }
    return orElse;
  }

  @override
  String? mapToSql(T? value) => value?.name;
}

class MeasurementTypeConverter extends _EnumConverter<MeasurementType> {
  const MeasurementTypeConverter() : super(MeasurementType.values);
}

class SourceConverter extends _EnumConverter<Source> {
  const SourceConverter() : super(Source.values, orElse: Source.manual);
}

class PostureConverter extends _EnumConverter<Posture> {
  const PostureConverter() : super(Posture.values, orElse: Posture.unknown);
}

class TempSiteConverter extends _EnumConverter<TempSite> {
  const TempSiteConverter() : super(TempSite.values, orElse: TempSite.unspecified);
}

class GlucoseContextConverter extends _EnumConverter<GlucoseContext> {
  const GlucoseContextConverter()
      : super(GlucoseContext.values, orElse: GlucoseContext.unspecified);
}

/// ---------- Taulut ----------
class Measurements extends Table {
  TextColumn get id => text()();

  TextColumn get type => text().map(const MeasurementTypeConverter())();

  DateTimeColumn get timestampUtc => dateTime()();

  IntColumn get utcOffsetMinutes => integer()();

  TextColumn get source =>
      text().map(const SourceConverter()).withDefault(const Constant('manual'))();

  TextColumn get posture => text().nullable().map(const PostureConverter())();

  TextColumn get note => text().nullable()();

  TextColumn get deviceMeta => text().nullable()();

  TextColumn get rawPayload => text().nullable()();

  @override
  Set<Column<Object>>? get primaryKey => {id};

  // (Indeksejä ei luoda customConstraintsilla; lisätään myöhemmin migraatiossa jos tarvitaan.)
}

class BpValues extends Table {
  TextColumn get measurementId =>
      text().references(Measurements, #id, onDelete: KeyAction.cascade)();

  IntColumn get systolicMmHg => integer()();

  IntColumn get diastolicMmHg => integer()();

  IntColumn get pulseBpm => integer().nullable()();

  @override
  Set<Column<Object>>? get primaryKey => {measurementId};
}

class PulseValues extends Table {
  TextColumn get measurementId =>
      text().references(Measurements, #id, onDelete: KeyAction.cascade)();

  IntColumn get bpm => integer()();

  @override
  Set<Column<Object>>? get primaryKey => {measurementId};
}

class TemperatureValues extends Table {
  TextColumn get measurementId =>
      text().references(Measurements, #id, onDelete: KeyAction.cascade)();

  RealColumn get celsius => real()();

  TextColumn get site => text().map(const TempSiteConverter())();

  @override
  Set<Column<Object>>? get primaryKey => {measurementId};
}

class GlucoseValues extends Table {
  TextColumn get measurementId =>
      text().references(Measurements, #id, onDelete: KeyAction.cascade)();

  RealColumn get mmolL => real()();

  TextColumn get context => text().map(const GlucoseContextConverter())();

  @override
  Set<Column<Object>>? get primaryKey => {measurementId};
}

/// ---------- SQLite-yhteys (Native) ----------
LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'app.sqlite'));
    return NativeDatabase(file);
  });
}

/// ---------- Tietokanta ----------
@DriftDatabase(
  tables: [Measurements, BpValues, PulseValues, TemperatureValues, GlucoseValues],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  // Perus-CRUD (repository käyttää näitä)
  Future<void> insertMeasurement(MeasurementsCompanion m) =>
      into(measurements).insert(m);

  Future<void> insertBp(BpValuesCompanion v) => into(bpValues).insert(v);
  Future<void> insertPulse(PulseValuesCompanion v) => into(pulseValues).insert(v);
  Future<void> insertTemp(TemperatureValuesCompanion v) =>
      into(temperatureValues).insert(v);
  Future<void> insertGlucose(GlucoseValuesCompanion v) =>
      into(glucoseValues).insert(v);

  Future<int> deleteMeasurementById(String id) =>
      (delete(measurements)..where((t) => t.id.equals(id))).go();

  /// Kaikki mittaukset uusimmasta vanhimpaan
  Stream<List<Measurement>> watchAllMeasurements() =>
      (select(measurements)..orderBy([(t) => OrderingTerm.desc(t.timestampUtc)])).watch();

  // Alatyyppien haut id:llä
  Future<BpValue?> getBp(String id) =>
      (select(bpValues)..where((t) => t.measurementId.equals(id))).getSingleOrNull();

  Future<PulseValue?> getPulse(String id) =>
      (select(pulseValues)..where((t) => t.measurementId.equals(id))).getSingleOrNull();

  Future<TemperatureValue?> getTemp(String id) =>
      (select(temperatureValues)..where((t) => t.measurementId.equals(id))).getSingleOrNull();

  Future<GlucoseValue?> getGlucose(String id) =>
      (select(glucoseValues)..where((t) => t.measurementId.equals(id))).getSingleOrNull();
}
