import 'package:flutter/material.dart';
import 'main.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _fullName = '';
  String _email = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final user = supabase.auth.currentUser!;
    final profile = await supabase
        .from('profiles')
        .select()
        .eq('id', user.id)
        .single();

    setState(() {
      _fullName = profile['full_name'] ?? '';
      _email = user.email ?? '';
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF4F9F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF4F9F8),
        elevation: 0,
        title: const Text('Profile', style: TextStyle(color: Color(0xFF0D3B3B))),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: CircleAvatar(
              radius: 40,
              backgroundColor: const Color(0xFFE6F3F1),
              child: Text(
                _fullName.isNotEmpty ? _fullName[0].toUpperCase() : '?',
                style: const TextStyle(fontSize: 32, color: Color(0xFF0F4C4C), fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(_fullName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0D3B3B))),
          ),
          Center(
            child: Text(_email, style: TextStyle(color: Colors.grey[600])),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () async {
              await supabase.auth.signOut();
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, '/');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[50],
              foregroundColor: Colors.red[700],
              minimumSize: const Size.fromHeight(48),
            ),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );
  }
}