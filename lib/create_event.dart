import 'package:flutter/material.dart';
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
  DateTime start = DateTime.now();

  @override
  void initState() {
    super.initState();
    DateTime start = widget.timeSlot == null
        ? DateTime.now()
        : getNextDateTimeFromTimeSlot(DateTime.now(), widget.timeSlot!);
    _startDateController.text = DateFormat.yMd().format(start);
    _startTimeController.text = DateFormat.jm().format(start);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('New ${widget.group.name} Event'),
        ),
        //left off here
        //TODO: implement the create event page UI with defaulting the passed in time slot
        body: ListView(children: [
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
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
                controller: _startDateController,
                decoration: InputDecoration(
                  labelText: 'Date',
                  filled: true,
                  enabledBorder:
                      OutlineInputBorder(borderSide: BorderSide.none),
                  prefixIcon: Icon(Icons.calendar_today),
                ),
                readOnly: true,
                onTap: () {
                  _selectDate(context, start);
                }),
          ),
          Padding(
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
                  _selectTime(context, TimeOfDay.fromDateTime(start));
                }),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: InputDecoration(
                labelText: 'End Time',
              ),
            ),
          ),
          Padding(
              padding: const EdgeInsets.all(8.0),
              child: ElevatedButton(
                  child: const Text('Create Event'), onPressed: () {})),
        ]));
  }

  Future<void> _selectDate(BuildContext context, DateTime start) async {
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

  Future<void> _selectTime(BuildContext context, TimeOfDay start) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: start,
    );

    if (picked != null)
      setState(() {
        _startTimeController.text = picked.toString();
      });
  }
}
