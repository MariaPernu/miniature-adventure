import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../data/repository_singleton.dart';
import '../../domain/measurement.dart';
import '../../domain/enums.dart';

class MeasurementsListPage extends StatefulWidget {
  const MeasurementsListPage({super.key});
  @override
  State<MeasurementsListPage> createState() => _MeasurementsListPageState();
}

class _MeasurementsListPageState extends State<MeasurementsListPage> {
  String? uid;

  @override
  void initState() {
    super.initState();
    // anonyymi kirjautuminen testiin
    FirebaseAuth.instance.signInAnonymously().then((c) {
      setState(() => uid = c.user!.uid);
    });
  }

  Future<void> _saveExampleBp() async {
    final now = DateTime.now();
    final m = Measurement(
      id: '',
      type: MeasurementType.bloodPressure,
      timestamp: now,
      utcOffsetMinutes: now.timeZoneOffset.inMinutes,
      source: SourceType.manual,
      systolicMmHg: 124,
      diastolicMmHg: 82,
      pulseBpm: 70,
      note: 'testitallennus ${now.toLocal()}',
    );
    await Repo.addMeasurement(m);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Testimittaus tallennettu')),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (uid == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final q = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('measurements')
        .orderBy('timestamp', descending: true)
        .limit(100);

    return Scaffold(
      appBar: AppBar(title: const Text('Mittaukset (Firestore)')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _saveExampleBp, icon: const Icon(Icons.add),
        label: const Text('Lisää testi-BP'),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: q.snapshots(),
        builder: (context, snap) {
          if (snap.hasError) return Center(child: Text('Virhe: ${snap.error}'));
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snap.data!.docs;
          if (docs.isEmpty) return const Center(child: Text('Ei mittauksia vielä'));
          return ListView.separated(
            itemCount: docs.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) {
              final d = docs[i].data();
              final type = (d['type'] as String?) ?? '';
              final ts = DateTime.fromMillisecondsSinceEpoch(
                  (d['timestamp'] as num).toInt()).toLocal();
              // näytä arvo tiiviisti
              String value = '';
              if (d['systolicMmHg'] != null && d['diastolicMmHg'] != null) {
                value = '${d['systolicMmHg']}/${d['diastolicMmHg']} mmHg';
              } else if (d['heartRateBpm'] != null) {
                value = '${d['heartRateBpm']} bpm';
              } else if (d['temperatureCelsius'] != null) {
                value = '${(d['temperatureCelsius'] as num).toStringAsFixed(1)} °C';
              }
              return ListTile(
                title: Text(type),
                subtitle: Text(ts.toString()),
                trailing: Text(value),
              );
            },
          );
        },
      ),
    );
  }
}
