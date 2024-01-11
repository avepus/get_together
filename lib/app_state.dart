import 'package:firebase_auth/firebase_auth.dart'
    hide EmailAuthProvider, PhoneAuthProvider;
import 'package:flutter/material.dart';

class ApplicationState extends ChangeNotifier {
  ApplicationState() {
    init();
  }

  bool _loggedIn = false;
  bool get loggedIn => _loggedIn;

  bool _emailVerified = false;
  bool get emailVerified => _emailVerified;

  Future<void> init() async {
    FirebaseAuth.instance.userChanges().listen((user) {
      if (user != null) {
        _loggedIn = true;
        _emailVerified = user.emailVerified;
      } else {
        _loggedIn = false;
        _emailVerified = false;
      }
      notifyListeners();
    });
  }
}
