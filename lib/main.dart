import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'profile_page.dart';
import 'home_page.dart';
import 'login_page.dart';
import 'singup_page.dart';

void main() {
  runApp(const MyApp());
}

final GoRouter _router = GoRouter(routes: [
  GoRoute(path: '/', builder: (context, state) => const HomePage()),
  GoRoute(path: '/profile', builder: (context, state) => const ProfilePage()),
  GoRoute(path: '/login', builder: (context, state) => const LogInPage()),
  GoRoute(path: '/signup', builder: (context, state) => const SignupPage()),
]);

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Testing',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      routerConfig: _router,
    );
  }
}
