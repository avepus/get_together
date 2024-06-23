import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../classes/app_notification.dart';
import '../app_state.dart';
import '../classes/app_user.dart';
import '../classes/app_notification.dart';

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
            StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance.collection('users').doc(appState.loginUserDocumentId).snapshots(),
              builder: (context, appUserSnapshot) {
                if (appUserSnapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox(width: 50, child: CircularProgressIndicator());
                } else if (appUserSnapshot.hasError) {
                  return Text("Error: ${appUserSnapshot.error}");
                } else if (!appUserSnapshot.hasData || appUserSnapshot.data == null) {
                  return const Text("No data found");
                } else {
                  AppUser user = AppUser.fromDocumentSnapshot(appUserSnapshot.data!);
                  return ListView.builder(
                      itemCount: user.notifications.length,
                      itemBuilder: (context, index) {
                        AppNotification notification = AppNotification.fromNotificationArray(user.notifications[index]);
                        return notification.toListTile();
                      });
                }
              },
            ),
            //TODO: Create button to create a notification. AppUser will probably need a method to add a notification to the list
            //TODO: update page to display notifications
          ],
        ));
  }
}
