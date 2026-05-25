import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:flutter/material.dart';

class UserProfileScreen extends StatelessWidget {
  const UserProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ProfileScreen(
      actions: [
        SignedOutAction((context) {
          Navigator.of(context).pop();
        }),
      ],
      appBar: AppBar(title: const Text('User Profile')),
      avatar: const CircleAvatar(
        radius: 56,
        child: Icon(Icons.person, size: 56),
      ),
      children: [
        const Divider(),
        Padding(
          padding: const EdgeInsets.all(2),
          child: AspectRatio(
            aspectRatio: 1,
            child: Image.asset('assets/flutterfire_300x.png'),
          ),
        ),
        const SignOutButton(),
      ],
    );
  }
}
