import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:syncfusion_flutter_datepicker/datepicker.dart';
import 'package:intl/intl.dart';
import 'classes/group.dart';
import 'classes/availability.dart';
import 'classes/event.dart';
import 'time_utils.dart';
import 'findTime.dart';

class CreateEventPage extends StatefulWidget {
  final Group group;
  final int? timeSlot;
  CreateEventPage({super.key, required this.group, this.timeSlot});

  @override
  _CreateEventPageState createState() => _CreateEventPageState();
}

class _CreateEventPageState extends State<CreateEventPage> {
  final int numberOfSlotsToReturn = 5; //this should probably be configurable
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
  late int timeSlotDuration = widget.group.meetingDuration == null
      ? Group.defaultMeetingDuration
      : widget.group.meetingDuration!.toInt();

  @override
  void initState() {
    super.initState();
    duration = widget.group.meetingDuration == null
        ? Group.defaultMeetingDuration
        : widget.group.meetingDuration!.toInt();
    start = widget.timeSlot == null
        ? DateTime.now()
        : getNextDateTimeFromTimeSlot(DateTime.now(), widget.timeSlot!);
    end = start.add(Duration(hours: duration));
    _startDateController.text = DateFormat.yMMMMEEEEd().format(start);
    _startTimeController.text = DateFormat.jm().format(start);
    _endDateController.text = DateFormat.yMMMMEEEEd().format(end);
    _endTimeController.text = DateFormat.jm().format(end);

    for (String member in widget.group.members) {
      memberAvailabilities[member] = widget.group.getAvailability(member);
    }

    timeSlotsAndScores = findTimeSlots(
        memberAvailabilities, timeSlotDuration, numberOfSlotsToReturn);

    timeSlots = timeSlotsAndScores.keys.toList();
    int test = 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('New ${widget.group.name} Event'),
        ),
        body: ListView(children: [
          //TODO: Create default for event title
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: InputDecoration(
                labelText: '${widget.group.name} Event Title',
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: InputDecoration(
                labelText: 'Event Description',
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
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
                        enabledBorder:
                            OutlineInputBorder(borderSide: BorderSide.none),
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
                        enabledBorder:
                            OutlineInputBorder(borderSide: BorderSide.none),
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

          //TODO: set up end time to not allow before start time
          //TODO: set up end time to move when a new start is selected
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
                        enabledBorder:
                            OutlineInputBorder(borderSide: BorderSide.none),
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
                        enabledBorder:
                            OutlineInputBorder(borderSide: BorderSide.none),
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
          Padding(
              padding: const EdgeInsets.all(8.0),
              child: ElevatedButton(
                  child: const Text('Create Event'), onPressed: () {})),
          SizedBox(
              height: 500,
              width: 200, //why isn't this width being respected?
              child: ListView.builder(
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
                    String timeSlotName = Availability.getTimeslotName(
                        timeSlots[index - 1], context);
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
                              Text(
                                  '${timeSlotsAndScores[timeSlots[index - 1]]}'),
                            ],
                          ),
                        ],
                      ),
                    );
                  }
                },
              )),
        ]));
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

    Duration newStartDifference = picked.difference(start);

    start = start.add(Duration(days: newStartDifference.inDays));
    end = end.add(Duration(days: newStartDifference.inDays));

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

    Duration difference = Duration(
        minutes:
            ((picked.hour - start.hour) * 60) + (picked.minute - start.minute));

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

    Duration newEndDifference = picked.difference(end);

    end = end.add(Duration(days: newEndDifference.inDays));

    if (end.isBefore(start)) {
      end = start.add(const Duration(minutes: 30));
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

    Duration difference = Duration(
        minutes:
            ((picked.hour - end.hour) * 60) + (picked.minute - end.minute));

    end = end.add(difference);

    if (end.isBefore(start)) {
      end = start.add(const Duration(minutes: 30));
    }

    setState(() {
      _endDateController.text = DateFormat.yMMMMEEEEd().format(end);
      _endTimeController.text = DateFormat.jm().format(end);
    });
  }
}
