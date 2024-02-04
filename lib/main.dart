// Copyright 2022 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart' hide EmailAuthProvider;
import 'firebase_options.dart';

import 'firebase.dart';
import 'app_state.dart';
import 'main_navigator.dart';
import 'navigation_pages/profile_page.dart';
import 'navigation_pages/group_details_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  FirebaseUIAuth.configureProviders([
    EmailAuthProvider(),
  ]);

  runApp(ChangeNotifierProvider(
    create: (context) => ApplicationState(),
    builder: ((context, child) => App()),
  ));
}

final _router = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const MainNavigation(),
      redirect: (context, state) {
        if (FirebaseAuth.instance.currentUser == null) {
          return '/sign-in';
        } else {
          //else, remain at current page
          return null;
        }
      },
      routes: [
        GoRoute(
            path: 'profile/:userDocumentId',
            name: 'profile',
            builder: (context, state) {
              return ProfilePage(
                  userDocumentId: state.pathParameters['userDocumentId']!);
            }),
        GoRoute(
            path: 'group/:groupDocumentId',
            name: 'group',
            builder: (context, state) {
              return GroupDetailsPage(
                  groupDocumentId: state.pathParameters['groupDocumentId']!);
            }),
        GoRoute(
          path: 'sign-in',
          builder: (context, state) {
            return SignInScreen(
              actions: [
                ForgotPasswordAction(((context, email) {
                  //TODO: this is not working
                  final uri = Uri(
                    path: '/sign-in/forgot-password',
                    queryParameters: <String, String?>{
                      'email': email,
                    },
                  );
                  context.push(uri.toString());
                })),
                AuthStateChangeAction(((context, state) {
                  final user = switch (state) {
                    SignedIn state => state.user,
                    UserCreated state => state.credential.user,
                    _ => null
                  };
                  if (user == null) {
                    return;
                  }
                  if (state is UserCreated) {
                    user.updateDisplayName(user.email!.split('@')[0]);
                    //I don't know for sure that the follwing user.email! is safe. It should be according to https://firebase.google.com/docs/auth/users
                    createFirestoreUser(
                        user.email!.split('@')[0], user.email!, user.uid);
                  }
                  if (!user.emailVerified) {
                    //user.sendEmailVerification();
                    const snackBar = SnackBar(
                        content: Text(
                            'Please check your email to verify your email address'));
                    //ScaffoldMessenger.of(context).showSnackBar(snackBar);
                  }
                  context.pushReplacement('/');
                })),
              ],
            );
          },
          routes: [
            GoRoute(
              path: 'forgot-password',
              builder: (context, state) {
                final arguments = state.uri.queryParameters;
                return ForgotPasswordScreen(
                  email: arguments['email'],
                  headerMaxExtent: 200,
                );
              },
            ),
          ],
        ),
      ],
    ),
  ],
);

class App extends StatelessWidget {
  App({super.key});

  final providers = [EmailAuthProvider()];

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'GetTogether',
      themeMode: ThemeMode.dark,
      theme: ThemeData(
        buttonTheme: Theme.of(context).buttonTheme.copyWith(
              highlightColor: Colors.deepPurple,
            ),
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        textTheme: GoogleFonts.robotoTextTheme(
          Theme.of(context).textTheme,
        ),
        visualDensity: VisualDensity.adaptivePlatformDensity,
        useMaterial3: true,
      ),
      darkTheme: ThemeData.dark(),
      routerConfig: _router,
    );
  }
}
