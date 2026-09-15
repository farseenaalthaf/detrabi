import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_screen.dart';
import 'home_screen.dart';
import 'nurse_screen.dart';
import 'doctor_screen.dart';
import 'pharmacist_screen.dart';
import 'admin_screen.dart';
import 'main_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://ajdbcbfjlzpypgqinwgg.supabase.co',
    publishableKey: 'sb_publishable_GqvfIkzcsdqCxXhoZzJjbQ_l6qiDF3A',
  );
  runApp(const MyApp());
}

final supabase = Supabase.instance.client;

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DetRabi',
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) => AuthScreen(),
        '/home': (context) => const MainScreen(),
        '/nurse': (context) => const NurseScreen(),
        '/doctor': (context) => const DoctorScreen(),
        '/pharmacist': (context) => const PharmacistScreen(),
        '/admin': (context) => const AdminScreen(),
      },
    );
  }
}