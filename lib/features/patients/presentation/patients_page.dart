import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:miniature_adventure/features/patients/presentation/patient_measurements_page.dart';
import '../data/firebase_patient_repository.dart';
import '../domain/patient.dart';

class PatientsPage extends StatefulWidget {
  const PatientsPage({super.key});

  @override
  State<PatientsPage> createState() => _PatientsPageState();
}

class _PatientsPageState extends State<PatientsPage> {
  final repo = FirebasePatientRepository();
  String? uid;

  @override
  void initState() {
    super.initState();
    FirebaseAuth.instance.signInAnonymously().then((c) {
      if (!mounted) return;
      setState(() => uid = c.user!.uid);
    });
  }

  Future<void> _addPatientDialog() async {
    final nameCtrl = TextEditingController();
    final yearCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Lisää testiasiakas'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '⚠️ Tämä on TESTI-asiakas – ',
                style: TextStyle(color: Colors.redAccent, fontSize: 12),
              ),
              TextFormField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Nimi (keksitty)'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Pakollinen' : null,
              ),
              TextFormField(
                controller: yearCtrl,
                decoration:
                    const InputDecoration(labelText: 'Syntymävuosi (valinnainen)'),
                keyboardType: TextInputType.number,
              ),
              TextFormField(
                controller: notesCtrl,
                decoration: const InputDecoration(labelText: 'Muistiinpano'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Peruuta')),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              final p = Patient(
                id: '',
                displayName: nameCtrl.text.trim(),
                birthYear: int.tryParse(yearCtrl.text.trim()),
                isTest: true,
                notes: notesCtrl.text.trim(),
              );
              await repo.add(uid!, p);
              if (!mounted) return;
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Testiasiakas lisätty')),
              );
            },
            child: const Text('Tallenna'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (uid == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Asiakkaat (TESTI)')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addPatientDialog,
        icon: const Icon(Icons.person_add),
        label: const Text('Lisää testiasiakas'),
      ),
      body: StreamBuilder<List<Patient>>(
        stream: repo.streamAll(uid!),
        builder: (ctx, snap) {
          if (snap.hasError) return Center(child: Text('Virhe: ${snap.error}'));
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final patients = snap.data!;
          if (patients.isEmpty) return const Center(child: Text('Ei asiakkaita vielä'));
          return ListView.builder(
            itemCount: patients.length,
            itemBuilder: (_, i) {
              final p = patients[i];
              return ListTile(
                title: Text('${p.displayName} ${p.isTest ? "(TESTI)" : ""}'),
                subtitle: Text(
                  p.birthYear != null ? 's. ${p.birthYear}' : 'Syntymävuosi ei tiedossa',
                ),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => PatientMeasurementsPage(
                        uid: uid!,
                        patientId: p.id,
                        patientName: p.displayName,
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
