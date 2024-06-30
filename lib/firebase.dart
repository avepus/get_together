import 'package:cloud_firestore/cloud_firestore.dart';
import 'classes/app_user.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';
import 'package:rxdart/rxdart.dart';

import 'classes/group.dart';

Future<List<AppUser>> fetchAllUsers() async {
  CollectionReference users = FirebaseFirestore.instance.collection('users');
  QuerySnapshot querySnapshot = await users.get();
  List<AppUser> userList = [];

  for (var doc in querySnapshot.docs) {
    AppUser user = AppUser.fromDocumentSnapshot(doc);
    userList.add(user);
  }

  return userList;
}

//takes in a list of user documentIds and stores them in the specified group field
Future<void> storeUserIdsListInGroup(List<String> userDocumentIds, String groupDocumentId, String fieldKey) async {
  CollectionReference groups = FirebaseFirestore.instance.collection(Group.collectionName);

  Map<String, dynamic> data = {
    fieldKey: userDocumentIds,
  };

  await groups.doc(groupDocumentId).update(data);
}

//helper function that takes in list of AppUsers and stores their documentIds in a group
Future<void> storeUserListInGroup(List<AppUser> users, String groupDocumentId, String fieldKey) async {
  List<String> userDocumentIds = users.map((user) => user.documentId).toList();
  await storeUserIdsListInGroup(userDocumentIds, groupDocumentId, fieldKey);
}

Future<void> createFirestoreUser(String displayName, String email, String uid) async {
  CollectionReference users = FirebaseFirestore.instance.collection('users');
  final timestamp = Timestamp.now();
  AppUser user = AppUser(
    documentId: uid,
    uniqueUserId: uid,
    displayName: displayName,
    email: email,
    createdTime: timestamp,
  );

  users.doc(uid).set(user.toMap());
  return;
}

Future<void> deleteFirestoreGroup(String groupDocumentId) async {
  CollectionReference groups = FirebaseFirestore.instance.collection('groups');
  groups.doc(groupDocumentId).delete();
  return;
}

Future<void> requestNotificationPermission() async {
  //TODO: remove this when done testing
  bool kDebugMode = true;
  final messaging = FirebaseMessaging.instance;

  final settings = await messaging.requestPermission(
    alert: true,
    announcement: false,
    badge: true,
    carPlay: false,
    criticalAlert: false,
    provisional: false,
    sound: true,
  );

  if (kDebugMode) print('Permission granted: ${settings.authorizationStatus}');

  // TODO: replace with your own VAPID key
  const vapidKey = 'BGYAwu6UzqoYdPVeJx0j9BqaeDyeI9Nhbyf3nr-zXSJ8zXQvO7j0islR_oFd-lMR6U7RsT5KPmE2HDonFc3Cl1M';
  String? token;

  // use the registration token to send messages to users from your trusted server environment

  //TODO: Left off here on stepf 5: https://firebase.google.com/codelabs/firebase-fcm-flutter#4
  if (DefaultFirebaseOptions.currentPlatform == DefaultFirebaseOptions.web) {
    token = await messaging.getToken(
      vapidKey: vapidKey,
    );
  } else {
    token = await messaging.getToken();
  }

  if (kDebugMode) print('Registration Token=$token');

  final _messageStreamController = BehaviorSubject<RemoteMessage>();
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    if (kDebugMode) {
      print('Handling a foreground message: ${message.messageId}');
      print('Message data: ${message.data}');
      print('Message notification: ${message.notification?.title}');
      print('Message notification: ${message.notification?.body}');
    }

    _messageStreamController.sink.add(message);
  });
}
