import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'profile_page.dart';
import 'groups_page.dart';
import 'events_page.dart';
import 'app_state.dart';

/// Flutter code sample for [NavigationBar].

void main() {
  runApp(ChangeNotifierProvider(
    create: (context) => ApplicationState(),
    builder: ((context, child) => const MyApp()),
  ));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(useMaterial3: true),
      home: const MainNavigation(),
    );
  }
}

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
          NavigationDestination(
            selectedIcon: Icon(Icons.home),
            icon: Icon(Icons.home_outlined),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Badge(child: Icon(Icons.notifications_sharp)),
            label: 'Notifications',
          ),
          NavigationDestination(
            icon: Badge(
              label: Text('2'),
              child: Icon(Icons.messenger_sharp),
            ),
            label: 'Messages',
          ),
        ],
      ),
      body: <Widget>[
        const Padding(padding: EdgeInsets.all(8.0), child: GroupsPage()),
        const Padding(padding: EdgeInsets.all(8.0), child: EventsPage()),
        const Padding(padding: EdgeInsets.all(8.0), child: ProfilePage()),
      ][currentPageIndex],
    );
  }
}
