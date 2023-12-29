import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// displays the details of a document in a ListView.builder
Widget getDocumentDetailsWidget(Map<String, dynamic> map, String imageKey) {
  //remove imageUrl from map so it dooesn't get displayed in the
  //ListView.builder and so it can be displayed separately
  var imageUrl = map.remove(imageKey);
  return Column(
    children: [
      imageUrl != null
          ? Image.network(imageUrl)
          : const Icon(Icons.image_not_supported),
      Expanded(
        child: ListView.builder(
          itemCount: map.length,
          itemBuilder: (context, index) {
            var key = map.keys.elementAt(index);
            dynamic value = map[key];
            if (value is Timestamp) {
              // Convert the Timestamp to DateTime
              DateTime date = value.toDate();
              value = DateFormat('yyyy-MM-dd – kk:mm').format(date);
            }
            return Card(
              child: ListTile(title: Text(key), subtitle: Text(value ?? '')),
            );
          },
        ),
      ),
    ],
  );
}

/// TODO create a getDocumentDetailsWidgetEditable() function

ListTile getDocumentTile(Map<String, dynamic> map, String titleKey,
    String descriptionKey, String imageKey) {
  return ListTile(
    leading: map[imageKey] != null
        ? Image.network(map[imageKey]!)
        : const Icon(Icons.image_not_supported),
    title: Text(map[titleKey] ?? '<no name>'),
    subtitle: Text(map[descriptionKey]),
  );
}
