import 'package:firebase_auth/firebase_auth.dart' hide EmailAuthProvider, PhoneAuthProvider;
import 'package:flutter/material.dart';
import 'package:flutter_timezone/flutter_timezone.dart';

class ApplicationState extends ChangeNotifier {
  ApplicationState() {
    init();
  }

  bool _loggedIn = false;
  bool get loggedIn => _loggedIn;

  bool _emailVerified = false;
  bool get emailVerified => _emailVerified;

  //storing user's timezone in state prevents me from having to make async calls everywhere to get it
  String _loginUserTimeZone = '';
  String get loginUserTimeZone => _loginUserTimeZone;

  String _loginUserDocumentId = '';
  String get loginUserDocumentId => _loginUserDocumentId;

  Future<void> init() async {
    FirebaseAuth.instance.userChanges().listen((user) {
      if (user != null) {
        _loggedIn = true;
        _emailVerified = user.emailVerified;
        _loginUserDocumentId = user.uid;
      } else {
        _loggedIn = false;
        _emailVerified = false;
      }
      notifyListeners();
    });

    try {
      _loginUserTimeZone = await FlutterTimezone.getLocalTimezone();
    } catch (e) {
      print('Could not get local timezone: $e'); //TODO: handle this error better
    }
  }
}
