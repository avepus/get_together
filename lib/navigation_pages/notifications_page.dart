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
    Stream<DocumentSnapshot> _userStream = FirebaseFirestore.instance.collection('users').doc(appState.loginUserDocumentId).snapshots();
    return Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false, //prevent back button from displaying, shouldn't be necessary but this is all I could figure out for now
          title: const Text('Notifications'),
        ),
        floatingActionButton: CreateNotification(userStream: _userStream),
        body: StreamBuilder<DocumentSnapshot>(
          stream: _userStream,
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
        ));
  }
}

class CreateNotification extends StatelessWidget {
  const CreateNotification({
    super.key,
    required this.userStream,
  });

  final Stream<DocumentSnapshot> userStream;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
        stream: userStream,
        builder: (context, appUserSnapshot) {
          if (appUserSnapshot.connectionState == ConnectionState.waiting) {
            return const SizedBox(width: 50, child: CircularProgressIndicator());
          } else if (appUserSnapshot.hasError) {
            return Text("Error: ${appUserSnapshot.error}");
          } else if (!appUserSnapshot.hasData || appUserSnapshot.data == null) {
            return const Text("No data found");
          } else {
            AppUser user = AppUser.fromDocumentSnapshot(appUserSnapshot.data!);
            return ElevatedButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    String title = '';
                    String description = '';
                    String type = '';

                    return AlertDialog(
                      title: const Text('Create Notification'),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextField(
                            onChanged: (value) {
                              title = value;
                            },
                            decoration: const InputDecoration(
                              labelText: 'Title',
                            ),
                          ),
                          TextField(
                            onChanged: (value) {
                              description = value;
                            },
                            decoration: const InputDecoration(
                              labelText: 'Description',
                            ),
                          ),
                          TextField(
                            onChanged: (value) {
                              type = value;
                            },
                            decoration: const InputDecoration(
                              labelText: 'Type',
                            ),
                          ),
                        ],
                      ),
                      actions: [
                        ElevatedButton(
                          onPressed: () {
                            AppNotification newNotification = AppNotification(
                              title: title,
                              description: description,
                              type: int.tryParse(type) ?? 0,
                              createdTime: Timestamp.now(),
                            );
                            FirebaseFirestore.instance.collection('users').doc(user.documentId).update({
                              AppUser.notificationsKey: FieldValue.arrayUnion([newNotification.toMap()]),
                            });
                            Navigator.of(context).pop();
                          },
                          child: const Text('Create'),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: const Text('Cancel'),
                        ),
                      ],
                    );
                  },
                );
              },
              child: const Text('Create Notification'),
            );
          }
        });
  }
}
