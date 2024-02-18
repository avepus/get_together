import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';

import 'package:get_together/availability.dart';
import '../group.dart';

//This button will be used to add availability to the group for the logged in user
//the availability is an array of numbers -1, 0, 1, 2, 3 where
//    -1: 'Not Available',
//    0: 'Not Set',
//    1: 'Sometimes Available',
//    2: 'Usually Available',
//    3: 'Preferred Time'
//The array will be 336 elements long, one for each 30 minute increment in a week
//The array will be stored in the group document as a map where the key is the user's documentId
//when clicked, the user should first be prompted to choose which days of the week they are available
//Then the user will be prompted to choose which 30 minute increments they are available for the days they indicated they are available

class AvailabilityButton extends StatelessWidget {
  final String groupDocumentId;
  const AvailabilityButton({super.key, required this.groupDocumentId});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      child: Text('Set Availability'),
      onPressed: () {
        // Navigate to a new page or open a dialog here
        // This is where you'll ask the user for their availability
        // You'll need to create a new widget for this page/dialog
        Navigator.of(context).push(MaterialPageRoute(
          builder: (context) =>
              AvailabilityPageDay(groupDocumentId: groupDocumentId),
        ));
      },
    );
  }
}

class AvailabilityPageDay extends StatefulWidget {
  final String groupDocumentId;
  const AvailabilityPageDay({super.key, required this.groupDocumentId});
  @override
  _AvailabilityPageDayState createState() => _AvailabilityPageDayState();
}

class _AvailabilityPageDayState extends State<AvailabilityPageDay> {
  // This list will store the user's availability
  // It starts with all elements set to 0 (not available)
  var days = List<bool?>.filled(Days.values.length, false);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('Set Availability'),
        ),
        body: ListView.builder(
          itemCount: Days.values.length,
          itemBuilder: (context, index) {
            return CheckboxListTile(
              title: Text(Days.values[index].toString().split('.').last),
              value: days[index],
              onChanged: (value) {
                setState(() {
                  days[index] = value;
                });
              },
            );
          },
        ),
        bottomNavigationBar: BottomAppBar(
          child: ElevatedButton(
            child: Text('Submit'),
            onPressed: () {
              if (!days.contains(true)) {
                // Show snackbar message
                const snackBar =
                    SnackBar(content: Text('Please select at least one day.'));
                ScaffoldMessenger.of(context).showSnackBar(snackBar);
                return;
              }

              //the following line will populate an array of just the indexes of the days that are available. The indices represent the days of the week (with 0 as Sunday)
              Navigator.of(context).push(MaterialPageRoute(builder: (context) {
                List<int> availabileDays = days
                    .asMap()
                    .entries
                    .where((day) => day.value == true)
                    .map((day) => day.key)
                    .toList();
                return AvailabilityPageDetail(
                    groupDocumentId: widget.groupDocumentId,
                    days: availabileDays);
              }));
            },
          ),
        ));
  }
}

class AvailabilityPageDetail extends StatefulWidget {
  final String groupDocumentId;
  List<int> days;
  AvailabilityPageDetail(
      {super.key, required this.days, required this.groupDocumentId});
  @override
  _AvailabilityPageDetailState createState() => _AvailabilityPageDetailState();
}

class _AvailabilityPageDetailState extends State<AvailabilityPageDetail> {
  // This list will store the user's availability
  // It starts with all elements set to 0 (not available)
  var availability = Availability.notSet();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('Set Availability'),
        ),
        body: ListView.builder(
          itemCount: Availability.ArrayLength,
          itemBuilder: (context, index) {
            return Row(
              children: [
                SizedBox(
                  width: 150,
                  child: Text(Availability.get_timeslot_name(index, context)),
                ),
                Flexible(
                  child: RadioListTile(
                      title: Text(Availability.ValueDefinitions[-1]!),
                      value: -1,
                      groupValue: availability.weekAvailability[index],
                      onChanged: (value) {
                        setState(() {
                          availability.weekAvailability[index] = value ?? 0;
                        });
                      }),
                ),
                Flexible(
                  child: RadioListTile(
                      title: Text(Availability.ValueDefinitions[0]!),
                      value: 0,
                      groupValue: availability.weekAvailability[index],
                      onChanged: (value) {
                        setState(() {
                          availability.weekAvailability[index] = value ?? 0;
                        });
                      }),
                ),
                Flexible(
                  child: RadioListTile(
                      title: Text(Availability.ValueDefinitions[1]!),
                      value: 1,
                      groupValue: availability.weekAvailability[index],
                      onChanged: (value) {
                        setState(() {
                          availability.weekAvailability[index] = value ?? 0;
                        });
                      }),
                ),
                Flexible(
                  child: RadioListTile(
                      title: Text(Availability.ValueDefinitions[2]!),
                      value: 2,
                      groupValue: availability.weekAvailability[index],
                      onChanged: (value) {
                        setState(() {
                          availability.weekAvailability[index] = value ?? 0;
                        });
                      }),
                ),
                Flexible(
                  child: RadioListTile(
                      title: Text(Availability.ValueDefinitions[3]!),
                      value: 3,
                      groupValue: availability.weekAvailability[index],
                      onChanged: (value) {
                        setState(() {
                          availability.weekAvailability[index] = value ?? 0;
                        });
                      }),
                ),
              ],
            );
          },
        ),
        floatingActionButton: ElevatedButton(
            child: Text('Submit'),
            onPressed: () async {
              final User? user = FirebaseAuth.instance.currentUser;
              if (user != null) {
                await FirebaseFirestore.instance
                    .collection(Group.collectionName)
                    .doc(widget.groupDocumentId)
                    .update({
                  'availability.${user.uid}': availability.weekAvailability
                });
              }

              if (context.mounted) {
                context.pop();
                context.pop();
              }
            }));
  }
}

class AvailabilityDialog extends StatelessWidget {
  final Function(int) onSelected;

  AvailabilityDialog({required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return SimpleDialog(
      title: Text('Select Availability'),
      children: <Widget>[
        SimpleDialogOption(
          child: Text('Not Available'),
          onPressed: () {
            onSelected(0);
            Navigator.of(context).pop();
          },
        ),
        SimpleDialogOption(
          child: Text('Sometimes Available'),
          onPressed: () {
            onSelected(1);
            Navigator.of(context).pop();
          },
        ),
        SimpleDialogOption(
          child: Text('Usually Available'),
          onPressed: () {
            onSelected(2);
            Navigator.of(context).pop();
          },
        ),
        SimpleDialogOption(
          child: Text('Preferred Time'),
          onPressed: () {
            onSelected(3);
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }
}
