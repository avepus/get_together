import 'package:flutter/material.dart';
import 'package:get_together/utils.dart';
import 'package:intl/date_symbol_data_file.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'classes/group.dart';
import 'classes/availability.dart';
import 'classes/event.dart';
import 'time_utils.dart';
import 'findTime.dart';
import 'app_state.dart';
import 'classes/app_notification.dart';
import 'classes/app_user.dart';

///this page is used to create a new event or update an existing event
///a group is required
///an event or a timeslot must be passed in
///if an event is passed in, the save event button on this page will update the event
///if a timeslot is passed in and no event is passed in, the save event button on this page will create a new event
class UpdateEventPage extends StatefulWidget {
  final Group group;
  final Event? event;
  final int? timeSlot;
  UpdateEventPage({super.key, required this.group, this.event, this.timeSlot});

  @override
  _UpdateEventPageState createState() => _UpdateEventPageState();
}

class _UpdateEventPageState extends State<UpdateEventPage> {
  final int numberOfSlotsToReturn = 5; //this should probably be configurable
  final _eventTitleController = TextEditingController();
  final _eventDescriptionController = TextEditingController();
  final _eventLocationController = TextEditingController();
  final _startTimeController = TextEditingController();
  final _startDateController = TextEditingController();
  final _endTimeController = TextEditingController();
  final _endDateController = TextEditingController();
  late DateTime start;
  late int duration;
  late DateTime end;
  Map<String, Availability> memberAvailabilities = {};
  late Map<int, int> timeSlotsAndScores;
  late List<int> timeSlots;
  late ApplicationState appState;

  ///left off here. Need to call this function in widget build to display attendance responses and need to call in saveToFirestore to replace repeated code in saveEventToFirestore
  Map<String, AttendanceResponse> _getAttendanceResponses() {
    Map<String, AttendanceResponse> attendanceResponses = {};
    for (String member in widget.group.members) {
      Availability? availability = memberAvailabilities[member];
      if (availability == null) {
        attendanceResponses[member] = AttendanceResponse.unconfirmedMaybe;
      } else {
        attendanceResponses[member] = availability.getAttendanceResponseForEvent(start.toUtc(), end.toUtc(), 'UTC');
      }
    }
    return attendanceResponses;
  }

  ///This widget accpets a group and either an event or a timeSlot. If an event is passed in, we just use it's values. If it's not, we set the start and based on the timeslot
  void _setValuesFromEventAndTimeSlot(Event? event, int? timeSlot) {
    if (event != null) {
      _eventTitleController.text = event.title;
      _eventDescriptionController.text = event.description;
      _eventLocationController.text = event.location;
      start = event.startTime;
      end = event.endTime;
    } else if (timeSlot != null) {
      start = getNextDateTimeFromTimeSlot(DateTime.now(), timeSlot);
      end = start.add(Duration(minutes: widget.group.meetingDurationMinutes));
    } else {
      start = DateTime.now();
      end = start.add(Duration(minutes: widget.group.meetingDurationMinutes));
    }
  }

  @override
  void initState() {
    super.initState();
    _setValuesFromEventAndTimeSlot(widget.event, widget.timeSlot);
    _startDateController.text = DateFormat.yMMMMEEEEd().format(start);
    _startTimeController.text = DateFormat.jm().format(start);
    _endDateController.text = DateFormat.yMMMMEEEEd().format(end);
    _endTimeController.text = DateFormat.jm().format(end);

    for (String member in widget.group.members) {
      Availability? availability = widget.group.getAvailability(member);
      if (availability != null) {
        memberAvailabilities[member] = availability;
      }
    }

    appState = Provider.of<ApplicationState>(context, listen: false);

    assert(appState.loginUserTimeZone != null, 'loginUserTimeZone should be populated when the app is initialized but it is null');
    timeSlotsAndScores = findTimeSlotsFiltered(memberAvailabilities, widget.group.meetingDurationTimeSlots, numberOfSlotsToReturn, appState.loginUserTimeZone!);

    timeSlots = timeSlotsAndScores.keys.toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('New ${widget.group.name} Event'),
        ),
        floatingActionButton: ElevatedButton(onPressed: saveEventToFirestore, child: const Text('Save Event')),
        body: ListView(children: [
          //TODO: Create default for event title
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _eventTitleController,
              decoration: InputDecoration(
                labelText: '${widget.group.name} Event Title',
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _eventDescriptionController,
              decoration: InputDecoration(
                labelText: 'Event Description',
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _eventLocationController,
              decoration: InputDecoration(
                labelText: 'Event Location',
              ),
            ),
          ),
          Row(
            children: [
              SizedBox(
                width: 300,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                      controller: _startDateController,
                      decoration: const InputDecoration(
                        labelText: 'Start Date',
                        filled: true,
                        enabledBorder: OutlineInputBorder(borderSide: BorderSide.none),
                        prefixIcon: Icon(Icons.calendar_today),
                      ),
                      readOnly: true,
                      onTap: () {
                        _selectStartDate(context);
                      }),
                ),
              ),
              SizedBox(
                width: 150,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                      controller: _startTimeController,
                      decoration: const InputDecoration(
                        labelText: 'Start Time',
                        filled: true,
                        enabledBorder: OutlineInputBorder(borderSide: BorderSide.none),
                        prefixIcon: Icon(Icons.schedule),
                      ),
                      readOnly: true,
                      onTap: () {
                        _selectStartTime(context);
                      }),
                ),
              ),
            ],
          ),
          Row(
            children: [
              SizedBox(
                width: 300,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                      controller: _endDateController,
                      decoration: const InputDecoration(
                        labelText: 'End Date',
                        filled: true,
                        enabledBorder: OutlineInputBorder(borderSide: BorderSide.none),
                        prefixIcon: Icon(Icons.calendar_today),
                      ),
                      readOnly: true,
                      onTap: () {
                        _selectEndDate(context);
                      }),
                ),
              ),
              SizedBox(
                width: 150,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                      controller: _endTimeController,
                      decoration: const InputDecoration(
                        labelText: 'End Time',
                        filled: true,
                        enabledBorder: OutlineInputBorder(borderSide: BorderSide.none),
                        prefixIcon: Icon(Icons.schedule),
                      ),
                      readOnly: true,
                      onTap: () {
                        _selectEndTime(context);
                      }),
                ),
              ),
            ],
          ),
          Container(width: 400, height: 400, child: SuggestedTimesListView(timeSlots: timeSlots, timeSlotsAndScores: timeSlotsAndScores, group: widget.group, linkToEvent: false))
        ]));
  }

  //TODO: this needs to be broken up and have unit tests but that's for future Avery
  void saveEventToFirestore() async {
    assert(appState.loginUserDocumentId != null, 'loginUserDocumentId should be populated when the app is initialized but it is null');

    //TODO: differentiate between inferred response based on availability and manual responses
    //TODO: this will overwrite any manual responses. May want to avoid doing that under some circumstances like a title or description update.
    Map<String, AttendanceResponse> attendanceResponses = widget.event?.attendanceResponses ?? {};
    for (String member in widget.group.members) {
      Availability? availability = memberAvailabilities[member];
      //it might make more sense here to have the timezone be based on your availability or some other user setting but we're just basing it off your local timezone
      if (availability == null) {
        attendanceResponses[member] = AttendanceResponse.unconfirmedMaybe;
      } else {
        attendanceResponses[member] = availability.getAttendanceResponseForEvent(start.toUtc(), end.toUtc(), 'UTC');
      }
    }

    Event event = Event(
      documentId: widget.event?.documentId, //this isn't great but for now we use null to indicate a new event
      title: _eventTitleController.text,
      description: _eventDescriptionController.text,
      location: _eventLocationController.text,
      startTime: start.toUtc(),
      endTime: end.toUtc(),
      groupDocumentId: widget.group.documentId,
      createdTime: widget.event?.createdTime ?? DateTime.now(),
      creatorDocumentId: appState.loginUserDocumentId!,
      attendanceResponses: attendanceResponses,
    );
    String notificationTitle = event.documentId == null ? 'New Event' : 'Event Updated';
    String description = event.documentId == null ? '${widget.group.name} has a new event "${event.title}" scheduled for ${myFormatDateAndTime(event.startTime)}' : 'An event has been updated';
    NotificationType type = event.documentId == null ? NotificationType.newEvent : NotificationType.updatedEvent;

    //saveToFirestore will update event and store the new document ID if it's a new event so we need our checks for a new event before this call
    await event.saveToFirestore();
    //after saving we can assume event.documentId is not null
    AppNotification notification = AppNotification(title: notificationTitle, description: description, type: type, createdTime: Timestamp.now(), routeToDocumentId: event.documentId!);
    for (String memberID in widget.group.members) {
      await notification.saveToDocument(documentId: memberID, fieldKey: AppUser.notificationsKey, collection: AppUser.collectionName);
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('event ${_eventTitleController.text} saved'),
      ),
    );
    if (context.mounted) {
      context.pushNamed('events');
    }
  }

  //TODO: make this move the end when the start time is changed
  Future<void> _selectStartDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: start,
      firstDate: DateTime.now(),
      lastDate: DateTime(2050),
    );

    if (picked == null) {
      return;
    }

    DateTime startMidnight = DateTime(start.year, start.month, start.day);
    Duration newStartDifference = picked.difference(startMidnight);

    start = start.add(newStartDifference);
    end = end.add(newStartDifference);

    setState(() {
      _startDateController.text = DateFormat.yMMMMEEEEd().format(start);
      _startTimeController.text = DateFormat.jm().format(start);
      _endDateController.text = DateFormat.yMMMMEEEEd().format(end);
      _endTimeController.text = DateFormat.jm().format(end);
    });
  }

  Future<void> _selectStartTime(BuildContext context) async {
    TimeOfDay initialTime = TimeOfDay.fromDateTime(start);
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );

    if (picked == null) {
      return;
    }

    Duration difference = Duration(minutes: ((picked.hour - start.hour) * 60) + (picked.minute - start.minute));

    start = start.add(difference);
    end = end.add(difference);

    setState(() {
      _startDateController.text = DateFormat.yMMMMEEEEd().format(start);
      _startTimeController.text = DateFormat.jm().format(start);
      _endDateController.text = DateFormat.yMMMMEEEEd().format(end);
      _endTimeController.text = DateFormat.jm().format(end);
    });
  }

  //having an issue with trying to move the end date to the next day
  Future<void> _selectEndDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: end,
      firstDate: start,
      lastDate: start.add(const Duration(days: 1)),
    );

    if (picked == null) {
      return;
    }

    //when selecting a date, the time is set to midnight. We want an even comparison so we compare it to our current end time at midnight
    DateTime endMidnight = DateTime(end.year, end.month, end.day);

    Duration newEndDifference = picked.difference(endMidnight);

    end = end.add(newEndDifference);

    if (end.isBefore(start)) {
      end = start.add(const Duration(minutes: Availability.timeSlotDuration));
    }

    setState(() {
      _endDateController.text = DateFormat.yMMMMEEEEd().format(end);
      _endTimeController.text = DateFormat.jm().format(end);
    });
  }

  Future<void> _selectEndTime(BuildContext context) async {
    TimeOfDay initialTime = TimeOfDay.fromDateTime(end);
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );

    if (picked == null) {
      return;
    }

    Duration difference = Duration(minutes: ((picked.hour - end.hour) * 60) + (picked.minute - end.minute));

    end = end.add(difference);

    if (end.isBefore(start)) {
      end = start.add(const Duration(minutes: Availability.timeSlotDuration));
    }

    setState(() {
      _endDateController.text = DateFormat.yMMMMEEEEd().format(end);
      _endTimeController.text = DateFormat.jm().format(end);
    });
  }
}

class GenerateEventButton extends StatelessWidget {
  final Group group;
  final int timeSlotDuration;
  final int numberOfSlotsToReturn;

  const GenerateEventButton({
    required this.group,
    required this.timeSlotDuration,
    required this.numberOfSlotsToReturn,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      child: const Text('Create Event'),
      onPressed: () {
        showAddEventDialog(context, group, timeSlotDuration, numberOfSlotsToReturn);
      },
    );
  }
}

void showAddEventDialog(BuildContext context, Group group, int timeSlotDuration, int numberOfSlotsToReturn) {
  ApplicationState appState = Provider.of<ApplicationState>(context, listen: false);
  Map<String, Availability> memberAvailabilities = group.getGroupMemberAvailabilities();
  //TODO: may want to pass in a future DateTime to findTimeSlots to have more accurrate availability calcuations based on the week that it will be planned rather than now
  assert(appState.loginUserTimeZone != null, 'loginUserTimeZone should be populated when the app is initialized but it is null');
  Map<int, int> timeSlotsAndScores = findTimeSlotsFiltered(memberAvailabilities, timeSlotDuration, numberOfSlotsToReturn, appState.loginUserTimeZone!);
  List<int> timeSlots = timeSlotsAndScores.keys.toList();
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Best Times'),
        content: SizedBox(
            height: 200,
            width: 300,
            child: SuggestedTimesListView(
              timeSlots: timeSlots,
              timeSlotsAndScores: timeSlotsAndScores,
              group: group,
              linkToEvent: true,
            )),
        actions: <Widget>[
          TextButton(
            child: const Text('Cancel'),
            onPressed: () {
              context.pop();
            },
          ),
        ],
      );
    },
  );
}

class SuggestedTimesListView extends StatelessWidget {
  const SuggestedTimesListView({
    super.key,
    required this.timeSlots,
    required this.timeSlotsAndScores,
    required this.group,
    required this.linkToEvent,
  });

  final List<int> timeSlots;
  final Map<int, int> timeSlotsAndScores;
  final Group group;
  final bool linkToEvent;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: timeSlots.length + 1, // Add one for the header row
      itemBuilder: (BuildContext context, int index) {
        if (index == 0) {
          // This is the header row
          return ListTile(
            title: Table(
              columnWidths: const {
                0: FractionColumnWidth(0.2),
                1: FractionColumnWidth(0.6),
                2: FractionColumnWidth(0.2),
              },
              children: const [
                TableRow(
                  children: [
                    Text('Rank'),
                    Text('Start Time'),
                    Text('Score'),
                  ],
                ),
              ],
            ),
          );
        } else {
          // This is a data row
          String timeSlotName = Availability.getTimeslotName(timeSlots[index - 1], context);
          return ListTile(
            title: Table(
              columnWidths: const {
                0: FractionColumnWidth(0.2),
                1: FractionColumnWidth(0.6),
                2: FractionColumnWidth(0.2),
              },
              children: [
                TableRow(
                  children: [
                    Text('$index'),
                    Text(timeSlotName),
                    Text('${timeSlotsAndScores[timeSlots[index - 1]]}'),
                  ],
                ),
              ],
            ),
            onTap: () {
              if (linkToEvent) {
                context.pop();
                context.pushNamed('updateEvent', extra: {'group': group, 'timeSlot': timeSlots[index - 1]});
              }
            },
          );
        }
      },
    );
  }
}
