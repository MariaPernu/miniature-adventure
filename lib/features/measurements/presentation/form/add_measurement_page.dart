import 'package:flutter/material.dart';
import 'package:miniature_adventure/features/measurements/domain/measurement.dart';
import 'package:miniature_adventure/features/measurements/domain/enums.dart';
import 'package:miniature_adventure/features/measurements/data/repository_singleton.dart';

class AddMeasurementPage extends StatelessWidget {
  const AddMeasurementPage({super.key});

  Future<void> _saveExampleBp(BuildContext context) async {
    final now = DateTime.now();
    final m = Measurement(
      id: '',
      type: MeasurementType.bloodPressure,
      timestamp: now,
      utcOffsetMinutes: now.timeZoneOffset.inMinutes,
      source: SourceType.manual,
      // jos mallissasi EI ole deviceId-kenttää, jätä tämä pois:
      // deviceId: 'manual',
      systolicMmHg: 124,
      diastolicMmHg: 82,
      pulseBpm: 70,
      note: 'testitallennus ${now.toLocal()}',
    );
    await Repo.addMeasurement(m);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Tallennus OK')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lisää mittaus (testi)')),
      body: Center(
        child: ElevatedButton(
          onPressed: () => _saveExampleBp(context),
          child: const Text('Tallenna testimittaus'),
        ),
      ),
    );
  }
}
