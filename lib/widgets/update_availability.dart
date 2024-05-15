import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_native_timezone/flutter_native_timezone.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:provider/provider.dart';

import 'package:get_together/classes/availability.dart';
import '../classes/group.dart';
import '../app_state.dart';

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

//TODO: this entire interface should be made not terrible
//perhaps a calendar view/grid view. Each tap on the grid would rotatthrough the availability options
class AvailabilityButton extends StatelessWidget {
  final String groupDocumentId;
  final Availability? availability;

  AvailabilityButton({super.key, required this.groupDocumentId, required this.availability});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      child: const Text('Set Availability'),
      onPressed: () {
        Navigator.of(context).push(MaterialPageRoute(
          builder: (context) => AvailabilityPageDetail(groupDocumentId: groupDocumentId, availability: availability),
        ));
      },
    );
  }
}

class AvailabilityPageDetail extends StatefulWidget {
  final String groupDocumentId;
  final Availability? availability;

  AvailabilityPageDetail({super.key, required this.groupDocumentId, required this.availability});
  @override
  _AvailabilityPageDetailState createState() => _AvailabilityPageDetailState();
}

class _AvailabilityPageDetailState extends State<AvailabilityPageDetail> {
  late Future<Availability> _availability;
  final double radioWidth = 100;
  final double timeSlotWidth = 150;

  @override
  void initState() {
    super.initState();
  }

  Future<Availability> _getAvailability(String timeZone) async {
    if (widget.availability != null) {
      return widget.availability!;
    }

    return Availability(weekAvailability: Availability.emptyWeekArray(), timeZoneName: timeZone);
  }

  @override
  Widget build(BuildContext context) {
    var appState = Provider.of<ApplicationState>(context);

    return FutureBuilder(
        future: _getAvailability(appState.loginUserTimeZone),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const CircularProgressIndicator();
          }
          Availability availability = snapshot.data as Availability;
          return Scaffold(
              appBar: AppBar(
                title:
                    //TODO: Low priority, this should editable
                    Text('Set Availability - (${availability.timeZoneName})'),
              ),
              body: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: timeSlotWidth,
                        child: Text('Time Slot'),
                      ),
                      SizedBox(
                        width: radioWidth,
                        child: ListTile(
                          title: Text(Availability.ValueDefinitions[Availability.badValue]!),
                        ),
                      ),
                      SizedBox(
                        width: radioWidth,
                        child: ListTile(
                          title: Text(Availability.ValueDefinitions[Availability.goodValue]!),
                        ),
                      ),
                      SizedBox(
                        width: radioWidth,
                        child: ListTile(
                          title: Text(Availability.ValueDefinitions[Availability.greatValue]!),
                        ),
                      ),
                    ],
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: Availability.ArrayLength,
                      itemBuilder: (context, index) {
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(width: timeSlotWidth, child: Text(Availability.getTimeslotName(index, context))),
                            SizedBox(
                              width: radioWidth,
                              child: RadioListTile(
                                  toggleable: true,
                                  value: Availability.badValue,
                                  groupValue: availability.weekAvailability[index],
                                  onChanged: (value) {
                                    setState(() {
                                      availability.weekAvailability[index] = value ?? 0;
                                    });
                                  }),
                            ),
                            SizedBox(
                              width: radioWidth,
                              child: RadioListTile(
                                  toggleable: true,
                                  value: Availability.goodValue,
                                  groupValue: availability.weekAvailability[index],
                                  onChanged: (value) {
                                    setState(() {
                                      availability.weekAvailability[index] = value ?? 0;
                                    });
                                  }),
                            ),
                            SizedBox(
                              width: radioWidth,
                              child: RadioListTile(
                                  toggleable: true,
                                  value: Availability.greatValue,
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
                  ),
                ],
              ),
              floatingActionButton: ElevatedButton(
                  child: const Text('Submit'),
                  onPressed: () async {
                    final User? user = FirebaseAuth.instance.currentUser;
                    if (user != null) {
                      await FirebaseFirestore.instance.collection(Group.collectionName).doc(widget.groupDocumentId).update({
                        '${Group.availabilityKey}.${user.uid}': availability.weekAvailability,
                        '${Group.memberTimezonesKey}.${user.uid}': availability.timeZoneName,
                      });
                    }

                    if (context.mounted) {
                      context.pop();
                    }
                  }));
        });
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
