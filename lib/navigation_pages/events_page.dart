import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get_together/main.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import '../classes/group.dart';
import '../classes/event.dart';
import '../widgets/image_with_null_error_handling.dart';

class EventsPage extends StatefulWidget {
  const EventsPage({super.key});

  @override
  _EventsPageState createState() => _EventsPageState();
}

class _EventsPageState extends State<EventsPage> {
  void _showAddEventDialog(BuildContext context, ApplicationState appState) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Select Group'),
          content: FutureBuilder<QuerySnapshot>(
            future: FirebaseFirestore.instance.collection(Group.collectionName).where(Group.adminsKey, arrayContains: appState.loginUserDocumentId).get(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Text('Error: ${snapshot.error}');
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const CircularProgressIndicator();
              }

              if (!snapshot.hasData) {
                return const Text('No data');
              }

              return ListView.builder(
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  var group = Group.fromDocumentSnapshot(snapshot.data!.docs[index]);
                  //this code relies on knowing the group structure. would be better if it didn't
                  //I tried to extract this as group method to return the ListTile, but I couldn't get the navigfation to work
                  return ListTile(
                      leading: ImageWithNullAndErrorHandling(imageUrl: group.imageUrl),
                      title: Text(group.name ?? '<No Name>'),
                      subtitle: group.description != null ? Text(group.description!) : null,
                      onTap: () {
                        //TODO: Implement this
                      });
                },
              );
            },
          ),
        );
      },
    );
  }

  //TODO: next up: implement events page
  @override
  Widget build(BuildContext context) {
    ApplicationState appState = Provider.of<ApplicationState>(context);
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false, //prevent back button from displaying, shouldn't be necessary but this is all I could figure out for now
        title: const Text('Groups'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEventDialog(context, appState),
        child: Icon(Icons.add),
      ),
      body: FutureBuilder<QuerySnapshot>(
        future: FirebaseFirestore.instance.collection(Group.collectionName).where(Group.membersKey, arrayContains: appState.loginUserDocumentId).get(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}');
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const CircularProgressIndicator();
          }

          if (!snapshot.hasData) {
            return const Text('No data');
          }

          List<String> groupDocumentIds = [];
          for (DocumentSnapshot doc in snapshot.data!.docs) {
            groupDocumentIds.add(doc.id);
          }

          return FutureBuilder<QuerySnapshot>(
              future: FirebaseFirestore.instance.collection(Event.collectionName).where(Event.groupDocumentIdKey, whereIn: groupDocumentIds).get(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                }

                if (!snapshot.hasData) {
                  return const Text('No data');
                }

                return ListView.separated(
                  itemCount: snapshot.data!.docs.length,
                  separatorBuilder: (context, index) => Divider(height: 10),
                  itemBuilder: (context, index) {
                    Event event = Event.fromDocumentSnapshot(snapshot.data!.docs[index]);
                    //this code relies on knowing the group structure. would be better if it didn't
                    //I tried to extract this as group method to return the ListTile, but I couldn't get the navigfation to work
                    return ListTile(
                        title: Text(event.title),
                        subtitle: Text(event.description),
                        trailing: Text(event.startTime.toIso8601String()),
                        onTap: () {
                          //TODO: Implement this
                        });
                  },
                );
              });
        },
      ),
    );
  }
}
