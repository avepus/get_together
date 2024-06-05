import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../classes/notification.dart';
import '../app_state.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  _NotificationsPageState createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  @override
  Widget build(BuildContext context) {
    ApplicationState appState = Provider.of<ApplicationState>(context);
    return Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false, //prevent back button from displaying, shouldn't be necessary but this is all I could figure out for now
          title: const Text('Events'),
        ),
        body: Column(
          children: [
            Text('Placeholder for notifications'),
            ElevatedButton(
              onPressed: () {
                context.pushNamed('profile', pathParameters: {
                  'userDocumentId': appState.loginUserDocumentId!,
                });
              },
              child: const Text('Go To Profile Page'),
            ),
          ],
        ));
  }
}
