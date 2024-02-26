import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';

import 'package:get_together/event.dart';
import 'package:get_together/availability.dart';

class GenerateEventButton extends StatelessWidget {
  final String groupDocumentId;
  final Map<String, Availability> availabilities;
  GenerateEventButton(
      {super.key, required this.groupDocumentId, required this.availabilities});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
        child: const Text('Set Availability'),
        onPressed: () {
          generateEvents(availabilities);
        });
  }
}

//this function tkaes a list of availability and generates a list of possible events during the times of the most availability
List<Event> generateEvents(Map<String, Availability> availabilities) {
  List<Event> events = [];
  //TOTO; do some calculations on availability to generate events
  return events;
}
