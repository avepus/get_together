import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'navigation_pages/profile_page.dart';
import 'navigation_pages/groups_page.dart';
import 'navigation_pages/events_page.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({required this.initialPage, super.key});
  final Pages initialPage;

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

enum Pages { groups, events, profile }

class _MainNavigationState extends State<MainNavigation> {
  late int currentPageIndex;

  @override
  void initState() {
    super.initState();
    currentPageIndex = widget.initialPage.index;
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    if (FirebaseAuth.instance.currentUser == null) {
      return const Scaffold(
        body: Center(
          child: Text("Not signed in. Redirecting..."),
        ),
      );
    }
    return Scaffold(
      bottomNavigationBar: NavigationBar(
        onDestinationSelected: (int index) {
          setState(() {
            currentPageIndex = index;
          });
        },
        indicatorColor: theme.primaryColorLight,
        selectedIndex: currentPageIndex,
        destinations: const <Widget>[
          //groups page
          NavigationDestination(
            icon: Icon(Icons.diversity_3),
            label: 'Groups',
          ),
          //Events page
          NavigationDestination(
            icon: Badge(child: Icon(Icons.list_alt)),
            label: 'Events ',
          ),
          //Profile page
          NavigationDestination(
            icon: Badge(
              child: Icon(Icons.person),
            ),
            label: 'Profile',
          ),
        ],
      ),
      body: <Widget>[
        Padding(padding: const EdgeInsets.all(8.0), child: GroupsPage()),
        const Padding(padding: EdgeInsets.all(8.0), child: EventsPage()),
        Padding(padding: const EdgeInsets.all(8.0), child: ProfilePage(userDocumentId: FirebaseAuth.instance.currentUser!.uid)),
      ][currentPageIndex],
    );
  }
}
