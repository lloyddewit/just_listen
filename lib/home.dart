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
            icon: const Icon(Icons.person),
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
        automaticallyImplyLeading: false,
      ),
      bottomNavigationBar: const Padding(
        padding: EdgeInsets.all(8.0),
        child: Text(
          'Made with ❤️ by the FlutterFire team',
          textAlign: TextAlign.center,
        ),
      ),
      bottomSheet: Container(
        color: Colors.lightGreen,
        height: 50,
        child: const Center(
          child: Text(
            'This is a bottom sheet',
            style: TextStyle(color: Colors.white),
          ),
        ),
      ),
      persistentFooterButtons: [
        TextButton(
          onPressed: () {},
          child: const Text('Persistent Footer Button 1'),
        ),
        TextButton(
          onPressed: () {},
          child: const Text('Persistent Footer Button 2'),
        ),
      ],
      body: Center(
        child: Column(
          children: [
            SizedBox(width: 250, child: Image.asset('assets/dash.png')),
            Text('Welcome!', style: Theme.of(context).textTheme.displaySmall),
            const SignOutButton(),
          ],
        ),
      ),
    );
  }
}
