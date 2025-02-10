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
import '/widgets/image_with_null_error_handling.dart';

///this page is used to create a new event or update an existing event
///a group is required
///an event or a timeslot must be passed in
///if an event is passed in, the save event button on this page will update the event
///if a timeslot is passed in and no event is passed in, the save event button on this page will create a new event
class UpdateEventPage extends StatefulWidget {
  final Group group;
  final Event event;
  UpdateEventPage({super.key, required this.group, required this.event});

  @override
  _UpdateEventPageState createState() => _UpdateEventPageState();
}

class _UpdateEventPageState extends State<UpdateEventPage> {
  late Event _event;
  final int numberOfSlotsToReturn = 5; //this should probably be configurable
  final _eventTitleController = TextEditingController();
  final _eventDescriptionController = TextEditingController();
  final _eventLocationController = TextEditingController();
  final _startTimeController = TextEditingController();
  final _startDateController = TextEditingController();
  final _endTimeController = TextEditingController();
  final _endDateController = TextEditingController();
  late final Future<List<AppUser>> _users;
  late int duration;
  Map<String, Availability> memberAvailabilities = {};
  late Map<int, int> timeSlotsAndScores;
  late List<int> timeSlots;
  late ApplicationState appState;

  @override
  void initState() {
    _users = widget.group.fetchMemberUsers();

    super.initState();
    //create a non-final copy of the event passed in so it can be modified
    _event = Event(
      documentId: widget.event.documentId,
      title: widget.event.title,
      description: widget.event.description,
      location: widget.event.location,
      startTime: widget.event.startTime,
      endTime: widget.event.endTime,
      groupDocumentId: widget.event.groupDocumentId,
      isCancelled: widget.event.isCancelled,
      createdTime: widget.event.createdTime,
      creatorDocumentId: widget.event.creatorDocumentId,
      attendanceResponses: Map<String, AttendanceResponse>.from(widget.event.attendanceResponses),
    );

    _eventTitleController.text = _event.title;
    _eventDescriptionController.text = _event.description;
    _eventLocationController.text = _event.location;
    _startDateController.text = DateFormat.yMMMMEEEEd().format(_event.startTime);
    _startTimeController.text = DateFormat.jm().format(_event.startTime);
    _endDateController.text = DateFormat.yMMMMEEEEd().format(_event.endTime);
    _endTimeController.text = DateFormat.jm().format(_event.endTime);

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
          Container(
              width: 400,
              height: 400,
              child: SuggestedTimesListView(timeSlots: timeSlots, timeSlotsAndScores: timeSlotsAndScores, group: widget.group, userDocumentId: appState.loginUserDocumentId!, linkToEvent: false)),
          Container(
              width: 400,
              height: 400,
              child: FutureBuilder<List<AppUser>>(
                  future: _users,
                  builder: (context, users) {
                    if (users.connectionState == ConnectionState.waiting) {
                      return CircularProgressIndicator();
                    } else if (users.hasError) {
                      return Text('Error: ${users.error}');
                    } else if (users.data == null) {
                      return const Text('No users found');
                    } else {
                      List<AppUser> usersList = users.data!;
                      return ListView.builder(
                          itemCount: usersList.length,
                          itemBuilder: (context, index) {
                            AppUser user = usersList[index];
                            return ListTile(
                              leading: ImageWithNullAndErrorHandling(imageUrl: user.imageUrl),
                              title: Text(user.displayName ?? '<No Name>'),
                              subtitle: Text(_event.attendanceResponses[user.documentId]?.displayText ?? AttendanceResponse.unconfirmedMaybe.displayText),
                            );
                          });
                    }
                  })),
        ]));
  }

  //TODO: this needs to be broken up and have unit tests but that's for future Avery
  void saveEventToFirestore() async {
    assert(appState.loginUserDocumentId != null, 'loginUserDocumentId should be populated when the app is initialized but it is null');

    //TODO: this will overwrite any manual responses. May want to avoid doing that under some circumstances like a title or description update.
    _event.attendanceResponses = getAttendanceResponses(widget.group, _event.startTime, _event.endTime);
    _event.title = _eventTitleController.text;
    _event.description = _eventDescriptionController.text;
    _event.location = _eventLocationController.text;

    String notificationTitle = _event.documentId == null ? 'New Event' : 'Event Updated';
    String description = _event.documentId == null ? '${widget.group.name} has a new event "${_event.title}" scheduled for ${myFormatDateAndTime(_event.startTime)}' : 'An event has been updated';
    NotificationType type = _event.documentId == null ? NotificationType.newEvent : NotificationType.updatedEvent;

    //saveToFirestore will update event and store the new document ID if it's a new event so we need our checks for a new event before this call
    await _event.saveToFirestore();
    //after saving we can assume event.documentId is not null
    AppNotification notification = AppNotification(title: notificationTitle, description: description, type: type, createdTime: Timestamp.now(), routeToDocumentId: _event.documentId!);
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
      initialDate: _event.startTime,
      firstDate: DateTime.now(),
      lastDate: DateTime(2050),
    );

    if (picked == null) {
      return;
    }

    DateTime startMidnight = DateTime(_event.startTime.year, _event.startTime.month, _event.startTime.day);
    Duration newStartDifference = picked.difference(startMidnight);

    _event.startTime = _event.startTime.add(newStartDifference);
    _event.endTime = _event.endTime.add(newStartDifference);

    setState(() {
      _startDateController.text = DateFormat.yMMMMEEEEd().format(_event.startTime);
      _startTimeController.text = DateFormat.jm().format(_event.startTime);
      _endDateController.text = DateFormat.yMMMMEEEEd().format(_event.endTime);
      _endTimeController.text = DateFormat.jm().format(_event.endTime);
    });
  }

  Future<void> _selectStartTime(BuildContext context) async {
    TimeOfDay initialTime = TimeOfDay.fromDateTime(_event.startTime);
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );

    if (picked == null) {
      return;
    }

    Duration difference = Duration(minutes: ((picked.hour - _event.startTime.hour) * 60) + (picked.minute - _event.startTime.minute));

    _event.startTime = _event.startTime.add(difference);
    _event.endTime = _event.endTime.add(difference);

    setState(() {
      _startDateController.text = DateFormat.yMMMMEEEEd().format(_event.startTime);
      _startTimeController.text = DateFormat.jm().format(_event.startTime);
      _endDateController.text = DateFormat.yMMMMEEEEd().format(_event.endTime);
      _endTimeController.text = DateFormat.jm().format(_event.endTime);
    });
  }

  //having an issue with trying to move the end date to the next day
  Future<void> _selectEndDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _event.endTime,
      firstDate: _event.startTime,
      lastDate: _event.startTime.add(const Duration(days: 1)),
    );

    if (picked == null) {
      return;
    }

    //when selecting a date, the time is set to midnight. We want an even comparison so we compare it to our current end time at midnight
    DateTime endMidnight = DateTime(_event.endTime.year, _event.endTime.month, _event.endTime.day);

    Duration newEndDifference = picked.difference(endMidnight);

    _event.endTime = _event.endTime.add(newEndDifference);

    if (_event.endTime.isBefore(_event.startTime)) {
      _event.endTime = _event.startTime.add(const Duration(minutes: Availability.timeSlotDuration));
    }

    setState(() {
      _endDateController.text = DateFormat.yMMMMEEEEd().format(_event.endTime);
      _endTimeController.text = DateFormat.jm().format(_event.endTime);
    });
  }

  Future<void> _selectEndTime(BuildContext context) async {
    TimeOfDay initialTime = TimeOfDay.fromDateTime(_event.endTime);
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );

    if (picked == null) {
      return;
    }

    Duration difference = Duration(minutes: ((picked.hour - _event.endTime.hour) * 60) + (picked.minute - _event.endTime.minute));

    _event.endTime = _event.endTime.add(difference);

    if (_event.endTime.isBefore(_event.startTime)) {
      _event.endTime = _event.startTime.add(const Duration(minutes: Availability.timeSlotDuration));
    }

    setState(() {
      _endDateController.text = DateFormat.yMMMMEEEEd().format(_event.endTime);
      _endTimeController.text = DateFormat.jm().format(_event.endTime);
    });
  }
}

class GenerateEventButton extends StatelessWidget {
  final Group group;
  final String userDocumentId;
  final int timeSlotDuration;
  final int numberOfSlotsToReturn;

  const GenerateEventButton({
    required this.group,
    required this.userDocumentId,
    required this.timeSlotDuration,
    required this.numberOfSlotsToReturn,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      child: const Text('Create Event'),
      onPressed: () {
        showAddEventDialog(context, group, userDocumentId, timeSlotDuration, numberOfSlotsToReturn);
      },
    );
  }
}

void showAddEventDialog(BuildContext context, Group group, String userDocumentId, int timeSlotDuration, int numberOfSlotsToReturn) {
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
              userDocumentId: userDocumentId,
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
    required this.userDocumentId,
    required this.linkToEvent,
  });

  final List<int> timeSlots;
  final Map<int, int> timeSlotsAndScores;
  final Group group;
  final String userDocumentId;
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
                int utcTimeSlot = getUtcShiftedTimeSlot(timeSlots[index - 1]);
                DateTime start = getNextDateTimeFromTimeSlot(DateTime.now().toUtc(), utcTimeSlot).toLocal();
                DateTime end = start.add(Duration(minutes: group.meetingDurationMinutes));
                Event event = Event(
                  documentId: null, //this is always used to create a new event so we want the documentId to be null
                  title: '',
                  description: '',
                  location: '',
                  startTime: start,
                  endTime: end,
                  groupDocumentId: group.documentId,
                  createdTime: DateTime.now(), //Future: this is not technmically created yet. We'd want this to be when they save the event
                  creatorDocumentId: userDocumentId,
                  attendanceResponses: {},
                );
                context.pushNamed('updateEvent', extra: {'group': group, 'event': event});
              }
            },
          );
        }
      },
    );
  }
}

Map<String, AttendanceResponse> getAttendanceResponses(Group group, DateTime start, DateTime end) {
  Map<String, AttendanceResponse> attendanceResponses = {};
  for (String member in group.members) {
    Availability? availability = group.getAvailability(member);
    if (availability == null) {
      attendanceResponses[member] = AttendanceResponse.unconfirmedMaybe;
    } else {
      attendanceResponses[member] = availability.getAttendanceResponseForEvent(start.toUtc(), end.toUtc(), 'UTC');
    }
  }
  return attendanceResponses;
}
