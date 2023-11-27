import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('home'),
        ),
        body: ListView(
          children: [
            ElevatedButton(
                onPressed: () => context.push("/profile"),
                child: const Text("Profile page")),
            ElevatedButton(
                onPressed: () => context.push("/login"),
                child: const Text("Login page")),
            ElevatedButton(
                onPressed: () => context.push("/signup"),
                child: const Text("Signup page")),
          ],
        ));
  }
}
