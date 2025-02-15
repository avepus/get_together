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
import 'package:timezone/data/latest.dart' as tz;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'firebase.dart';
import 'app_state.dart';
import 'main_navigator.dart';
import 'navigation_pages/profile_page.dart';
import 'navigation_pages/group_details_page.dart';
import 'update_event.dart';
import 'classes/group.dart';
import 'classes/event.dart';
import 'navigation_pages/event_details_page.dart';
import 'navigation_pages/notifications_page.dart';
import 'event_proposal_page.dart';
import 'classes/event_proposal.dart';

///todo list
///display responses on the event details screen (not update screen)
///propose event functionality with multiple time slot options that will default based on their availability but they can overwrite
///restrict adding people to groups to only seeing friends
///
//low priority todo list
///filter out past events and cancelled events from page and add checkbox to optionally show them
//add caching

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  bool kDebugMode = true;
  if (kDebugMode) {
    print("Handling a background message: ${message.messageId}");
    print('Message data: ${message.data}');
    print('Message notification: ${message.notification?.title}');
    print('Message notification: ${message.notification?.body}');
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  tz.initializeTimeZones();

  FirebaseUIAuth.configureProviders([
    EmailAuthProvider(),
  ]);

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  runApp(ChangeNotifierProvider(
    create: (context) => ApplicationState(),
    //ApplicaitonState has an async call in init so lazy is false to ensure async call is complete before the data is needed
    lazy: false,
    builder: ((context, child) => App()),
  ));
}

final _router = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      name: 'home',
      builder: (context, state) => const MainNavigation(initialPage: Pages.groups),
      redirect: (context, state) {
        if (FirebaseAuth.instance.currentUser == null) {
          return '/sign-in';
        } else {
          //else, remain at current page
          return null;
        }
      },
      routes: [
        GoRoute(path: 'events', name: 'events', builder: (context, state) => const MainNavigation(initialPage: Pages.events)),
        GoRoute(
            path: 'profile/:userDocumentId',
            name: 'profile',
            builder: (context, state) {
              return ProfilePage(userDocumentId: state.pathParameters['userDocumentId']!);
            }),
        GoRoute(
            path: 'group/:groupDocumentId',
            name: 'group',
            builder: (context, state) {
              return GroupDetailsPage(groupDocumentId: state.pathParameters['groupDocumentId']!);
            }),
        GoRoute(
            path: 'event/:eventDocumentId',
            name: 'event',
            builder: (context, state) {
              Map<String, dynamic>? map = state.extra as Map<String, dynamic>?;
              Event? event = map?['event'] as Event?;
              String? eventDocumentId = state.pathParameters['eventDocumentId'];

              if (state.extra == null && state.pathParameters['eventDocumentId'] == null) {
                context.pushReplacement('/');
              }
              return EventDetailsPage(event: event, eventDocumentId: eventDocumentId);
            }),
        GoRoute(
          path: 'eventProposal/:eventProposalDocumentId',
          name: 'eventProposal',
          builder: (context, state) {
            Map<String, dynamic>? map = state.extra as Map<String, dynamic>?;
            EventProposal? eventProposal = map?['eventProposal'] as EventProposal?;
            String? eventProposalDocumentId = state.pathParameters['eventProposalDocumentId'];
            Group? group = map?['group'] as Group?;

            if (eventProposal == null && eventProposalDocumentId == null) {
              return Scaffold(body: Center(child: Text('No event proposal provdided. You should not see this message ever.')));
            }

            if (eventProposal != null && group != null) {
              return EventProposalPage(eventProposal: eventProposal, group: group);
            }

            //remaining cases are when eventProposal is null and we need to retreive it
            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance.collection(EventProposal.collectionName).doc(eventProposalDocumentId).get(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Scaffold(
                    appBar: AppBar(title: Text('Loading...')),
                    body: Center(child: CircularProgressIndicator()),
                  );
                } else if (snapshot.hasError) {
                  return Scaffold(
                    appBar: AppBar(title: Text('Error')),
                    body: Center(child: Text('Error: ${snapshot.error}')),
                  );
                } else if (!snapshot.hasData || !snapshot.data!.exists) {
                  return Scaffold(
                    appBar: AppBar(title: Text('Event Proposal Not Found')),
                    body: Center(child: Text('Event Proposal with id "$eventProposalDocumentId" was not found')),
                  );
                } else {
                  eventProposal = EventProposal.fromDocumentSnapshot(snapshot.data!);

                  if (group != null) {
                    return EventProposalPage(eventProposal: eventProposal!, group: group!);
                  }

                  return FutureBuilder<DocumentSnapshot>(
                    future: FirebaseFirestore.instance.collection(Group.collectionName).doc(eventProposal!.groupDocumentId).get(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Scaffold(
                          appBar: AppBar(title: Text('Loading...')),
                          body: Center(child: CircularProgressIndicator()),
                        );
                      } else if (snapshot.hasError) {
                        return Scaffold(
                          appBar: AppBar(title: Text('Error')),
                          body: Center(child: Text('Error: ${snapshot.error}')),
                        );
                      } else if (!snapshot.hasData || !snapshot.data!.exists) {
                        return Scaffold(
                          appBar: AppBar(title: Text('Group Not Found')),
                          body: Center(child: Text('Group with id "${eventProposal!.groupDocumentId}" was not found')),
                        );
                      } else {
                        group = Group.fromDocumentSnapshot(snapshot.data!);
                        return EventProposalPage(eventProposal: eventProposal!, group: group!);
                      }
                    },
                  );
                }
              },
            );
          },
        ),
        GoRoute(
            path: 'updateEvent',
            name: 'updateEvent',
            builder: (context, state) {
              if (state.extra == null) {
                context.pushReplacement('/');
              }
              Map<String, dynamic> map = state.extra! as Map<String, dynamic>;
              if (map['group'] == null) {
                //always need the group passed
                context.pushReplacement('/');
              }
              assert(map['event'] != null, 'Event must be passed to updateEvent route');
              if (map['event'] == null) {
                //need an event passed in
                context.pushReplacement('/');
              }
              Group group = map['group'] as Group;
              return UpdateEventPage(group: group, event: map['event']);
            }),
        GoRoute(
          path: 'sign-in',
          builder: (context, state) {
            return SignInScreen(
              providers: [
                EmailAuthProvider(),
              ],
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
                  final user = switch (state) { SignedIn state => state.user, UserCreated state => state.credential.user, _ => null };
                  if (user == null) {
                    return;
                  }
                  if (state is UserCreated) {
                    user.updateDisplayName(user.email!.split('@')[0]);
                    //I don't know for sure that the follwing user.email! is safe. It should be according to https://firebase.google.com/docs/auth/users
                    createFirestoreUser(user.email!.split('@')[0], user.email!, user.uid);
                  }
                  if (!user.emailVerified) {
                    //user.sendEmailVerification();
                    //const snackBar = SnackBar(content: Text('Please check your email to verify your email address'));
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
