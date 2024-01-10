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
  final Type dataType;
  bool isEditing = false;

  EditableFirestoreField({
    required this.collection,
    required this.fieldKey,
    required this.label,
    required this.documentId,
    required this.currentValue,
    required this.hasSecurity,
    required this.dataType,
  });

  @override
  _EditableFirestoreFieldState createState() => _EditableFirestoreFieldState();
}

class _EditableFirestoreFieldState extends State<EditableFirestoreField> {
  final List<TextInputFormatter> formatters = <TextInputFormatter>[];
  late TextEditingController textController;

  @override
  void initState() {
    super.initState();
    if (widget.dataType == int) {
      formatters.add(FilteringTextInputFormatter.digitsOnly);
    }
    if (widget.dataType == double) {
      formatters.add(FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')));
    }
    textController = TextEditingController(
        text:
            widget.currentValue != null ? widget.currentValue.toString() : '');
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        Card(
          child: ListTile(
            title: Text(widget.label),
            subtitle: widget.isEditing
                ? TextField(
                    controller: textController, inputFormatters: formatters)
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
                          dynamic convertedValue;
                          if (widget.dataType == int) {
                            convertedValue =
                                int.tryParse(textController.text) ??
                                    widget.currentValue;
                          } else if (widget.dataType == double) {
                            convertedValue =
                                double.tryParse(textController.text) ??
                                    widget.currentValue;
                          } else {
                            convertedValue = textController.text;
                          }
                          FirebaseFirestore.instance
                              .collection(widget.collection)
                              .doc(widget.documentId)
                              .update({widget.fieldKey: convertedValue});
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
