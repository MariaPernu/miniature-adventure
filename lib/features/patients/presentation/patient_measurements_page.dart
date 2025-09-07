import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../measurements/presentation/heart_rate_live_page.dart';
import '../../measurements/data/firebase_measurement_repository.dart';
import '../../measurements/domain/measurement.dart';
import '../../measurements/domain/enums.dart';
import '../../measurements/presentation/thermo_live_page.dart';

class PatientMeasurementsPage extends StatelessWidget {
  final String uid;         // kirjautuneen käyttäjän uid
  final String patientId;   // patients-kokoelman docId
  final String patientName; // näytetään appbarissa

  PatientMeasurementsPage({
    super.key,
    required this.uid,
    required this.patientId,
    required this.patientName,
  });

  final repo = FirebaseMeasurementRepository(FirebaseFirestore.instance);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Mittaukset – $patientName')),
      body: Column(
        children: [
          // ---------------- PIKANAPIT ----------------
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Verenpaine
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _openAddBpDialog(context),
                    icon: const Icon(Icons.monitor_heart, size: 18),
                    label: const Text('Verenpaine'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // Pulssi (live)
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => HeartRateLivePage(
                          uid: uid,
                          patientId: patientId,
                          patientName: patientName,
                        ),
                      ));
                    },
                    icon: const Icon(Icons.favorite, size: 18),
                    label: const Text('Pulssi'),
                  ),
                ),
                const SizedBox(height: 8),

                // Lämpö (BLE live + Withings-synkka Thermo-sivulla)
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ThermoLivePage(
                            uid: uid,
                            patientId: patientId,
                            patientName: patientName,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.thermostat, size: 18),
                    label: const Text('Lämpö'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // ---------------- LISTA ----------------
          Expanded(
            child: StreamBuilder<List<Measurement>>(
              stream: repo.streamAll(uid, patientId, limit: 200),
              builder: (context, snap) {
                if (snap.hasError) {
                  return Center(child: Text('Virhe: ${snap.error}'));
                }
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final measurements = snap.data!;
                if (measurements.isEmpty) {
                  // Poistettu "Lisää ensimmäinen verenpaine" -painike
                  return const Center(child: Text('Ei mittauksia vielä'));
                }

                return ListView.separated(
                  itemCount: measurements.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final m = measurements[i];

                    // alaotsikko: DD.MM.YYYY HH:MM (+ muistiinpano)
                    final parts = <String>[];
                    final dt = m.timestamp.toLocal();
                    final dateStr =
                        "${_dd(dt)}.${_mm(dt)}.${dt.year} ${_hh(dt)}:${_min(dt)}";
                    parts.add(dateStr);

                    final note = m.note?.trim() ?? '';
                    if (note.isNotEmpty) parts.add(note);

                    final subtitle = parts.join(' • ');

                    return ListTile(
                      dense: true,
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      leading: Icon(_typeIcon(m.type)),
                      title: Text(_typeLabel(m.type)),
                      subtitle: Text(subtitle),
                      trailing: Text(
                        m.displayValue,
                        textAlign: TextAlign.right,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // =================== DIALOGI: lisää verenpaine ===================

  Future<void> _openAddBpDialog(BuildContext context) async {
    final sysCtrl = TextEditingController();
    final diaCtrl = TextEditingController();
    final pulseCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        scrollable: true,
        title: const Text('Lisää verenpaine'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: sysCtrl,
                decoration: const InputDecoration(labelText: 'Systolinen'),
                keyboardType: TextInputType.number,
                validator: (v) {
                  final n = int.tryParse((v ?? '').trim());
                  if (n == null) return 'Anna numero';
                  if (n < 60 || n > 260) return 'Epätodennäköinen arvo';
                  return null;
                },
              ),
              TextFormField(
                controller: diaCtrl,
                decoration: const InputDecoration(labelText: 'Diastolinen'),
                keyboardType: TextInputType.number,
                validator: (v) {
                  final n = int.tryParse((v ?? '').trim());
                  if (n == null) return 'Anna numero';
                  if (n < 30 || n > 180) return 'Epätodennäköinen arvo';
                  return null;
                },
              ),
              TextFormField(
                controller: pulseCtrl,
                decoration: const InputDecoration(labelText: 'Pulssi'),
                keyboardType: TextInputType.number,
                validator: (v) {
                  final t = (v ?? '').trim();
                  if (t.isEmpty) return null;
                  final n = int.tryParse(t);
                  if (n == null) return 'Anna numero';
                  if (n < 30 || n > 220) return 'Epätodennäköinen arvo';
                  return null;
                },
              ),
              TextFormField(
                controller: noteCtrl,
                decoration: const InputDecoration(labelText: 'Muistiinpano'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Peruuta')),
          ElevatedButton(
            onPressed: () {
              if (!formKey.currentState!.validate()) return;
              Navigator.pop(ctx, true);
            },
            child: const Text('Tallenna'),
          ),
        ],
      ),
    );

    if (ok != true) return;

    final now = DateTime.now();
    final m = Measurement(
      id: '',
      type: MeasurementType.bloodPressure,
      timestamp: now,
      utcOffsetMinutes: now.timeZoneOffset.inMinutes,
      source: SourceType.manual,
      note: noteCtrl.text.trim().isEmpty ? null : noteCtrl.text.trim(),
      systolicMmHg: int.parse(sysCtrl.text.trim()),
      diastolicMmHg: int.parse(diaCtrl.text.trim()),
      pulseBpm: (pulseCtrl.text.trim().isEmpty) ? null : int.parse(pulseCtrl.text.trim()),
    );

    await repo.add(uid, patientId, m);

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Verenpaine tallennettu')),
    );
  }

  // =================== APUT ===================

  String _typeLabel(MeasurementType t) {
    switch (t) {
      case MeasurementType.bloodPressure:
        return 'Verenpaine';
      case MeasurementType.heartRate:
        return 'Pulssi';
      case MeasurementType.temperature:
        return 'Lämpö';
    }
  }

  IconData _typeIcon(MeasurementType t) {
    switch (t) {
      case MeasurementType.bloodPressure:
        return Icons.monitor_heart;
      case MeasurementType.heartRate:
        return Icons.favorite_outline;
      case MeasurementType.temperature:
        return Icons.thermostat;
    }
  }

  String _dd(DateTime dt) => dt.day.toString().padLeft(2, '0');
  String _mm(DateTime dt) => dt.month.toString().padLeft(2, '0');
  String _hh(DateTime dt) => dt.hour.toString().padLeft(2, '0');
  String _min(DateTime dt) => dt.minute.toString().padLeft(2, '0');
}
