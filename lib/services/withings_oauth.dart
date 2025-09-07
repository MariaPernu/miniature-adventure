// lib/services/withings_oauth.dart
import 'dart:convert';
import 'package:flutter_appauth/flutter_appauth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';

import 'withings_config.dart';

final FlutterAppAuth _appAuth = FlutterAppAuth();
final FlutterSecureStorage _storage = const FlutterSecureStorage();

const _kWithingsUserIdKey = 'withings_userid';

/// 1) authorize (PKCE)
/// 2) vaihda code -> tokens Withingsin requesttoken-WS:llä **using secret**
///    (action=requesttoken, grant_type=authorization_code, client_id, client_secret, code, redirect_uri)
Future<void> linkWithings() async {
  try {
    // 1) Authorize (heitää poikkeuksen jos käyttäjä peruuttaa)
    final auth = await _appAuth.authorize(
      AuthorizationRequest(
        withingsClientId,
        withingsRedirectUri,
        serviceConfiguration: const AuthorizationServiceConfiguration(
          authorizationEndpoint: withingsAuthorizationEndpoint,
          tokenEndpoint: withingsTokenEndpoint,
        ),
        scopes: withingsScopes,
        // additionalParameters: const {'mode': 'demo'}, // halutessasi demo-käyttäjä
      ),
    );

    final code = auth.authorizationCode;
    if (code == null || code.isEmpty) {
      throw Exception('Authorization code puuttuu.');
    }

    // 2) Token-vaihto "using secret" (ei noncea/signaturea)
    final res = await http.post(
      Uri.parse('https://wbsapi.withings.net/v2/oauth2'),
      body: {
        'action': 'requesttoken',
        'grant_type': 'authorization_code',
        'client_id': withingsClientId,
        'client_secret': withingsClientSecret,
        'code': code,
        'redirect_uri': withingsRedirectUri,
      },
    );

    if (res.statusCode != 200) {
      throw Exception('requesttoken HTTP ${res.statusCode}: ${res.body}');
    }

    final json = jsonDecode(res.body) as Map<String, dynamic>;
    if ((json['status'] as num?)?.toInt() != 0) {
      throw Exception('Token error: ${json['status']} ${json['error']}');
    }

    final body = json['body'] as Map<String, dynamic>;
    final accessToken = body['access_token'] as String?;
    final refreshToken = body['refresh_token'] as String?;
    final expiresIn = (body['expires_in'] as num?)?.toInt() ?? 3600;
    final userId = body['userid']; // int tai string

    if (accessToken == null) {
      throw Exception('Token-vaihto epäonnistui: access_token puuttuu.');
    }

    await _storage.write(key: kWithingsAccessKey, value: accessToken);
    if (refreshToken != null) {
      await _storage.write(key: kWithingsRefreshKey, value: refreshToken);
    }
    await _storage.write(
      key: kWithingsAccessExpKey,
      value: DateTime.now().add(Duration(seconds: expiresIn)).toIso8601String(),
    );
    if (userId != null) {
      await _storage.write(key: _kWithingsUserIdKey, value: '$userId');
    }
  } catch (e) {
    // Anna virheen kuplia ylös, jotta UI näyttää siitä ilmoituksen
    rethrow;
  }
}

/// Potilaskohtainen linkitys: kutsuu linkWithings ja kirjaa potilasdokumenttiin
/// merkinnän `patients/{patientId}/integrations/withings`.
Future<void> linkWithingsForPatient(String patientId) async {
  await linkWithings();

  final withingsUserId = await _storage.read(key: _kWithingsUserIdKey);

  final doc = FirebaseFirestore.instance
      .collection('patients')
      .doc(patientId)
      .collection('integrations')
      .doc('withings');

  await doc.set(
    {
      'linkedAt': FieldValue.serverTimestamp(),
      if (withingsUserId != null) 'withingsUserId': withingsUserId,
    },
    SetOptions(merge: true),
  );
}

/// Palauttaa voimassa olevan access tokenin tai päivittää sen refresh-tokenilla
/// (myös refresh tehdään "using secret" -tavalla).
Future<String?> getValidAccessToken() async {
  final access = await _storage.read(key: kWithingsAccessKey);
  final expIso = await _storage.read(key: kWithingsAccessExpKey);
  final refresh = await _storage.read(key: kWithingsRefreshKey);

  if (access == null || expIso == null) return null;

  final exp = DateTime.tryParse(expIso);
  if (exp != null && DateTime.now().isBefore(exp.subtract(const Duration(seconds: 30)))) {
    return access;
  }
  if (refresh == null) return null;

  try {
    final res = await http.post(
      Uri.parse('https://wbsapi.withings.net/v2/oauth2'),
      body: {
        'action': 'requesttoken',
        'grant_type': 'refresh_token',
        'client_id': withingsClientId,
        'client_secret': withingsClientSecret,
        'refresh_token': refresh,
      },
    );

    if (res.statusCode != 200) {
      throw Exception('refresh HTTP ${res.statusCode}: ${res.body}');
    }

    final json = jsonDecode(res.body) as Map<String, dynamic>;
    if ((json['status'] as num?)?.toInt() != 0) {
      throw Exception('Refresh error: ${json['status']} ${json['error']}');
    }

    final body = json['body'] as Map<String, dynamic>;
    final newAccess = body['access_token'] as String?;
    final newRefresh = body['refresh_token'] as String?;
    final expiresIn = (body['expires_in'] as num?)?.toInt() ?? 3600;

    if (newAccess == null) return null;

    await _storage.write(key: kWithingsAccessKey, value: newAccess);
    if (newRefresh != null) {
      await _storage.write(key: kWithingsRefreshKey, value: newRefresh);
    }
    await _storage.write(
      key: kWithingsAccessExpKey,
      value: DateTime.now().add(Duration(seconds: expiresIn)).toIso8601String(),
    );

    return newAccess;
  } catch (_) {
    return null;
  }
}
