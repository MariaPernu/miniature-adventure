import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../data/firebase_measurement_repository.dart';
import '../domain/measurement.dart';
import '../domain/enums.dart';
import '../../../services/ble_heart_rate.dart';

class HeartRateLivePage extends StatefulWidget {
  final String uid;
  final String patientId;
  final String patientName;

  const HeartRateLivePage({
    super.key,
    required this.uid,
    required this.patientId,
    required this.patientName,
  });

  @override
  State<HeartRateLivePage> createState() => _HeartRateLivePageState();
}

class _HeartRateLivePageState extends State<HeartRateLivePage> {
  final _ble = BleHeartRate();
  final _repo = FirebaseMeasurementRepository(FirebaseFirestore.instance);

  StreamSubscription<int>? _hrSub;
  int? _currentBpm;
  String _status = 'Ei yhteyttä';
  bool _isConnecting = false;
  bool _isSaving = false;

  @override
  void dispose() {
    _hrSub?.cancel();
    _ble.disconnect();
    super.dispose();
  }

  Future<void> _connect() async {
    if (_isConnecting) return;
    setState(() {
      _isConnecting = true;
      _status = 'Yhdistetään…';
      _currentBpm = null;
    });

    try {
      await _ble.disconnect();
      final id = await _ble.scanAndConnect(
        scanTimeout: const Duration(seconds: 15),
        connectTimeout: const Duration(seconds: 15),
      );
      if (!mounted) return;

      if (id == null) {
        setState(() => _status = 'Laitetta ei löytynyt');
        return;
      }

      setState(() => _status = 'Yhdistetty');

      await _hrSub?.cancel();
      _hrSub = _ble.heartRateStream().listen((bpm) {
        if (!mounted) return;
        setState(() => _currentBpm = bpm);
      }, onError: (e) {
        if (!mounted) return;
        setState(() => _status = 'Virhe: ${e.toString().split('\n').first}');
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _status = 'Virhe: ${e.toString().split('\n').first}');
    } finally {
      if (mounted) setState(() => _isConnecting = false);
    }
  }

  Future<void> _disconnect() async {
    await _hrSub?.cancel();
    await _ble.disconnect();
    if (!mounted) return;
    setState(() {
      _status = 'Ei yhteyttä';
      _currentBpm = null;
    });
  }

  Future<void> _saveLatest() async {
    if (_isSaving) return;
    final latest = _currentBpm;

    if (latest == null || latest <= 0) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ei voimassaolevaa arvoa')),
      );
      return;
    }

    if (latest < 30 || latest > 240) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Epätodennäköinen arvo ($latest bpm)')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final now = DateTime.now();
      final m = Measurement(
        id: '',
        type: MeasurementType.heartRate,
        timestamp: now,
        utcOffsetMinutes: now.timeZoneOffset.inMinutes,
        source: SourceType.bluetooth,
        note: null,
        heartRateBpm: latest,
      );

      await _repo.add(widget.uid, widget.patientId, m);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Tallennettu: $latest bpm')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Tallennus epäonnistui: ${e.toString().split('\n').first}')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Pulssi – ${widget.patientName}')),
      body: SafeArea(
        bottom: true,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(
                    _status == 'Yhdistetty'
                        ? Icons.bluetooth_connected
                        : Icons.bluetooth_disabled,
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: Text(_status, style: const TextStyle(fontSize: 14))),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Center(
                  child: Text(
                    _currentBpm != null && _currentBpm! > 0 ? '${_currentBpm!}' : '--',
                    style: const TextStyle(fontSize: 72, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isConnecting ? null : _connect,
                      icon: const Icon(Icons.bluetooth_searching),
                      label: Text(_isConnecting ? 'Yhdistetään…' : 'Yhdistä HR-laite'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _disconnect,
                      icon: const Icon(Icons.link_off),
                      label: const Text('Katkaise'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: (_currentBpm == null || _currentBpm! <= 0 || _isSaving)
                      ? null
                      : _saveLatest,
                  icon: const Icon(Icons.save),
                  label: Text(_isSaving ? 'Tallennetaan…' : 'Tallenna'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
