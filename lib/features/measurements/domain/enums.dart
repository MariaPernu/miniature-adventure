/// Sovelluksen mittaustyypit
enum MeasurementType { bloodPressure, pulse, temperature, glucose }

/// Datan lähde – nyt aina [Source.manual], myöhemmin myös BLE jne.
enum Source { manual, ble, file, healthService }

/// Verenpaineen mittausasento
enum Posture { supine, sitting, standing, standing3min, unknown }

/// Lämpötilan mittauspaikka
enum TempSite { axillary, oral, tympanic, temporal, unspecified }

/// Verensokerin konteksti
enum GlucoseContext { fasting, preprandial, postprandial2h, unspecified }

/// ————— Apufunktiot UI:ta ja tallennusta varten —————

extension MeasurementTypeX on MeasurementType {
  String get key => name; // tallennetaan kantaan nimenä
  String get label => switch (this) {
        MeasurementType.bloodPressure => 'Verenpaine',
        MeasurementType.pulse => 'Pulssi',
        MeasurementType.temperature => 'Lämpötila',
        MeasurementType.glucose => 'Verensokeri',
      };
}

extension SourceX on Source {
  String get key => name;
  String get label => switch (this) {
        Source.manual => 'Manuaalinen',
        Source.ble => 'Bluetooth',
        Source.file => 'Tiedosto',
        Source.healthService => 'Terveysalusta',
      };
}

extension PostureX on Posture {
  String get key => name;
  String get label => switch (this) {
        Posture.supine => 'Maaten',
        Posture.sitting => 'Istu­en',
        Posture.standing => 'Seisten',
        Posture.standing3min => 'Seisten 3 min',
        Posture.unknown => 'Tuntematon',
      };
}

extension TempSiteX on TempSite {
  String get key => name;
  String get label => switch (this) {
        TempSite.axillary => 'Kainalo',
        TempSite.oral => 'Suu',
        TempSite.tympanic => 'Korva',
        TempSite.temporal => 'Otsa',
        TempSite.unspecified => 'Muu/ei määritelty',
      };
}

extension GlucoseContextX on GlucoseContext {
  String get key => name;
  String get label => switch (this) {
        GlucoseContext.fasting => 'Paasto',
        GlucoseContext.preprandial => 'Ennen ateriaa',
        GlucoseContext.postprandial2h => '2 h aterian jälkeen',
        GlucoseContext.unspecified => '—',
      };
}

/// Palauttaa enum-arvon sen [name]-avainarvosta (turvallinen DB:stä lukemiseen).
T enumFromKey<T extends Enum>(List<T> values, String key, {T? orElse}) {
  for (final v in values) {
    if (v.name == key) return v;
  }
  if (orElse != null) return orElse;
  throw ArgumentError('Unknown enum key "$key" for $T');
}
