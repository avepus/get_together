import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'dart:math';

import '../AppUser.dart';
import 'ImageWithNullErrorHandling.dart';

class UsersListView extends StatelessWidget {
  final Future<List<AppUser>> futureMembers;

  const UsersListView({
    Key? key,
    required this.futureMembers,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<AppUser>>(
        future: futureMembers,
        builder: (context, inFutureMembers) {
          if (inFutureMembers.connectionState == ConnectionState.waiting) {
            return CircularProgressIndicator();
          } else if (inFutureMembers.hasError) {
            return Text("Error: ${inFutureMembers.error}");
          } else {
            if (!inFutureMembers.hasData || inFutureMembers.data == null) {
              return const Text('No data');
            }
            List<AppUser> members = inFutureMembers.data!;
            return SizedBox(
              height: min(200, 50.0 * members.length),
              child: ListView.builder(
                itemCount: members.length,
                itemBuilder: (context, index) {
                  AppUser member = members[index];
                  return Container(
                    height: 50,
                    child: Card(
                      child: ListTile(
                        leading: ImageWithNullAndErrorHandling(member.imageUrl),
                        title: Text(member.displayName ?? '<No Name>'),
                        onTap: () {
                          context.pushNamed('profile', pathParameters: {
                            'userDocumentId': member.documentId,
                          });
                        },
                      ),
                    ),
                  );
                },
              ),
            );
          }
        });
  }
}
