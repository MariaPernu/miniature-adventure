enum MeasurementType { bloodPressure, temperature, heartRate }
enum SourceType { bluetooth, manual }
enum Posture { sitting, standing, lying, unknown }
enum TempSite { ear, oral, axillary, forehead, unspecified }
enum GlucoseContext { fasting, beforeMeal, afterMeal, bedtime, unspecified }

extension MeasurementTypeX on MeasurementType {
  String get asKey {
    switch (this) {
      case MeasurementType.bloodPressure: return 'bloodPressure';
      case MeasurementType.temperature:   return 'temperature';
      case MeasurementType.heartRate:     return 'heartRate';
    }
  }
  static MeasurementType fromKey(String v) {
    switch (v) {
      case 'bloodPressure': return MeasurementType.bloodPressure;
      case 'temperature':   return MeasurementType.temperature;
      case 'heartRate':     return MeasurementType.heartRate;
      default: throw ArgumentError('Unknown MeasurementType: $v');
    }
  }
}

extension SourceTypeX on SourceType {
  String get asKey => this == SourceType.bluetooth ? 'bluetooth' : 'manual';
  static SourceType fromKey(String? v) =>
      v == 'bluetooth' ? SourceType.bluetooth : SourceType.manual;
}

extension PostureX on Posture {
  String get asKey => name;
  static Posture fromKey(String? v) =>
      Posture.values.firstWhere((e) => e.name == v, orElse: () => Posture.unknown);
}

extension TempSiteX on TempSite {
  String get asKey => name;
  static TempSite fromKey(String? v) =>
      TempSite.values.firstWhere((e) => e.name == v, orElse: () => TempSite.unspecified);
}

extension GlucoseContextX on GlucoseContext {
  String get asKey => name;
  static GlucoseContext fromKey(String? v) => GlucoseContext.values
      .firstWhere((e) => e.name == v, orElse: () => GlucoseContext.unspecified);
}
