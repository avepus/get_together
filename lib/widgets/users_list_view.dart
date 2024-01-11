import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'dart:math';

import '../app_user.dart';
import 'image_with_null_error_handling.dart';

class UsersListView extends StatelessWidget {
  final Future<List<AppUser>> futureMembers;
  static const double _oneTileHeight = 50.0;
  //setting _maxHeight to a partial multiplyer gives a visual queue to the user that there's more to scroll
  static const double _maxHeight = _oneTileHeight * 4.6;

  const UsersListView({
    super.key,
    required this.futureMembers,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<AppUser>>(
        future: futureMembers,
        builder: (context, inFutureMembers) {
          if (inFutureMembers.connectionState == ConnectionState.waiting) {
            return const SizedBox(
                width: 50, child: CircularProgressIndicator());
          } else if (inFutureMembers.hasError) {
            return Text("Error: ${inFutureMembers.error}");
          } else {
            if (!inFutureMembers.hasData || inFutureMembers.data == null) {
              return const Text('No data');
            }
            List<AppUser> members = inFutureMembers.data!;
            return SizedBox(
              height: min(_maxHeight, _oneTileHeight * members.length),
              child: ListView.builder(
                itemCount: members.length,
                itemBuilder: (context, index) {
                  AppUser member = members[index];
                  return SizedBox(
                    height: _oneTileHeight,
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
