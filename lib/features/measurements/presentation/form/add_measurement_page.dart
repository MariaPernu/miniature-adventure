import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:miniature_adventure/features/measurements/domain/enums.dart';
import 'package:miniature_adventure/features/measurements/domain/measurement.dart';
import 'package:miniature_adventure/features/patients/data/firebase_patient_repository.dart';
import 'package:miniature_adventure/features/patients/domain/patient.dart';

class AddMeasurementPage extends StatefulWidget {
  const AddMeasurementPage({super.key});

  @override
  State<AddMeasurementPage> createState() => _AddMeasurementPageState();
}

class _AddMeasurementPageState extends State<AddMeasurementPage> {
  final _formKey = GlobalKey<FormState>();
  final _sysCtrl = TextEditingController();
  final _diaCtrl = TextEditingController();
  final _pulseCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();

  final _patientsRepo = FirebasePatientRepository();
  String? _uid;
  String? _selectedPatientId;

  @override
  void initState() {
    super.initState();
    // varmistetaan että on käyttäjä
    final u = FirebaseAuth.instance.currentUser;
    if (u != null) {
      _uid = u.uid;
      setState(() {});
    } else {
      FirebaseAuth.instance.signInAnonymously().then((c) {
        if (!mounted) return;
        _uid = c.user!.uid;
        setState(() {});
      });
    }
  }

  @override
  void dispose() {
    _sysCtrl.dispose();
    _diaCtrl.dispose();
    _pulseCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  String? _reqInt(String? v, {int? min, int? max}) {
    if (v == null || v.trim().isEmpty) return 'Pakollinen';
    final n = int.tryParse(v);
    if (n == null) return 'Vain numeroita';
    if (min != null && n < min) return 'Minimi $min';
    if (max != null && n > max) return 'Maksimi $max';
    return null;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedPatientId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Valitse asiakas')),
      );
      return;
    }
    final sys = int.parse(_sysCtrl.text);
    final dia = int.parse(_diaCtrl.text);
    if (sys < dia) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Systolinen ei voi olla pienempi kuin diastolinen')),
      );
      return;
    }

    final now = DateTime.now();
    final m = Measurement(
      id: '',
      type: MeasurementType.bloodPressure,
      timestamp: now,
      utcOffsetMinutes: now.timeZoneOffset.inMinutes,
      source: SourceType.manual,
      systolicMmHg: sys,
      diastolicMmHg: dia,
      pulseBpm: _pulseCtrl.text.trim().isEmpty ? null : int.parse(_pulseCtrl.text),
      note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
    );

    // Tallennus valitun potilaan alle
    final path = FirebaseFirestore.instance
        .collection('users')
        .doc(_uid)
        .collection('patients')
        .doc(_selectedPatientId)
        .collection('measurements');

    await path.add(m.toMap());

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Mittaus tallennettu')),
    );
    _formKey.currentState!.reset();
    _sysCtrl.clear();
    _diaCtrl.clear();
    _pulseCtrl.clear();
    _noteCtrl.clear();
  }

  @override
  Widget build(BuildContext context) {
    if (_uid == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Lisää mittaus potilaalle')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // POTILASVALINTA
            StreamBuilder<List<Patient>>(
              stream: _patientsRepo.streamAll(_uid!),
              builder: (context, snap) {
                if (snap.hasError) return Text('Virhe: ${snap.error}');
                if (!snap.hasData) return const LinearProgressIndicator();
                final patients = snap.data!;
                if (patients.isEmpty) {
                  return const ListTile(
                    title: Text('Ei potilaita'),
                    subtitle: Text('Lisää ensin testiasiakas Asiakkaat-näkymässä'),
                  );
                }
                return DropdownButtonFormField<String>(
                  value: _selectedPatientId,
                  decoration: const InputDecoration(
                    labelText: 'Valitse asiakas',
                    border: OutlineInputBorder(),
                  ),
                  items: patients
                      .map((p) => DropdownMenuItem(
                            value: p.id,
                            child: Row(
                              children: [
                                Text(p.displayName),
                                const SizedBox(width: 8),
                                if (p.isTest)
                                  const Chip(
                                    label: Text('TESTI'),
                                    visualDensity: VisualDensity.compact,
                                  ),
                              ],
                            ),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedPatientId = v),
                  validator: (v) => v == null ? 'Valitse asiakas' : null,
                );
              },
            ),
            const SizedBox(height: 16),

            // LOMAKE
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    const Text('Verenpaine', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _sysCtrl,
                      decoration: const InputDecoration(labelText: 'Systolinen (mmHg)'),
                      keyboardType: TextInputType.number,
                      validator: (v) => _reqInt(v, min: 60, max: 250),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _diaCtrl,
                      decoration: const InputDecoration(labelText: 'Diastolinen (mmHg)'),
                      keyboardType: TextInputType.number,
                      validator: (v) => _reqInt(v, min: 40, max: 150),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _pulseCtrl,
                      decoration: const InputDecoration(labelText: 'Pulssi (bpm)'),
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return null;
                        return _reqInt(v, min: 30, max: 250);
                      },
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _noteCtrl,
                      decoration: const InputDecoration(labelText: 'Muistiinpano'),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: _save,
                      icon: const Icon(Icons.save),
                      label: const Text('Tallenna'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
