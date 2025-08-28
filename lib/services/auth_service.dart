import 'package:flutter/foundation.dart';

class AuthService extends ChangeNotifier {
  bool _loggedIn = false;
  bool get isLoggedIn => _loggedIn;

  Future<bool> login(String username, String password) async {
    // MVP: hyväksytään mikä tahansa ei-tyhjä yhdistelmä
    await Future.delayed(const Duration(milliseconds: 300));
    _loggedIn = username.isNotEmpty && password.isNotEmpty;
    notifyListeners();
    return _loggedIn;
  }

  void logout() {
    _loggedIn = false;
    notifyListeners();
  }
}
