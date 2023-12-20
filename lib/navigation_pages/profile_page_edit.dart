import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../firebase.dart';

class ProfilePageEdit extends StatefulWidget {
  final String userDocumentId;
  const ProfilePageEdit({Key? key, required this.userDocumentId})
      : super(key: key);
  @override
  _ProfilePageEditState createState() => _ProfilePageEditState();
}

class _ProfilePageEditState extends State<ProfilePageEdit> {
  TextEditingController _nameController = TextEditingController();
  TextEditingController _emailController = TextEditingController();
  TextEditingController _phoneNumberController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Fetch data from Firestore and populate the text fields
    fetchData();
  }

  void fetchData() async {
    // Fetch data from Firestore and populate the text fields
    DocumentSnapshot snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userDocumentId)
        .get();

    if (snapshot.exists) {
      setState(() {
        var data = snapshot.data()! as Map;
        _nameController.text = data[UserFields.display_name.name];
        _emailController.text = data[UserFields.email.name];
        _phoneNumberController.text = data[UserFields.phone_number.name];
      });
    }
  }

  void saveData() async {
    // Save the updated data to Firestore
    await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userDocumentId)
        .update({
      UserFields.display_name.name: _nameController.text,
      UserFields.email.name: _emailController.text,
      UserFields.phone_number.name: _phoneNumberController.text,
    });

    // Show a snackbar to indicate that the data has been saved
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Data saved')),
    );
  }

  void cancelButtonPressed() {
    // Navigate back to the previous screen
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Profile'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextFormField(
              controller: _nameController,
              decoration:
                  InputDecoration(labelText: UserFields.display_name.label),
            ),
            TextFormField(
              controller: _emailController,
              decoration: InputDecoration(labelText: UserFields.email.label),
            ),
            TextFormField(
              controller: _phoneNumberController,
              decoration:
                  InputDecoration(labelText: UserFields.phone_number.label),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ElevatedButton(
                onPressed: cancelButtonPressed,
                child: Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  saveData();
                  Navigator.pop(context);
                },
                child: Text('Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
