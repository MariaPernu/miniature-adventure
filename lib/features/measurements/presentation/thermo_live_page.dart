// lib/features/measurements/presentation/thermo_live_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../measurements/data/firebase_measurement_repository.dart';
import '../../measurements/domain/measurement.dart';
import '../../measurements/domain/enums.dart';

import 'package:virelink/services/withings_oauth.dart' as wo;
import 'package:virelink/services/withings_api.dart' show syncWithingsLatestForPatient;

class ThermoLivePage extends StatefulWidget {
  final String uid;
  final String patientId;
  final String patientName;

  const ThermoLivePage({
    super.key,
    required this.uid,
    required this.patientId,
    required this.patientName,
  });

  @override
  State<ThermoLivePage> createState() => _ThermoLivePageState();
}

class _ThermoLivePageState extends State<ThermoLivePage> {
  bool _busy = false;

  final _repo = FirebaseMeasurementRepository(FirebaseFirestore.instance);

  DocumentReference<Map<String, dynamic>> get _latestDoc => FirebaseFirestore
      .instance
      .collection('patients')
      .doc(widget.patientId)
      .collection('temperatureMeasurements')
      .doc('latest');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Lämpö – ${widget.patientName}')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          _LatestWithingsCard(stream: _latestDoc.snapshots()),
          const SizedBox(height: 12),

          OutlinedButton.icon(
            onPressed: _busy ? null : _linkWithings,
            icon: const Icon(Icons.link),
            label: Text(_busy ? 'Yhdistetään…' : 'Yhdistä Withings-tili'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _busy ? null : _syncLatest,
            icon: const Icon(Icons.sync),
            label: Text(_busy ? 'Haetaan…' : 'Hae uusin mittaus'),
          ),
        ],
      ),
    );
  }

  Future<void> _linkWithings() async {
    setState(() => _busy = true);
    try {
      await wo.linkWithings();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Withings-tili yhdistetty')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Linkitys epäonnistui: $e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _syncLatest() async {
    setState(() => _busy = true);
    try {
      // 1) Hae uusin Withingsiltä -> kirjoittaa temperatureMeasurements/latest
      await syncWithingsLatestForPatient(widget.uid, widget.patientId);

      // 2) Kopioi latest myös measurements-kokoelmaan listaa varten
      await _upsertLatestIntoMeasurements();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Uusin mittaus haettu ja tallennettu listaan')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Synkronointi epäonnistui: $e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Lukee `temperatureMeasurements/latest` ja lisää saman arvon
  /// `patients/{patientId}/measurements`-kokoelmaan VireLink-skeemalla.
  Future<void> _upsertLatestIntoMeasurements() async {
    final snap = await _latestDoc.get();
    final data = snap.data();
    if (data == null) return;

    // Withings latest: odotetut kentät: { timestamp: secondsOrMs, temperature: double }
    final rawTs = (data['timestamp'] as num?)?.toInt();
    final temp = (data['temperature'] as num?)?.toDouble();
    if (rawTs == null || temp == null) return;

    // Sekunnit -> millisekunnit (jos jo ms, jätetään)
    final tsMs = rawTs > 20000000000 /* ~ms threshold */ ? rawTs : rawTs * 1000;
    final dt = DateTime.fromMillisecondsSinceEpoch(tsMs);

    final m = Measurement(
      id: '',
      type: MeasurementType.temperature,
      timestamp: dt,
      utcOffsetMinutes: dt.timeZoneOffset.inMinutes,
      source: SourceType.manual,          // Withings-API: ei BLE. Vaihda tarvittaessa.
      note: null,
      temperatureCelsius: temp,
    );

    await _repo.add(widget.uid, widget.patientId, m);
  }
}

class _LatestWithingsCard extends StatelessWidget {
  final Stream<DocumentSnapshot<Map<String, dynamic>>> stream;
  const _LatestWithingsCard({required this.stream});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: stream,
      builder: (context, snap) {
        String subtitle = 'Ei mittauksia';
        String value = '—';

        if (snap.hasData && snap.data!.data() != null) {
          final m = snap.data!.data()!;
          final ts = m['timestamp'] as int?;
          final temp = (m['temperature'] as num?)?.toDouble();

          if (ts != null) {
            final dt = DateTime.fromMillisecondsSinceEpoch(
              ts > 20000000000 ? ts : ts * 1000,
            ).toLocal();
            final dd = dt.day.toString().padLeft(2, '0');
            final mm = dt.month.toString().padLeft(2, '0');
            final hh = dt.hour.toString().padLeft(2, '0');
            final mi = dt.minute.toString().padLeft(2, '0');
            subtitle = '$dd.$mm.${dt.year} $hh:$mi';
          }
          if (temp != null) value = '${temp.toStringAsFixed(1)} °C';
        }

        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            side: BorderSide(color: Theme.of(context).dividerColor),
            borderRadius: BorderRadius.circular(16),
          ),
          child: ListTile(
            leading: const Icon(Icons.thermostat),
            title: const Text('Viimeisin mittaus (Withings)'),
            subtitle: Text(subtitle),
            trailing: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        );
      },
    );
  }
}
