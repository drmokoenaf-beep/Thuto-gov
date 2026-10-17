

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const supabaseUrl = 'https://ziekltrnewqtnlhfiyxx.supabase.co';

// Replace with your Supabase publishable key.
const supabasePublishableKey = 'sb_publishable_K-tqCzze6AlfTHyMt8f0nA_-kaeb5yn';
sb_publishable_K-tqCzze6AlfTHyMt8f0nA_-kaeb5ynFuture<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: supabaseUrl,
    publishableKey: supabasePublishableKey,
  );

  runApp(const ThutoGovApp());
}

final supabase = Supabase.instance.client;

class ThutoGovApp extends StatelessWidget {
  const ThutoGovApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Thuto Gov',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF174A35),
        ),
        useMaterial3: true,
      ),
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: supabase.auth.onAuthStateChange,
      builder: (context, snapshot) {
        if (supabase.auth.currentSession != null) {
          return const HomeScreen();
        }
        return const AuthScreen();
      },
    );
  }
}

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();

  bool _registering = false;
  bool _loading = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      if (_registering) {
        final response = await supabase.auth.signUp(
          email: _email.text.trim(),
          password: _password.text,
          data: {'full_name': _name.text.trim()},
        );

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              response.session == null
                  ? 'Registration received. Check your email to confirm.'
                  : 'Registration successful.',
            ),
          ),
        );
      } else {
        await supabase.auth.signInWithPassword(
          email: _email.text.trim(),
          password: _password.text,
        );
      }
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Connection failed. Check your settings.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Thuto Gov')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const Icon(Icons.verified_user, size: 72),
                const Text(
                  'DR MOKOENA INSTITUTION',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
                const SizedBox(height: 24),
                if (_registering)
                  TextFormField(
                    controller: _name,
                    decoration: const InputDecoration(
                      labelText: 'Full name',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) =>
                        v == null || v.trim().isEmpty
                            ? 'Enter your full name'
                            : null,
                  ),
                if (_registering) const SizedBox(height: 12),
                TextFormField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) =>
                      v == null || !v.contains('@')
                          ? 'Enter a valid email'
                          : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _password,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Password (at least 8 characters)',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) =>
                      v == null || v.length < 8
                          ? 'Use at least 8 characters'
                          : null,
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _loading ? null : _submit,
                    child: Text(
                      _loading
                          ? 'Please wait...'
                          : _registering
                              ? 'REGISTER'
                              : 'LOGIN',
                    ),
                  ),
                ),
                TextButton(
                  onPressed: _loading
                      ? null
                      : () => setState(
                            () => _registering = !_registering,
                          ),
                  child: Text(
                    _registering
                        ? 'Already registered? Login'
                        : 'New user? Register',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<Map<String, dynamic>?> _getProfile() async {
    final user = supabase.auth.currentUser;
    if (user == null) return null;

    return await supabase
        .from('profiles')
        .select('full_name, role')
        .eq('id', user.id)
        .maybeSingle();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thuto Gov Dashboard'),
        actions: [
          IconButton(
            tooltip: 'Logout',
            onPressed: () => supabase.auth.signOut(),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _getProfile(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError || snapshot.data == null) {
            return const Center(
              child: Text(
                'Profile unavailable. Check your Supabase database.',
              ),
            );
          }

          final profile = snapshot.data!;
          final name = profile['full_name'] ?? 'User';
          final role = profile['role'] ?? 'employee';

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const Icon(Icons.account_circle, size: 80),
              Text(
                'Welcome, $name',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              ListTile(
                leading: const Icon(Icons.security),
                title: const Text('Account role'),
                subtitle: Text(role.toString()),
              ),
              const Card(
                child: ListTile(
                  leading: Icon(Icons.access_time),
                  title: Text('Attendance'),
                  subtitle: Text('Attendance module to be connected next.'),
                ),
              ),
              const Card(
                child: ListTile(
                  leading: Icon(Icons.location_on),
                  title: Text('GPS location'),
                  subtitle: Text('Location module to be connected next.'),
                ),
              ),
              if (role == 'supervisor' || role == 'admin')
                const Card(
                  child: ListTile(
                    leading: Icon(Icons.dashboard),
                    title: Text('Supervisor dashboard'),
                    subtitle: Text('Supervisor role detected.'),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
