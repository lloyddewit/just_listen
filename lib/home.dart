import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:flutter/material.dart';
import 'user_profile_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const UserProfileScreen(),
                ),
              );
            },
          ),
        ],
        title: const Text('Tough Talk'),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Column(
          children: [
            SizedBox(width: 250, child: Image.asset('assets/dash.png')),
            Text('Welcome!', style: Theme.of(context).textTheme.displaySmall),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        //selectedIndex: _selectedIndex,
        // onDestinationSelected: _onItemTapped,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home),
            label: 'Home',
            tooltip: 'Go back to start screen',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart),
            label: 'Progress',
            tooltip: 'See your progress',
          ),
          NavigationDestination(
            icon: Icon(Icons.history),
            label: 'History',
            tooltip: 'See your previous activities',
          ),
        ],
      ),
    );
  }
}
