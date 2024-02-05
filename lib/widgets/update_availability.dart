import 'package:flutter/material.dart';

//This button will be used to add availability to the group for the logged in user
//the availability is an array of numbers 0, 1, 2, 3 where
//  0 = not available
//  1 = sometimes available
//  2 = usually available
//  3 = preferred time
//The array will be 336 elements long, one for each 30 minute increment in a week
//The array will be stored in the group document as a map where the key is the user's documentId
//when clicked, the user should first be prompted to choose which days of the week they are available
//Then the user will be prompted to choose which 30 minute increments they are available for the days they indicated they are available

class AvailabilityButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      child: Text('Set Availability'),
      onPressed: () {
        // Navigate to a new page or open a dialog here
        // This is where you'll ask the user for their availability
        // You'll need to create a new widget for this page/dialog
        Navigator.of(context).push(MaterialPageRoute(
          builder: (context) => AvailabilityPageDay(),
        ));
      },
    );
  }
}

class AvailabilityPageDay extends StatefulWidget {
  @override
  _AvailabilityPageDayState createState() => _AvailabilityPageDayState();
}

class _AvailabilityPageDayState extends State<AvailabilityPageDay> {
  // This list will store the user's availability
  // It starts with all elements set to 0 (not available)
  List<int?> availability = List<int?>.filled(336, null);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('Set Availability'),
        ),
        body: ListView.builder(
          itemCount: 7,
          itemBuilder: (context, index) {
            return ListTile(
              title: Text('30-minute slot $index'),
              onTap: () {
                // This is where you'll ask the user for their availability for this 30-minute slot
                // You'll need to create a new widget for this dialog
                showDialog(
                  context: context,
                  builder: (context) => AvailabilityDialog(
                    onSelected: (value) {
                      setState(() {
                        availability[index] = value;
                      });
                    },
                  ),
                );
              },
            );
          },
        ),
        bottomNavigationBar: BottomAppBar(
          child: ElevatedButton(
            child: Text('Submit'),
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (context) =>
                    AvailabilityPageDetail(availability: availability),
              ));
            },
          ),
        ));
  }
}

class AvailabilityPageDetail extends StatefulWidget {
  List<int?> availability;
  AvailabilityPageDetail({super.key, required this.availability});
  @override
  _AvailabilityPageDetailState createState() => _AvailabilityPageDetailState();
}

class _AvailabilityPageDetailState extends State<AvailabilityPageDetail> {
  // This list will store the user's availability
  // It starts with all elements set to 0 (not available)

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Set Availability'),
      ),
      body: ListView.builder(
        itemCount: 336,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text('30-minute slot $index'),
            onTap: () {
              // This is where you'll ask the user for their availability for this 30-minute slot
              // You'll need to create a new widget for this dialog
              showDialog(
                context: context,
                builder: (context) => AvailabilityDialog(
                  onSelected: (value) {
                    setState(() {
                      widget.availability[index] = value;
                    });
                  },
                ),
              );
            },
          );
        },
      ),
    );
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
