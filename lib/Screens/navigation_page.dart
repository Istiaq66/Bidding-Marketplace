import 'package:auction_app/Screens/dashboard.dart';
import 'package:auction_app/Screens/home.dart';
import 'package:auction_app/Screens/profile.dart';

import 'package:flutter/material.dart';


class NavigationPage extends StatefulWidget {
  const NavigationPage({super.key});

  @override
  State<NavigationPage> createState() => _NavigationPageState();
}

class _NavigationPageState extends State<NavigationPage> {


  int index = 0;
  
  final screens = [
    const Home(),
    const Dashboard(),
    Profile(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[300],
  
      body: screens[index],
      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarThemeData(
            indicatorColor: Colors.blue.shade100,
            labelTextStyle: MaterialStateProperty.all(
              const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            )),
        child: NavigationBar(
            selectedIndex: index,
            onDestinationSelected: (index) => setState(() {
                  this.index = index;
                }),
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                label: 'Home',
                selectedIcon: Icon(Icons.home),
              ),
              NavigationDestination(
                icon: Icon(Icons.dashboard_customize_outlined),
                label: 'Dashboard',
                selectedIcon: Icon(Icons.dashboard),
              ),
              NavigationDestination(
                icon: Icon(Icons.person_2_outlined),
                label: 'Profile',
                selectedIcon: Icon(Icons.person),
              )
            ]),
      ),
    );
  }
}
