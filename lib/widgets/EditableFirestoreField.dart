import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';

/// A widget that represents a field in Firestore.
/// It is editable if hasSecurity is true
class EditableFirestoreField extends StatefulWidget {
  final String collection;
  final String fieldKey;
  final String label;
  final String documentId;
  final dynamic currentValue;
  final bool hasSecurity;
  final List<TextInputFormatter> formatters;
  final TextEditingController textController = TextEditingController();
  bool isEditing = false;

  EditableFirestoreField({
    required this.collection,
    required this.fieldKey,
    required this.label,
    required this.documentId,
    required this.currentValue,
    required this.hasSecurity,
    this.formatters = const <TextInputFormatter>[],
  });

  @override
  _EditableFirestoreFieldState createState() => _EditableFirestoreFieldState();
}

class _EditableFirestoreFieldState extends State<EditableFirestoreField> {
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        Card(
          child: ListTile(
            title: Text(widget.label),
            subtitle: widget.isEditing
                ? TextField(controller: widget.textController)
                : Text(widget.currentValue.toString()),
          ),
        ),
        Visibility(
          visible: widget.hasSecurity, // replace with your own logic
          child: Align(
            alignment: Alignment.topRight,
            child: widget.isEditing
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.check),
                        onPressed: () {
                          FirebaseFirestore.instance
                              .collection(widget.collection)
                              .doc(widget.documentId)
                              .update({
                            widget.fieldKey: widget.textController.text
                          });
                          setState(() {
                            widget.isEditing = false;
                          });
                        },
                      ),
                      IconButton(
                        icon: Icon(Icons.close),
                        onPressed: () {
                          setState(() {
                            widget.isEditing = false;
                          });
                        },
                      ),
                    ],
                  )
                : IconButton(
                    icon: Icon(Icons.edit),
                    onPressed: () {
                      setState(() {
                        widget.isEditing = true;
                      });
                    },
                  ),
          ),
        ),
      ],
    );
  }
}
