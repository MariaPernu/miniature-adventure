// lib/services/ble_heart_rate.dart
import 'dart:async';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:permission_handler/permission_handler.dart';

class BleHeartRate {
  final _ble = FlutterReactiveBle();

  static final Uuid svcHeartRate =
      Uuid.parse("0000180D-0000-1000-8000-00805F9B34FB");
  static final Uuid chrHeartRateMeasurement =
      Uuid.parse("00002A37-0000-1000-8000-00805F9B34FB");

  StreamSubscription<DiscoveredDevice>? _scanSub;
  StreamSubscription<List<int>>? _notifySub;
  StreamSubscription<ConnectionStateUpdate>? _connSub;

  QualifiedCharacteristic? _hrChar;

  Future<void> ensurePermissions() async {
    // Android 12+: bt-scan & bt-connect. Vanhemmilla myös location.
    await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
    ].request();
  }

  Future<void> disconnect() async {
    await _notifySub?.cancel();
    await _scanSub?.cancel();
    await _connSub?.cancel();
    _notifySub = null;
    _scanSub = null;
    _connSub = null;
    _hrChar = null;
  }

  /// Skannaa POLAR-laitteen ja yhdistää (palauttaa deviceId:n tai null).
  Future<String?> scanAndConnect({
    Duration scanTimeout = const Duration(seconds: 15),
    Duration connectTimeout = const Duration(seconds: 15),
  }) async {
    await ensurePermissions();
    await disconnect(); // siivoa varmuudeksi

    final completer = Completer<String?>();

    // Jotkut laitteet eivät mainosta palvelu-UUID:ia → älä rajaa withServices
    _scanSub = _ble
        .scanForDevices(withServices: const [], scanMode: ScanMode.lowLatency)
        .listen((d) async {
      if (!d.name.toUpperCase().contains('POLAR')) return;

      await _scanSub?.cancel();

      _hrChar = QualifiedCharacteristic(
        serviceId: svcHeartRate,
        characteristicId: chrHeartRateMeasurement,
        deviceId: d.id,
      );

      // Yhdistä ja kuuntele tila. Ei firstWhereä → ei “Bad state: No element”.
      _connSub = _ble
          .connectToDevice(
            id: d.id,
            // nopeuttaa/varmistaa palvelujen löydön
            servicesWithCharacteristicsToDiscover: {
              svcHeartRate: [chrHeartRateMeasurement]
            },
            connectionTimeout: connectTimeout,
          )
          .listen((u) {
        if (u.connectionState == DeviceConnectionState.connected &&
            !completer.isCompleted) {
          completer.complete(d.id);
        }
        if (u.connectionState == DeviceConnectionState.disconnected &&
            !completer.isCompleted) {
          // irtosi ennen connected-tilaa
          completer.complete(null);
        }
      }, onError: (e) {
        final msg = e.toString();
        // Jos alusta sanoo "Already connected", jatketaan silti → OK tapaus
        if (msg.contains('Already connected') && !completer.isCompleted) {
          completer.complete(d.id);
        } else if (!completer.isCompleted) {
          completer.completeError(e);
        }
      });
    });

    // skannauksen turvatimeout
    Future.delayed(scanTimeout, () {
      if (!completer.isCompleted) {
        _scanSub?.cancel();
        completer.complete(null);
      }
    });

    return completer.future;
  }

  /// Tilaa sykemittausnotifikaatiot (bpm).
  Stream<int> heartRateStream() {
    final ch = _hrChar;
    if (ch == null) return const Stream.empty();

    return _ble.subscribeToCharacteristic(ch).map((data) {
      if (data.isEmpty) return 0;
      final flags = data[0];
      final is16 = (flags & 0x01) != 0;
      if (is16 && data.length >= 3) return data[1] | (data[2] << 8);
      if (data.length >= 2) return data[1];
      return 0;
    });
  }
}
