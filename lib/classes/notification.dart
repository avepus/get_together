import 'package:cloud_firestore/cloud_firestore.dart';

///current plan for notifications is to have them stored in an array of Maps in the user document

class Notification {
  static const String collectionName = 'notifications';
  static const String titleKey = 'title';
  static const String descriptionKey = 'description';
  static const String typeKey = 'type';
  static const String routeKey = 'route';

  String documentId = '';
  String title;
  String description;
  String type;
  String route;

  Notification({
    required this.title,
    required this.description,
    required this.type,
    required this.route,
  });

  Map<String, dynamic> toMap() {
    return {
      titleKey: title,
      descriptionKey: description,
      typeKey: type,
      routeKey: route,
    };
  }

  Future<void> saveToFirestore() async {
    if (documentId != '') {
      await FirebaseFirestore.instance.collection(collectionName).doc(documentId).set(toMap());
    } else {
      DocumentReference ref = await FirebaseFirestore.instance.collection(collectionName).add(toMap());
      documentId = ref.id;
    }
  }

  void deleteFromFirestore() {
    if (documentId != '') {
      FirebaseFirestore.instance.collection(collectionName).doc(documentId).delete();
    }
  }
}
