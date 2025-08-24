import 'enums.dart';

class Measurement {
  final String id; // Firestore docId
  final MeasurementType type;
  final DateTime timestamp;
  final int utcOffsetMinutes;
  final SourceType source;
  final Posture? posture;
  final String? note;
  final String? deviceMeta;
  final Map<String, dynamic>? raw;

  // subtype fields (nullable)
  final int? systolicMmHg;
  final int? diastolicMmHg;
  final int? pulseBpm;

  final double? temperatureCelsius;
  final TempSite? temperatureSite;

  final int? heartRateBpm;

  // (glukoosi jätetty valinnaiseksi; lisää tarvittaessa)
  final double? glucoseMmolL;
  final GlucoseContext? glucoseContext;

  Measurement({
    required this.id,
    required this.type,
    required this.timestamp,
    required this.utcOffsetMinutes,
    required this.source,
    this.posture,
    this.note,
    this.deviceMeta,
    this.raw,
    this.systolicMmHg,
    this.diastolicMmHg,
    this.pulseBpm,
    this.temperatureCelsius,
    this.temperatureSite,
    this.heartRateBpm,
    this.glucoseMmolL,
    this.glucoseContext,
  });

  Map<String, dynamic> toMap() => {
        'type': type.asKey,
        'timestamp': timestamp.millisecondsSinceEpoch,
        'utcOffsetMinutes': utcOffsetMinutes,
        'source': source.asKey,
        'posture': posture?.asKey,
        'note': note,
        'deviceMeta': deviceMeta,
        'raw': raw,
        'systolicMmHg': systolicMmHg,
        'diastolicMmHg': diastolicMmHg,
        'pulseBpm': pulseBpm,
        'temperatureCelsius': temperatureCelsius,
        'temperatureSite': temperatureSite?.asKey,
        'heartRateBpm': heartRateBpm,
        'glucoseMmolL': glucoseMmolL,
        'glucoseContext': glucoseContext?.asKey,
      };

  factory Measurement.fromDoc(String id, Map<String, dynamic> m) => Measurement(
        id: id,
        type: MeasurementTypeX.fromKey(m['type'] as String),
        timestamp: DateTime.fromMillisecondsSinceEpoch((m['timestamp'] as num).toInt()),
        utcOffsetMinutes: (m['utcOffsetMinutes'] as num).toInt(),
        source: SourceTypeX.fromKey(m['source'] as String?),
        posture: PostureX.fromKey(m['posture'] as String?),
        note: m['note'] as String?,
        deviceMeta: m['deviceMeta'] as String?,
        raw: (m['raw'] as Map?)?.cast<String, dynamic>(),
        systolicMmHg: m['systolicMmHg'] as int?,
        diastolicMmHg: m['diastolicMmHg'] as int?,
        pulseBpm: m['pulseBpm'] as int?,
        temperatureCelsius: (m['temperatureCelsius'] as num?)?.toDouble(),
        temperatureSite: TempSiteX.fromKey(m['temperatureSite'] as String?),
        heartRateBpm: m['heartRateBpm'] as int?,
        glucoseMmolL: (m['glucoseMmolL'] as num?)?.toDouble(),
        glucoseContext: GlucoseContextX.fromKey(m['glucoseContext'] as String?),
      );
}
