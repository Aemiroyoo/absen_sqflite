import 'package:absen_sqflite/services/pref_services.dart';
import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  Future<Widget> _getStartupScreen() async {
    bool loggedIn = await PrefService.isLoggedIn();
    if (loggedIn) {
      return HomeScreen();
    } else {
      return LoginScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sistem Absensi',
      debugShowCheckedModeBanner: false,
      home: FutureBuilder<Widget>(
        future: _getStartupScreen(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Scaffold(body: Center(child: CircularProgressIndicator()));
          } else {
            return snapshot.data!;
          }
        },
      ),
    );
  }
}
