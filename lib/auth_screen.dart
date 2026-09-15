import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'main.dart'; // to access the global "supabase" client

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();

  bool _isLogin = true; // true = show Login form, false = show Sign Up form
  bool _isLoading = false;
  String? _errorMessage;

  // Role chosen at sign-up time. Defaults to patient.
  // NOTE: for a real production app you would NOT let users self-select
  // staff roles like doctor/nurse/admin — role assignment would be done
  // by an existing admin. This is set up as self-select here purely so
  // each role's screens can be demoed/tested easily from the app itself.
  String _selectedRole = 'patient';

  final List<Map<String, String>> _roleOptions = const [
    {'value': 'patient', 'label': 'Patient'},
    {'value': 'nurse', 'label': 'Nurse'},
    {'value': 'doctor', 'label': 'Doctor'},
    {'value': 'pharmacist', 'label': 'Pharmacist'},
    {'value': 'admin', 'label': 'Admin'},
  ];

  Future<void> _submit() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (_isLogin) {
        // LOG IN an existing user
        await supabase.auth.signInWithPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
      } else {
        // SIGN UP a new user
        await supabase.auth.signUp(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
          data: {
            'full_name': _nameController.text.trim(),
            'role': _selectedRole,
          },
        );

        // Explicitly set the role on the profiles row too, in case the
        // profile-creation trigger doesn't copy custom metadata fields.
        final newUserId = supabase.auth.currentUser?.id;
        if (newUserId != null) {
          await supabase
              .from('profiles')
              .update({'role': _selectedRole})
              .eq('id', newUserId);
        }
      }

      if (mounted) {
        // Check the user's role and route accordingly
        final userId = supabase.auth.currentUser!.id;
        final profile = await supabase
            .from('profiles')
            .select('role')
            .eq('id', userId)
            .single();

        final role = profile['role'] ?? 'patient';

        if (mounted) {
          switch (role) {
            case 'nurse':
              Navigator.pushReplacementNamed(context, '/nurse');
              break;
            case 'doctor':
              Navigator.pushReplacementNamed(context, '/doctor');
              break;
            case 'pharmacist':
              Navigator.pushReplacementNamed(context, '/pharmacist');
              break;
            case 'admin':
              Navigator.pushReplacementNamed(context, '/admin');
              break;
            default:
              Navigator.pushReplacementNamed(context, '/home');
          }
        }
      }
    } on AuthException catch (e) {
      setState(() => _errorMessage = e.message);
    } catch (e) {
      setState(() => _errorMessage = 'Something went wrong. Please try again.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F9F8),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 24),
              const Icon(Icons.shield_moon, size: 64, color: Color(0xFF0F4C4C)),
              const SizedBox(height: 12),
              const Text(
                'DetRabi',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF0D3B3B)),
              ),
              const Text(
                'AI-Based Rabies Risk Assessment & Vaccination Advisor',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 32),

              // Only show name + role fields when signing up
              if (!_isLogin) ...[
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),

                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Sign up as',
                    style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade400),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedRole,
                      isExpanded: true,
                      items: _roleOptions.map((role) {
                        return DropdownMenuItem<String>(
                          value: role['value'],
                          child: Text(role['label']!),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _selectedRole = value);
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],

              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),

              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
                ),

              ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F4C4C),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : Text(
                        _isLogin ? 'Log In' : 'Get Started',
                        style: const TextStyle(color: Colors.white, fontSize: 16),
                      ),
              ),
              const SizedBox(height: 12),

              TextButton(
                onPressed: () => setState(() {
                  _isLogin = !_isLogin;
                  _errorMessage = null;
                }),
                child: Text(
                  _isLogin
                      ? "Don't have an account? Sign up"
                      : 'Already have an account? Log in',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}