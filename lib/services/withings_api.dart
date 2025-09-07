// lib/services/withings_api.dart
import 'dart:convert';
import 'dart:math' as math;
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';

import 'withings_oauth.dart';   // getValidAccessToken()
import 'withings_config.dart';  // withingsClientId, withingsClientSecret

/// --- Signature v2 apurit (nonce + HMAC) ---

String _generateSignature(Map<String, String> params, String clientSecret) {
  final keys = params.keys.toList()..sort();
  final joinedValues = keys.map((k) => params[k]!).join(',');
  final h = Hmac(sha256, utf8.encode(clientSecret));
  return h.convert(utf8.encode(joinedValues)).toString();
}

Future<String> _getNonce() async {
  final ts = (DateTime.now().millisecondsSinceEpoch ~/ 1000).toString();
  final params = {
    'action': 'getnonce',
    'client_id': withingsClientId,
    'timestamp': ts,
  };
  final signature = _generateSignature(params, withingsClientSecret);

  final res = await http.post(
    Uri.parse('https://wbsapi.withings.net/v2/signature'),
    body: {...params, 'signature': signature},
  );

  if (res.statusCode != 200) {
    throw Exception('Nonce request failed: ${res.statusCode} ${res.body}');
  }
  final json = jsonDecode(res.body) as Map<String, dynamic>;
  if (json['status'] != 0) {
    throw Exception('Nonce request error: ${json['status']} ${json['error']}');
  }
  return (json['body'] as Map<String, dynamic>)['nonce'] as String;
}

/// --- Withings: hae viimeisiä measuregrps-ryhmiä (vain lämpötila) ---

Future<List<Map<String, dynamic>>> _fetchLatestMeasureGroups(
  String accessToken, {
  int limit = 10,
  int? startDateEpochSec,
}) async {
  final nonce = await _getNonce();

  final params = {
    'action': 'getmeas',
    'client_id': withingsClientId,
    'nonce': nonce,
  };
  final signature = _generateSignature(params, withingsClientSecret);

  final body = <String, String>{
    ...params,
    'signature': signature,
    'category': '1',
    'offset': '0',
    'limit': '$limit',
    'meastype': '71', // vain lämpötila
    'access_token': accessToken,
    if (startDateEpochSec != null) 'startdate': '$startDateEpochSec',
  };

  final res = await http.post(
    Uri.parse('https://wbsapi.withings.net/measure'),
    body: body,
  );

  if (res.statusCode != 200) {
    throw Exception('Withings API error ${res.statusCode}: ${res.body}');
  }

  final json = jsonDecode(res.body) as Map<String, dynamic>;
  if (json['status'] != 0) {
    throw Exception('Withings API logical error: ${json['status']} - ${json['error'] ?? 'unknown'}');
  }

  final bodyJson = json['body'] as Map<String, dynamic>? ?? {};
  final groups = (bodyJson['measuregrps'] as List<dynamic>? ?? [])
      .whereType<Map<String, dynamic>>()
      .toList();

  return groups;
}

/// --- Poimi ryhmistä vain tuorein lämpötilamittaus ---

Map<String, dynamic>? _pickLatestTemperature(List<Map<String, dynamic>> groups) {
  Map<String, dynamic>? latest;
  int latestTs = -1;

  for (final g in groups) {
    final ts = g['date'] as int?;
    if (ts == null) continue;

    final measures = (g['measures'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>();

    // Poimi vain kehon lämpö (type = 71). Älä käytä type 12.
    final bodyTemp = measures.firstWhere(
      (m) => m['type'] == 71,
      orElse: () => {},
    );

    if (bodyTemp.isNotEmpty) {
      final value = (bodyTemp['value'] as num?) ?? 0;
      final unit  = (bodyTemp['unit']  as num?) ?? 0;
      final actual = (value * math.pow(10, unit)).toDouble(); // esim. 375 * 10^-1 = 37.5

      if (ts > latestTs) {
        latestTs = ts;
        latest = {'timestamp': ts, 'temperature': actual};
      }
    }
  }

  return latest;
}

Future<void> syncWithingsLatestForPatient(String uid, String patientId) async {
  // 1) access token
  final accessToken = await getValidAccessToken();
  if (accessToken == null) {
    throw Exception('No Withings access token');
  }

  // 2) mihin kirjoitetaan – SAMA polku kuin ThermoLivePage kuuntelee
  final latestDoc = FirebaseFirestore.instance
      .collection('patients')
      .doc(patientId)
      .collection('temperatureMeasurements')
      .doc('latest');

  // 3) hae nykyinen ts -> käytä startdate-suodatusta
  final snap = await latestDoc.get();
  final currentTs = snap.data()?['timestamp'] as int?;
  final startDate = (currentTs != null) ? currentTs + 1 : null;

  // 4) hae pieni määrä ryhmiä ja poimi uusin lämpö
  final groups = await _fetchLatestMeasureGroups(
    accessToken,
    limit: 5,
    startDateEpochSec: startDate,
  );
  if (groups.isEmpty) return;

  final latest = _pickLatestTemperature(groups);
  if (latest == null) return;

  final ts = latest['timestamp'] as int;                 // epoch seconds
  final temp = (latest['temperature'] as num).toDouble();

  // 5) kirjoita “latest” yhteen dokumenttiin
  await latestDoc.set({
    'timestamp': ts,                  // sekunteina (UI tekee *1000)
    'temperature': temp,              // UI odottaa kenttää "temperature"
    'source': 'Withings',
    'updatedAt': FieldValue.serverTimestamp(),
  }, SetOptions(merge: true));
}
