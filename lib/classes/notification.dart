///current plan for notifications is to have them stored in an array of Maps in the user document
///an instance of NOtification represents a single node in that array

enum NotificationTypes {
  friendRequest,
}

class Notification {
  static const String titleKey = 'title';
  static const String descriptionKey = 'description';
  static const String typeKey = 'type';

  String title;
  String description;
  int type;

  Notification({
    required this.title,
    required this.description,
    required this.type,
  });

  //creates a notification from a single
  factory Notification.fromNotificationArray(Map<String, String> notificationMap) {
    _retreivedFirestoreDataAssertions(notificationMap);
    return Notification(
      title: notificationMap[titleKey]!,
      description: notificationMap[descriptionKey]!,
      type: int.tryParse(notificationMap[typeKey]!)!,
    );
  }

  ///This method is used to ensure that the data retrieved from firestore is in the correct format
  static void _retreivedFirestoreDataAssertions(Map<String, String> notificationMap) {
    assert(notificationMap.containsKey(titleKey), 'Notification map does not contain title key which is required and should never be missing');
    assert(notificationMap.containsKey(descriptionKey), 'Notification map does not contain description key which is required and should never be missing');
    assert(notificationMap.containsKey(typeKey), 'Notification map does not contain type key which is required and should never be missing');
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
