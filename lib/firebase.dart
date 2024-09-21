import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get_together/classes/app_notification.dart';
import 'classes/app_user.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';
import 'package:rxdart/rxdart.dart';

import 'classes/group.dart';
import 'classes/app_notification.dart';
import 'classes/event.dart';

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

/// Creates a Firestore user with the given [displayName], [email], and [uid].
///
/// This function creates a new Firestore user document in the AppUser collection
/// with the provided user information. The user's document ID will be set to [uid],
/// and the user's display name, email, and creation time will be set based on the
/// provided parameters. The user's information is stored in a [AppUser] object,
/// which is converted to a map using the [toMap] method.
///
/// Example usage:
/// ```dart
/// await createFirestoreUser('John Doe', 'johndoe@example.com', '123456789');
/// ```
///
/// Throws an error if there is an issue setting the user document in Firestore.
Future<void> createFirestoreUser(String displayName, String email, String uid) async {
  CollectionReference users = FirebaseFirestore.instance.collection(AppUser.collectionName);
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

Future<void> addFriendsFirestore(String user1, String user2) async {
  CollectionReference users = FirebaseFirestore.instance.collection(AppUser.collectionName);
  users.doc(user1).update({
    AppUser.friendsKey: FieldValue.arrayUnion([user2]),
  });
  users.doc(user2).update({
    AppUser.friendsKey: FieldValue.arrayUnion([user1]),
  });
  return;
}

/// Removes the specified users from each other's friends list in Firestore.
/// This is always bidirectional since you must be friends with each other
///
/// The [user1] and [user2] parameters represent the IDs of the users to be removed from each other's friends list.
/// This method updates the Firestore documents for both users, removing the corresponding user ID from their friends list.
///
/// Returns a [Future] that completes when the updates are successfully applied to Firestore.
Future<void> removeFromFriendsFirestore(String user1, String user2) async {
  CollectionReference users = FirebaseFirestore.instance.collection(AppUser.collectionName);
  users.doc(user1).update({
    AppUser.friendsKey: FieldValue.arrayRemove([user2]),
  });
  users.doc(user2).update({
    AppUser.friendsKey: FieldValue.arrayRemove([user1]),
  });
  return;
}

Future<List<AppUser>> fetchFirestoreAppUsers(List<String> userIds) async {
  List<AppUser> users = [];

  for (var userId in userIds) {
    DocumentSnapshot snapshot = await FirebaseFirestore.instance.collection(AppUser.collectionName).doc(userId).get();

    if (snapshot.exists) {
      AppUser user = AppUser.fromDocumentSnapshot(snapshot);
      users.add(user);
    } else {
      //should probably log this
    }
    ;
  }

  return users;
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

Future<void> deleteFriendRequestNotificationsFromUserPair(AppUser user1, AppUser user2) async {
  //first remove the notification from user1's notifications
  user1.notifications.removeWhere((notification) {
    AppNotification appNotif = AppNotification.fromNotificationArray(notification);
    return appNotif.type == NotificationType.friendRequest && appNotif.routeToDocumentId == user2.documentId;
  });

  user2.notifications.removeWhere((notification) {
    AppNotification appNotif = AppNotification.fromNotificationArray(notification);
    return appNotif.type == NotificationType.friendRequest && appNotif.routeToDocumentId == user1.documentId;
  });

  await FirebaseFirestore.instance.collection(AppUser.collectionName).doc(user1.documentId).update({AppUser.notificationsKey: user1.notifications});
  await FirebaseFirestore.instance.collection(AppUser.collectionName).doc(user2.documentId).update({AppUser.notificationsKey: user2.notifications});
}

Future<void> markEventAsCancelled(Event event, Group group) async {
  assert(event.documentId != null, 'Event document ID is null but it never should be when we are attempting to cancel');
  CollectionReference events = FirebaseFirestore.instance.collection(Event.collectionName);
  events.doc(event.documentId).update({
    Event.isCancelledKey: true,
  });
}

Future<void> addNotificationToUser(AppNotification notification, String userDocumentId) async {
  FirebaseFirestore.instance.collection(AppUser.collectionName).doc(userDocumentId).update({
    AppUser.notificationsKey: FieldValue.arrayUnion([notification.toMap()]),
  });
}
