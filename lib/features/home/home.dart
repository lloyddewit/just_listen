import 'package:flutter/material.dart';
import 'settings_button.dart';
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

      bottomNavigationBar: const MainNavigationBar(),
    );
  }
}
