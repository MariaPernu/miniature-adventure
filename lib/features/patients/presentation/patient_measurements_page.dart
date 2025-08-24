import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PatientMeasurementsPage extends StatelessWidget {
  final String uid;         // kirjautuneen käyttäjän uid
  final String patientId;   // patients-kokoelman docId
  final String patientName; // näytetään appbarissa

  const PatientMeasurementsPage({
    super.key,
    required this.uid,
    required this.patientId,
    required this.patientName,
  });

  @override
  Widget build(BuildContext context) {
    final q = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('patients')
        .doc(patientId)
        .collection('measurements')
        .orderBy('timestamp', descending: true)
        .limit(200);

    return Scaffold(
      appBar: AppBar(title: Text('Mittaukset – $patientName')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: q.snapshots(),
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(child: Text('Virhe: ${snap.error}'));
          }
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snap.data!.docs;
          if (docs.isEmpty) {
            return const Center(child: Text('Ei mittauksia tälle asiakkaalle'));
          }

          return ListView.separated(
            itemCount: docs.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) {
              final m = docs[i].data();

              // timestamp voi olla ms (int) tai Firestore Timestamp
              DateTime? dt;
              final ts = m['timestamp'];
              if (ts is Timestamp) {
                dt = ts.toDate();
              } else if (ts is num) {
                dt = DateTime.fromMillisecondsSinceEpoch(ts.toInt());
              }

              // Näytettävä arvo
              String mainValue = '';
              if (m['systolicMmHg'] != null && m['diastolicMmHg'] != null) {
                mainValue =
                    '${m['systolicMmHg']}/${m['diastolicMmHg']} mmHg'
                    '${m['pulseBpm'] != null ? ' • ${m['pulseBpm']} bpm' : ''}';
              } else if (m['heartRateBpm'] != null) {
                mainValue = '${m['heartRateBpm']} bpm';
              } else if (m['temperatureCelsius'] != null) {
                final v = (m['temperatureCelsius'] as num).toStringAsFixed(1);
                mainValue = '$v °C';
              }

              final type = (m['type'] as String?) ?? 'mittaus';
              final subtitle = [
                if (dt != null) dt.toLocal().toString(),
                if ((m['note'] as String?)?.isNotEmpty == true) m['note'] as String,
              ].join(' • ');

              return ListTile(
                leading: const Icon(Icons.monitor_heart),
                title: Text(type),
                subtitle: Text(subtitle),
                trailing: Text(mainValue, textAlign: TextAlign.right),
              );
            },
          );
        },
      ),
    );
  }
}
