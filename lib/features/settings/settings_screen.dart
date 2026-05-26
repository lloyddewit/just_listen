import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ProfileScreen(
      actions: [
        SignedOutAction((context) {
          Navigator.of(context).pop();
        }),
      ],
      appBar: AppBar(title: const Text('Settings')),
      avatar: const CircleAvatar(
        radius: 56,
        child: Icon(Icons.person, size: 56),
      ),
    );
  }
}
