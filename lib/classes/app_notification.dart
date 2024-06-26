import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

///current plan for notifications is to have them stored in an array of Maps in the user document
///an instance of NOtification represents a single node in that array

enum NotificationTypes { friendRequest, newEvent, groupRequest }

extension NotificationTypesIconExtension on NotificationTypes {
  IconData get icon {
    switch (this) {
      case NotificationTypes.friendRequest:
        return Icons.person_add;
      case NotificationTypes.newEvent:
        return Icons.event;
      case NotificationTypes.groupRequest:
        return Icons.group_add;
    }
  }
}

class AppNotification {
  static const String titleKey = 'title';
  static const String descriptionKey = 'description';
  static const String typeKey = 'type';
  static const String createdTimeKey = 'createdTime';

  String title;
  String description;
  int type;
  Timestamp createdTime;

  AppNotification({
    required this.title,
    required this.description,
    required this.type,
    required this.createdTime,
  });

  //creates a notification from a single element of the user's notifications array
  factory AppNotification.fromNotificationArray(Map<String, dynamic> notificationMap) {
    _retreivedFirestoreDataAssertions(notificationMap);
    return AppNotification(
      title: notificationMap[titleKey]!,
      description: notificationMap[descriptionKey]!,
      type: notificationMap[typeKey]!,
      createdTime: notificationMap[createdTimeKey]!,
    );
  }

  ///This method is used to ensure that the data retrieved from firestore is in the correct format
  static void _retreivedFirestoreDataAssertions(Map<String, dynamic> notificationMap) {
    assert(notificationMap.containsKey(titleKey), 'Notification map does not contain title key which is required and should never be missing');
    assert(notificationMap.containsKey(descriptionKey), 'Notification map does not contain description key which is required and should never be missing');
    assert(notificationMap.containsKey(typeKey), 'Notification map does not contain type key which is required and should never be missing');
    assert(notificationMap.containsKey(createdTimeKey), 'Notification map does not contain createdTime key which is required and should never be missing');
  }

  Map<String, dynamic> toMap() {
    return {
      titleKey: title,
      descriptionKey: description,
      typeKey: type,
      createdTimeKey: createdTime,
    };
  }

  ListTile toListTile() {
    return ListTile(
      leading: Icon(NotificationTypes.values[type].icon),
      title: Text(title),
      subtitle: Text(description),
    );
  }
}
