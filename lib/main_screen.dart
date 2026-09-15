import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'clinic_screen.dart';
import 'vaccine_tab.dart';
import 'profile_screen.dart';
import 'assessment_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  // Incremented every time the Vaccine tab is opened, so its key changes
  // and Flutter rebuilds it from scratch (fresh initState → fresh query)
  // instead of reusing the IndexedStack's cached, possibly-stale widget.
  int _vaccineTabRefreshCounter = 0;

  List<Widget> get _tabs => [
        const HomeScreen(),
        const SizedBox(), // placeholder — "Assess" opens a new screen instead of switching tabs
        VaccineTab(key: ValueKey('vaccine_tab_$_vaccineTabRefreshCounter')),
        const ClinicsScreen(),
        const ProfileScreen(),
      ];

  void _onTabTapped(int index) {
    if (index == 1) {
      // "Assess" is an action, not a tab you stay on
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const AssessmentScreen()),
      );
      return;
    }

    if (index == 2) {
      // Force the Vaccine tab to refetch every time it's opened, so a
      // just-completed assessment shows up immediately instead of the
      // stale "No active vaccination plan" from before it existed.
      setState(() {
        _vaccineTabRefreshCounter++;
        _selectedIndex = index;
      });
      return;
    }

    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _tabs,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onTabTapped,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF0F4C4C),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.assignment_outlined), label: 'Assess'),
          BottomNavigationBarItem(icon: Icon(Icons.vaccines_outlined), label: 'Vaccine'),
          BottomNavigationBarItem(icon: Icon(Icons.local_hospital_outlined), label: 'Clinics'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
      ),
    );
  }
}