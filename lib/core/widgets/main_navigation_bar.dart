import 'package:flutter/material.dart';

class MainNavigationBar extends StatelessWidget {
  const MainNavigationBar({super.key});

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      destinations: [
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
    );
  }
}
