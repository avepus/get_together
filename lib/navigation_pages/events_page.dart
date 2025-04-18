import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';

import '../app_state.dart';
import '../classes/group.dart';
import '../classes/event.dart';
import '../widgets/image_with_null_error_handling.dart';
import '../update_event.dart';
import '../firebase.dart';

class EventsPage extends StatefulWidget {
  const EventsPage({super.key});

  @override
  _EventsPageState createState() => _EventsPageState();
}

class _EventsPageState extends State<EventsPage> {
  @override
  Widget build(BuildContext context) {
    //temporarily testing notificaitons here
    //requestNotificationPermission();

    ApplicationState appState = Provider.of<ApplicationState>(context);
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false, //prevent back button from displaying, shouldn't be necessary but this is all I could figure out for now
        title: const Text('Events'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEventDialog(context, appState),
        child: Icon(Icons.add),
      ),
      body: FutureBuilder<QuerySnapshot>(
        future: FirebaseFirestore.instance.collection(Group.collectionName).where(Group.membersKey, arrayContains: appState.loginUserDocumentId).get(const GetOptions(source: Source.server)),
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

          if (snapshot.data!.docs.isEmpty) {
            return const Text('You are not a member of any groups. Join a group to see events.');
          }

          Map<String, Group> groupMap = {};
          for (DocumentSnapshot doc in snapshot.data!.docs) {
            groupMap[doc.id] = Group.fromDocumentSnapshot(doc);
          }

          return FutureBuilder<QuerySnapshot>(
              //TODO: need to add a filter to show only events with end times in the future
              ///may want to query back a month and only show future by default with a button to show all
              future: FirebaseFirestore.instance.collection(Event.collectionName).where(Event.groupDocumentIdKey, whereIn: groupMap.keys).get(),
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

                if (snapshot.data!.docs.isEmpty) {
                  return const Text('No upcoming events found for your groups');
                }

                List<Event> events = [];
                for (DocumentSnapshot doc in snapshot.data!.docs) {
                  Event event = Event.fromDocumentSnapshot(doc);
                  events.add(event);
                }
                events.sort((a, b) => a.startTime.compareTo(b.startTime));

                return ListView.separated(
                  itemCount: events.length,
                  separatorBuilder: (context, index) => Divider(height: 10),
                  itemBuilder: (context, index) {
                    Event event = events[index];
                    //this code relies on knowing the group structure. would be better if it didn't
                    //I tried to extract this as group method to return the ListTile, but I couldn't get the navigfation to work

                    return ListTile(
                        title: Text(event.title, maxLines: 1),
                        leading: ImageWithNullAndErrorHandling(imageUrl: groupMap[event.groupDocumentId]!.imageUrl),
                        subtitle: Text(groupMap[event.groupDocumentId]!.name ?? '', maxLines: 1),
                        trailing: Text(DateFormat.MMMd().add_jm().format(event.startTime)),
                        onTap: () {
                          context.pushNamed('event', extra: {'event': event});
                        });
                  },
                );
              });
        },
      ),
    );
  }

  void _showAddEventDialog(BuildContext context, ApplicationState appState) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Select Group'),
          content: Container(
            height: 500,
            width: 300,
            child: FutureBuilder<QuerySnapshot>(
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
                    Group group = Group.fromDocumentSnapshot(snapshot.data!.docs[index]);
                    //this code relies on knowing the group structure. would be better if it didn't
                    //I tried to extract this as group method to return the ListTile, but I couldn't get the navigfation to work
                    return ListTile(
                        leading: ImageWithNullAndErrorHandling(imageUrl: group.imageUrl),
                        title: Text(
                          group.name ?? '<No Name>',
                          maxLines: 1,
                        ),
                        subtitle: group.description != null
                            ? Text(
                                group.description!,
                                maxLines: 1,
                              )
                            : null,
                        onTap: () {
                          context.pop();
                          //TODO: get rid of magic number 5 below
                          showAddEventDialog(context, group, appState.loginUserDocumentId!, group.meetingDurationTimeSlots, 5);
                        });
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }
}
