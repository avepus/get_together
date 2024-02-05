import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import 'image_with_null_error_handling.dart';

class EditableImageField extends StatefulWidget {
  final String collectionName;
  final String documentId;
  final String fieldKey;
  final String? imageUrl;
  final bool canEdit;

  EditableImageField({
    required this.collectionName,
    required this.documentId,
    required this.fieldKey,
    required this.imageUrl,
    required this.canEdit,
  });

  @override
  _EditableImageFieldState createState() => _EditableImageFieldState();
}

class _EditableImageFieldState extends State<EditableImageField> {
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
  }

  Future<void> uploadImage() async {
    final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery, maxWidth: 200, maxHeight: 200);

    if (pickedFile != null) {
      debugPrint(pickedFile.path);

      Reference ref = FirebaseStorage.instance
          .ref()
          .child('${widget.collectionName}/${widget.documentId}');

      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {'picked-file-path': pickedFile.path},
      );

      if (kIsWeb) {
        await ref.putData(await pickedFile.readAsBytes(), metadata);
      } else {
        await ref.putFile(File(pickedFile.path), metadata);
      }

      var downloadUrl = await ref.getDownloadURL();

      await FirebaseFirestore.instance
          .collection(widget.collectionName)
          .doc(widget.documentId)
          .update({widget.fieldKey: downloadUrl});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Flex(
      direction: Axis.horizontal,
      children: [
        Flexible(
            flex: 4,
            child: ImageWithNullAndErrorHandling(imageUrl: widget.imageUrl)),
        if (widget.canEdit)
          Flexible(
            flex: 1,
            child: IconButton(
              icon: const Icon(Icons.edit),
              onPressed: uploadImage,
            ),
          ),
      ],
    );
  }
}
