import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:miniature_adventure/features/measurements/presentation/list/measurements_list_page.dart';
import 'package:miniature_adventure/features/measurements/presentation/form/add_measurement_page.dart';
import 'package:miniature_adventure/features/patients/presentation/patients_page.dart';
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
      theme: ThemeData(useMaterial3: true),
      home: const HomeShell(),
    );
  }
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  final _pages = [
    MeasurementsListPage(), // lista Firestoresta
    AddMeasurementPage(),   // lisää/tallenna
    PatientsPage(),             // Asiakkaat
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.list_alt), label: 'Lista'),
          NavigationDestination(icon: Icon(Icons.add_circle_outline), label: 'Lisää'),
          NavigationDestination(icon: Icon(Icons.group), label: 'Asiakkaat'),
        ],
      ),
    );
  }
}