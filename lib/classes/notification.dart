import 'package:cloud_firestore/cloud_firestore.dart';

///current plan for notifications is to have them stored in an array of Maps in the user document
///an instance of NOtification represents a single node in that array

enum NotificationTypes {
  friendRequest,
}

class Notification {
  static const String titleKey = 'title';
  static const String descriptionKey = 'description';
  static const String typeKey = 'type';
  static const String createdTimeKey = 'createdTime';

  String title;
  String description;
  int type;
  Timestamp createdTime;

  Notification({
    required this.title,
    required this.description,
    required this.type,
    required this.createdTime,
  });

  //creates a notification from a single
  factory Notification.fromNotificationArray(Map<String, dynamic> notificationMap) {
    _retreivedFirestoreDataAssertions(notificationMap);
    return Notification(
      title: notificationMap[titleKey]!,
      description: notificationMap[descriptionKey]!,
      type: int.tryParse(notificationMap[typeKey]!)!,
      createdTime: notificationMap[createdTimeKey]!,
    );
  }

  ///This method is used to ensure that the data retrieved from firestore is in the correct format
  static void _retreivedFirestoreDataAssertions(Map<String, dynamic> notificationMap) {
    assert(notificationMap.containsKey(titleKey), 'Notification map does not contain title key which is required and should never be missing');
    assert(notificationMap.containsKey(descriptionKey), 'Notification map does not contain description key which is required and should never be missing');
    assert(notificationMap.containsKey(typeKey), 'Notification map does not contain type key which is required and should never be missing');
    assert(notificationMap.containsKey(createdTimeKey), 'Notification map does not contain createdTime key which is required and should never be missing');
    int? typeValue = int.tryParse(notificationMap[typeKey]!);
    assert(typeValue != null, 'Notification type value is not an integer');
  }

  Map<String, dynamic> toMap() {
    return {
      titleKey: title,
      descriptionKey: description,
      typeKey: type,
    };
  }
}
