import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

class ProfilePage extends StatefulWidget {
  ProfilePage({super.key});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final String uid = FirebaseAuth.instance.currentUser!.uid;
  final _picker = ImagePicker();

  Stream<QuerySnapshot> getUserDetails() {
    return FirebaseFirestore.instance
        .collection('users')
        .where('uid', isEqualTo: uid)
        .snapshots();
  }

  Future<void> uploadImage() async {
    final XFile? pickedFile =
        await _picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      debugPrint(pickedFile.path);
      /*
      var file = File(pickedFile.path);
      
      var snapshot = await FirebaseStorage.instance
          .ref()
          .child('images/${widget.uid}')
          .putFile(pickedFile.path);

      var downloadUrl = await snapshot.ref.getDownloadURL();

      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.uid)
          .update({'image_url': downloadUrl});
      */
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: getUserDetails(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Text("Error: ${snapshot.error}");
          } else if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Text("No data found");
          } else {
            var userDocument = snapshot.data!.docs.first.data() as Map;
            return ListView(
              children: <Widget>[
                userDocument['image_url'] != null
                    ? Image.network(userDocument['image_url'])
                    : IconButton(
                        icon: Icon(Icons.add_a_photo),
                        onPressed: uploadImage,
                      ),
                ListTile(
                    title: Text('Display Name'),
                    subtitle: Text(userDocument['display_name'])),
                ListTile(
                    title: Text('Email'),
                    subtitle:
                        Text(userDocument['email'] ?? 'No email provided')),
                ListTile(
                    title: Text('Phone Number'),
                    subtitle: Text(userDocument['phone_number'] ??
                        'No phone number provided')),
                ListTile(
                    title: Text('Created Time'),
                    subtitle: Text(userDocument['created_time'].toString())),
              ],
            );
          }
        },
      ),
    );
  }
}
