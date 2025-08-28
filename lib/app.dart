import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'services/auth_service.dart';
import 'theme/theme.dart';

import 'features/auth/presentation/login_page.dart';
import 'features/patients/presentation/patients_page.dart';

class VireLinkApp extends StatelessWidget {
  const VireLinkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
      ],
      child: MaterialApp(
        title: 'VireLink',
        theme: buildVireLinkTheme(),
        debugShowCheckedModeBanner: false,
        routes: {
          '/': (_) => const LoginPage(),
          '/patients': (_) => const PatientsPage(),
        },
      ),
    );
  }
}
