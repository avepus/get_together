import 'package:flutter/material.dart';
import 'navigation_pages/profile_page.dart';
import 'navigation_pages/groups_page.dart';
import 'navigation_pages/events_page.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

enum Pages { groups, events, profile }

class _MainNavigationState extends State<MainNavigation> {
  int currentPageIndex = Pages.groups.index;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
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
        const Padding(padding: EdgeInsets.all(8.0), child: GroupsPage()),
        const Padding(padding: EdgeInsets.all(8.0), child: EventsPage()),
        Padding(padding: EdgeInsets.all(8.0), child: ProfilePage()),
      ][currentPageIndex],
    );
  }
}
