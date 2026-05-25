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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: const [
                    Text('Welcome to Tough Talk!'),
                    SizedBox(height: 8),
                    Text('Your safe space to share and grow.'),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            const ElevatedButton(
              onPressed: null,
              child: Text('Start a New Conversation'),
            ),

            const SizedBox(height: 16),
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
