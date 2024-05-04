import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:syncfusion_flutter_datepicker/datepicker.dart';
import 'package:intl/intl.dart';
import 'classes/group.dart';
import 'classes/availability.dart';
import 'classes/event.dart';
import 'time_utils.dart';

class CreateEventPage extends StatefulWidget {
  final Group group;
  final int? timeSlot;
  const CreateEventPage({super.key, required this.group, this.timeSlot});

  @override
  _CreateEventPageState createState() => _CreateEventPageState();
}

class _CreateEventPageState extends State<CreateEventPage> {
  final _startTimeController = TextEditingController();
  final _startDateController = TextEditingController();
  final _endTimeController = TextEditingController();
  final _endDateController = TextEditingController();
  DateTime start = DateTime.now();
  late int duration;
  late DateTime end;

  @override
  void initState() {
    super.initState();
    DateTime start = widget.timeSlot == null
        ? DateTime.now()
        : getNextDateTimeFromTimeSlot(DateTime.now(), widget.timeSlot!);
    duration = widget.group.meetingDuration == null
        ? 2
        : widget.group.meetingDuration!.toInt();
    end = start.add(Duration(hours: duration));
    _startDateController.text = DateFormat.yMMMMEEEEd().format(start);
    _startTimeController.text = DateFormat.jm().format(start);
    _endDateController.text = DateFormat.yMMMMEEEEd().format(end);
    _endTimeController.text = DateFormat.jm().format(end);
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
                      decoration: InputDecoration(
                        labelText: 'Start Date',
                        filled: true,
                        enabledBorder:
                            OutlineInputBorder(borderSide: BorderSide.none),
                        prefixIcon: Icon(Icons.calendar_today),
                      ),
                      readOnly: true,
                      onTap: () {
                        _selectStartDate(context, start);
                      }),
                ),
              ),
              SizedBox(
                width: 150,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                      controller: _startTimeController,
                      decoration: InputDecoration(
                        labelText: 'Start Time',
                        filled: true,
                        enabledBorder:
                            OutlineInputBorder(borderSide: BorderSide.none),
                        prefixIcon: Icon(Icons.schedule),
                      ),
                      readOnly: true,
                      onTap: () {
                        _selectStartTime(
                            context, TimeOfDay.fromDateTime(start));
                      }),
                ),
              ),
            ],
          ),

          //TODO: set up end time to default to group meeting duration + start time
          //TODO: set up end time to not allow before start time
          //TODO: set up end time to move when a new start is selected
          //TODO: set up an end date field for events that span midnight
          Row(
            children: [
              SizedBox(
                width: 300,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                      controller: _endDateController,
                      decoration: InputDecoration(
                        labelText: 'End Date',
                        filled: true,
                        enabledBorder:
                            OutlineInputBorder(borderSide: BorderSide.none),
                        prefixIcon: Icon(Icons.calendar_today),
                      ),
                      readOnly: true,
                      onTap: () {
                        _selectEndDate(context, end);
                      }),
                ),
              ),
              SizedBox(
                width: 150,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                      controller: _endTimeController,
                      decoration: InputDecoration(
                        labelText: 'End Time',
                        filled: true,
                        enabledBorder:
                            OutlineInputBorder(borderSide: BorderSide.none),
                        prefixIcon: Icon(Icons.schedule),
                      ),
                      readOnly: true,
                      onTap: () {
                        _selectEndTime(context, TimeOfDay.fromDateTime(end));
                      }),
                ),
              ),
            ],
          ),
          Padding(
              padding: const EdgeInsets.all(8.0),
              child: ElevatedButton(
                  child: const Text('Create Event'), onPressed: () {})),
        ]));
  }

  Future<void> _selectStartDate(BuildContext context, DateTime start) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: start,
      firstDate: DateTime.now(),
      lastDate: DateTime(2050),
    );
    if (picked != null)
      setState(() {
        _startDateController.text = picked.toString().split(" ")[0];
      });
  }

  Future<void> _selectStartTime(BuildContext context, TimeOfDay start) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: start,
    );

    if (picked != null)
      setState(() {
        _startTimeController.text = picked.toString();
      });
  }

  Future<void> _selectEndDate(BuildContext context, DateTime end) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: end,
      firstDate: DateTime.now(),
      lastDate: DateTime(2050),
    );
    if (picked != null)
      setState(() {
        _endDateController.text = picked.toString().split(" ")[0];
      });
  }

  Future<void> _selectEndTime(BuildContext context, TimeOfDay end) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: end,
    );

    if (picked != null)
      setState(() {
        _endTimeController.text = picked.toString();
      });
  }
}
