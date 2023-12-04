import 'package:flutter/material.dart';

class ApplicationState extends ChangeNotifier {
  ApplicationState();

  bool _loggedIn = false;
  bool get loggedIn => _loggedIn;

  void switchLoggedIn() {
    _loggedIn = !_loggedIn;
  }

  /*
    Future<void> init() async {
    await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform);

    FirebaseUIAuth.configureProviders([
      EmailAuthProvider(),
    ]);

    FirebaseAuth.instance.userChanges().listen((user) {
      if (user != null) {
        _loggedIn = true;
      } else {
        _loggedIn = false;
      }
      notifyListeners();
    });
  */
}
