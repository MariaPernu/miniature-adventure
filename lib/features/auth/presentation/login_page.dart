import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../services/auth_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _userCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _doLogin() async {
    setState(() { _loading = true; _error = null;});
    final ok = await context.read<AuthService>().login(
      _userCtrl.text.trim(),
      _passCtrl.text,
    );
    setState(() => _loading = false);
    if (!mounted) return;
    if (ok) {
      Navigator.pushReplacementNamed(context, '/patients');
    } else {
      setState(() => _error = 'Tarkista tunnus ja salasana');
    }
  }

  @override
  Widget build(BuildContext context) {
    final spacing = const SizedBox(height: 18);
    final screenW = MediaQuery.of(context).size.width;
    final logoSize = (screenW * 0.4).clamp(120.0, 220.0);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom; // näppäimistö

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottomInset),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Iso logo + nimi
                      Image.asset(
                        'assets/icon.png',
                        width: logoSize,
                        height: logoSize,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'VireLink',
                        style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 32),

                      // Kentät
                      TextField(
                        controller: _userCtrl,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(hintText: 'Käyttäjätunnus'),
                      ),
                      spacing,
                      TextField(
                        controller: _passCtrl,
                        obscureText: true,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _loading ? null : _doLogin(),
                        decoration: const InputDecoration(hintText: 'Salasana'),
                      ),
                      const SizedBox(height: 28),

                      // Nappi
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _loading ? null : _doLogin,
                          child: _loading
                              ? const SizedBox(
                                  width: 18, height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Text('Kirjaudu sisään'),
                        ),
                      ),

                      if (_error != null) ...[
                        const SizedBox(height: 12),
                        Text(_error!, style: const TextStyle(color: Colors.red)),
                      ],
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
