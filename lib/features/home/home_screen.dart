import 'package:flutter/material.dart';
import 'settings_button.dart';
import '../activity/activity_screen.dart';
import '../../core/widgets/main_navigation_bar.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(actions: const [SettingsButton()]),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                'This week',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Your recent activities will appear here.'),
              ),
            ),
            SizedBox(height: 16),

            IconButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const ActivityScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.wechat),
              iconSize: 48,
              tooltip: 'Start a new activity',
              padding: const EdgeInsets.all(12),
              style: IconButton.styleFrom(shape: CircleBorder()),
            ),
          ],
        ),
      ),

      bottomNavigationBar: const MainNavigationBar(),
    );
  }
}
