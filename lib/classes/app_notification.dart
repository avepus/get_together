import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../utils.dart';

///current plan for notifications is to have them stored in an array of Maps in the user document
///an instance of NOtification represents a single node in that array

enum NotificationType { friendRequest, accptedFriendRequest, newEvent, updatedEvent, canceledEvent, groupRequest }

extension NotificationTypesIconExtension on NotificationType {
  IconData get icon {
    switch (this) {
      case NotificationType.friendRequest:
        return Icons.person_add;
      case NotificationType.accptedFriendRequest:
        return Icons.people;
      case NotificationType.newEvent:
        return Icons.event;
      case NotificationType.updatedEvent:
        return Icons.update;
      case NotificationType.canceledEvent:
        return Icons.cancel;
      case NotificationType.groupRequest:
        return Icons.group_add;
    }
  }

  String get namedRoute {
    switch (this) {
      case NotificationType.friendRequest:
        return 'profile';
      case NotificationType.accptedFriendRequest:
        return 'profile';
      case NotificationType.newEvent:
        return 'event';
      case NotificationType.updatedEvent:
        return 'event';
      case NotificationType.canceledEvent:
        return '';
      case NotificationType.groupRequest:
        return 'group';
    }
  }

  String get pathParameterKey {
    switch (this) {
      case NotificationType.friendRequest:
        return 'userDocumentId';
      case NotificationType.accptedFriendRequest:
        return 'userDocumentId';
      case NotificationType.newEvent:
        return 'eventDocumentId';
      case NotificationType.updatedEvent:
        return 'eventDocumentId';
      case NotificationType.canceledEvent:
        return '';
      case NotificationType.groupRequest:
        return 'groupDocumentId';
    }
  }
}

class AppNotification {
  static const String titleKey = 'title';
  static const String descriptionKey = 'description';
  static const String typeKey = 'type';
  static const String routeToDocumentIdKey = 'routeToDocumentId';
  static const String createdTimeKey = 'createdTime';

  String title;
  String description;
  NotificationType type;
  String routeToDocumentId;
  Timestamp createdTime;

  AppNotification({
    required this.title,
    required this.description,
    required this.type,
    required this.routeToDocumentId,
    required this.createdTime,
  });

  //creates a notification from a single element of the user's notifications array
  factory AppNotification.fromNotificationArray(Map<String, dynamic> notificationMap) {
    _retreivedFirestoreDataAssertions(notificationMap);
    return AppNotification(
      title: notificationMap[titleKey]!,
      description: notificationMap[descriptionKey]!,
      type: NotificationType.values[notificationMap[typeKey]!],
      routeToDocumentId: notificationMap[routeToDocumentIdKey]!,
      createdTime: notificationMap[createdTimeKey]!,
    );
  }

  ///This method is used to ensure that the data retrieved from firestore is in the correct format
  static void _retreivedFirestoreDataAssertions(Map<String, dynamic> notificationMap) {
    assert(notificationMap.containsKey(titleKey), 'Notification map does not contain title key which is required and should never be missing');
    assert(notificationMap.containsKey(descriptionKey), 'Notification map does not contain description key which is required and should never be missing');
    assert(notificationMap.containsKey(typeKey), 'Notification map does not contain type key which is required and should never be missing');
    assert(notificationMap.containsKey(routeToDocumentIdKey), 'Notification map does not contain routeToDocumentId key which is required and should never be missing');
    assert(notificationMap.containsKey(createdTimeKey), 'Notification map does not contain createdTime key which is required and should never be missing');
  }

  Map<String, dynamic> toMap() {
    return {
      titleKey: title,
      descriptionKey: description,
      typeKey: type.index, //toMap is used to save to firestore so we need to save the index of the enum
      routeToDocumentIdKey: routeToDocumentId,
      createdTimeKey: createdTime,
    };
  }

  ListTile toListTile(BuildContext context) {
    return ListTile(
      leading: Icon(type.icon),
      title: Text(title),
      subtitle: Text(description),
      trailing: Text(formatTimestamp(createdTime)),
      onTap: type.namedRoute.isNotEmpty
          ? () {
              context.goNamed(type.namedRoute, pathParameters: {type.pathParameterKey: routeToDocumentId});
            }
          : null,
    );
  }

  Future<void> saveToDocument({required String documentId, required String fieldKey, required String collection}) async {
    await FirebaseFirestore.instance.collection(collection).doc(documentId).update({
      fieldKey: FieldValue.arrayUnion([toMap()]),
    });
  }
}
