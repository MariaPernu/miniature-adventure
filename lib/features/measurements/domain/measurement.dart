import 'enums.dart';

class Measurement {
  final String id; // Firestore docId
  final MeasurementType type;
  final DateTime timestamp;
  final int utcOffsetMinutes;
  final SourceType source;
  final String? note;

  // Alatyypit (nullable)
  final int? systolicMmHg;
  final int? diastolicMmHg;
  final int? pulseBpm;
  final double? temperatureCelsius;
  final int? heartRateBpm;

  Measurement({
    required this.id,
    required this.type,
    required this.timestamp,
    required this.utcOffsetMinutes,
    required this.source,
    this.note,
    this.systolicMmHg,
    this.diastolicMmHg,
    this.pulseBpm,
    this.temperatureCelsius,
    this.heartRateBpm,
  });

  /// Näytettävä arvo listaan (RR+P / HR / lämpö)
  String get displayValue {
    if (systolicMmHg != null && diastolicMmHg != null) {
      final bp = '$systolicMmHg/$diastolicMmHg mmHg';
      return pulseBpm != null ? '$bp • $pulseBpm bpm' : bp;
    }
    if (heartRateBpm != null) return '$heartRateBpm bpm';
    if (temperatureCelsius != null) {
      return '${temperatureCelsius!.toStringAsFixed(1)} °C';
    }
    return '';
  }

  /// Aikaleima HH:MM (paikallisaika)
  String get formattedTime {
    final local = timestamp.toLocal();
    final hh = local.hour.toString().padLeft(2, '0');
    final mm = local.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  /// ========== Firebase map ==========
  /// Poistaa null-kentät -> ei kaadu sääntöihin.
  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'type': type.asKey,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'utcOffsetMinutes': utcOffsetMinutes,
      'source': source.asKey,
    };
    if (note != null && note!.trim().isNotEmpty) {
      map['note'] = note!.trim();
    }
    if (systolicMmHg != null) map['systolicMmHg'] = systolicMmHg;
    if (diastolicMmHg != null) map['diastolicMmHg'] = diastolicMmHg;
    if (pulseBpm != null) map['pulseBpm'] = pulseBpm;
    if (temperatureCelsius != null) map['temperatureCelsius'] = temperatureCelsius;
    if (heartRateBpm != null) map['heartRateBpm'] = heartRateBpm;
    return map;
  }

  /// ========== Factory-nimellinen konstruktori ==========
  factory Measurement.fromDoc(String id, Map<String, dynamic> m) {
    final typeStr = m['type'] as String?;
    final sourceStr = m['source'] as String?;
    final tsMs = (m['timestamp'] as num?)?.toInt()
        ?? DateTime.now().millisecondsSinceEpoch;
    final utcOff = (m['utcOffsetMinutes'] as num?)?.toInt() ?? 0;

    return Measurement(
      id: id,
      type: MeasurementTypeX.fromKey(
        typeStr ?? MeasurementType.temperature.asKey,
      ),
      timestamp: DateTime.fromMillisecondsSinceEpoch(tsMs),
      utcOffsetMinutes: utcOff,
      source: SourceTypeX.fromKey(
        sourceStr ?? SourceType.manual.asKey,
      ),
      note: (m['note'] as String?)?.trim(),
      systolicMmHg: (m['systolicMmHg'] as num?)?.toInt(),
      diastolicMmHg: (m['diastolicMmHg'] as num?)?.toInt(),
      pulseBpm: (m['pulseBpm'] as num?)?.toInt(),
      temperatureCelsius: (m['temperatureCelsius'] as num?)?.toDouble(),
      heartRateBpm: (m['heartRateBpm'] as num?)?.toInt(),
    );
  }
}
