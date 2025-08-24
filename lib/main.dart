import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:miniature_adventure/features/measurements/presentation/form/add_measurement_page.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'Miniature Adventure',
        home: const AddMeasurementPage(),
    );
  }
}

class TestFirestorePage extends StatelessWidget {
  const TestFirestorePage({super.key});

Future<void> _addTestDoc(BuildContext context) async {
  try {
    await FirebaseFirestore.instance.collection('test').add({
      'hello': 'world',
      'ts': DateTime.now().millisecondsSinceEpoch,
      'device': 'flutter',
    });

    if (!context.mounted) return;            
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Firestoreen lisätty OK')),
    );
  } catch (e) {
    if (!context.mounted) return;            
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Virhe: $e')),
    );
  }
}

  @override
  Widget build(BuildContext context) {
    final q = FirebaseFirestore.instance
        .collection('test')
        .orderBy('ts', descending: true)
        .limit(20);

    return Scaffold(
      appBar: AppBar(title: const Text('Firestore-yhteys')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addTestDoc(context),
        label: const Text('Lisää testidoc'),
        icon: const Icon(Icons.add),
      ),
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
            return const Center(child: Text('Ei dokumentteja. Paina nappia!'));
          }
          return ListView.separated(
            itemCount: docs.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final d = docs[i].data();
              final ts = d['ts'] as int?;
              final dt = ts != null
                  ? DateTime.fromMillisecondsSinceEpoch(ts).toLocal()
                  : null;
              return ListTile(
                title: Text(d['hello']?.toString() ?? '(ei hello-kenttää)'),
                subtitle: Text(dt?.toString() ?? ''),
                trailing: Text(docs[i].id.substring(0, 6)),
              );
            },
          );
        },
      ),
    );
  }
}
