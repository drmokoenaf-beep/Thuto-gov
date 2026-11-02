
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const String supabaseUrl =
    'https://uqmjkehzirlqpktwcdhh.supabase.co';

const String supabasePublishableKey =
    'sb_publishable_xE5Ftz-osVEAxVAeX32qTg_5UpKkRSi';

SupabaseClient get supabase => Supabase.instance.client;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Supabase.initialize(
      url: supabaseUrl,
      publishableKey: supabasePublishableKey,
    );

    runApp(const ThutoGovApp());
  } catch (e) {
    runApp(StartupErrorApp(error: e.toString()));
  }
}

class StartupErrorApp extends StatelessWidget {
  final String error;

  const StartupErrorApp({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: SelectableText(
              'Thuto Gov could not start.\n\n$error',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}

class ThutoGovApp extends StatelessWidget {
  const ThutoGovApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Thuto Gov',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.green,
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
        return const LoginScreen();
      },
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool loading = false;
  String message = '';
  bool success = false;

  Future<void> login() async {
    final email = emailController.text.trim();
    final password = passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() {
        message = 'Enter your email and password.';
        success = false;
      });
      return;
    }

    setState(() {
      loading = true;
      message = 'Connecting to Thuto Gov...';
      success = false;
    });

    try {
      await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (!mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => const HomeScreen(),
        ),
        (route) => false,
      );
    } on AuthException catch (e) {
      if (mounted) {
        setState(() {
          message = 'Login error: ${e.message}';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          message = 'Connection error: $e';
        });
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Thuto Gov Login')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Icon(Icons.account_balance,
                  size: 72, color: Colors.green),
              const SizedBox(height: 12),
              const Text(
                'THUTO GOV',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Text(
                'Dr Mokoena Institution & Indigenous Knowledge Systems',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email address',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              if (message.isNotEmpty)
                SelectableText(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: success ? Colors.green : Colors.red,
                  ),
                ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: loading ? null : login,
                  child: Text(loading ? 'Connecting...' : 'Login'),
                ),
              ),
              TextButton(
                onPressed: loading
                    ? null
                    : () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                const RegistrationScreen(),
                          ),
                        );
                      },
                child: const Text('Create an account'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// REGISTRATION SCREEN

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() =>
      _RegistrationScreenState();
}

class _RegistrationScreenState
    extends State<RegistrationScreen> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final idController = TextEditingController();
  final departmentController = TextEditingController();
  final positionController = TextEditingController();
  final passwordController = TextEditingController();

  bool loading = false;
  bool success = false;
  String message = '';

  // HTTPS DIAGNOSTIC
  Future<String> testSupabaseConnection() async {
    HttpClient? client;

    try {
      client = HttpClient()
        ..connectionTimeout = const Duration(seconds: 15);

      final request = await client.getUrl(
        Uri.parse('$supabaseUrl/auth/v1/health'),
      );

      final response = await request.close();
      final statusCode = response.statusCode;

      await response.drain();

      return 'HTTPS CONNECTION SUCCESS: HTTP $statusCode';
    } catch (e) {
      return 'HTTPS CONNECTION FAILED: $e';
    } finally {
      client?.close(force: true);
    }
  }

  Future<void> register() async {
    final name = nameController.text.trim();
    final email = emailController.text.trim();
    final idNumber = idController.text.trim();
    final department = departmentController.text.trim();
    final position = positionController.text.trim();
    final password = passwordController.text;

    if (name.isEmpty ||
        email.isEmpty ||
        password.length < 6) {
      setState(() {
        message =
            'Enter your name, email and a password of at least 6 characters.';
        success = false;
      });
      return;
    }

    setState(() {
      loading = true;
      message = 'Testing Supabase HTTPS connection...';
      success = false;
    });

    try {
      // STEP 1: Test HTTPS
      final diagnostic = await testSupabaseConnection();

      if (!mounted) return;

      setState(() {
        message = diagnostic;
        success = diagnostic.contains('SUCCESS');
      });

      if (diagnostic.contains('FAILED')) {
        return;
      }

      // STEP 2: Register account
      setState(() {
        message = '$diagnostic\nCreating your account...';
      });

      final response = await supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': name,
          'id_number': idNumber,
          'department': department,
          'position': position,
        },
      );

      if (response.user == null) {
        throw const AuthException(
          'Registration did not return a user.',
        );
      }

      if (!mounted) return;

      if (response.session == null) {
        setState(() {
          message =
              'Account created. Please check your email and confirm your account before logging in.';
          success = true;
        });
      } else {
        setState(() {
          message = 'Registration successful.';
          success = true;
        });

        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => const HomeScreen(),
          ),
          (route) => false,
        );
      }
    } on AuthException catch (e) {
      if (mounted) {
        setState(() {
          message = 'Registration error: ${e.message}';
          success = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          message = 'Connection error: $e';
          success = false;
        });
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    idController.dispose();
    departmentController.dispose();
    positionController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Widget field(
    TextEditingController controller,
    String label, {
    bool obscure = false,
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Account')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Icon(
              Icons.person_add_alt_1,
              size: 55,
              color: Colors.green,
            ),
            const SizedBox(height: 16),
            const Text(
              'THUTO GOV REGISTRATION',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            field(nameController, 'Full name'),
            field(
              emailController,
              'Email',
              keyboardType: TextInputType.emailAddress,
            ),
            field(
              idController,
              'South African ID number (optional)',
              keyboardType: TextInputType.number,
            ),
            field(departmentController, 'Department'),
            field(positionController, 'Position'),
            field(
              passwordController,
              'Password (minimum 6 characters)',
              obscure: true,
            ),
            if (message.isNotEmpty)
              SelectableText(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: success ? Colors.green : Colors.red,
                ),
              ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: loading ? null : register,
                child: Text(
                  loading ? 'Testing / Registering...' : 'Register',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// HOME SCREEN

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<void> logout(BuildContext context) async {
    try {
      await supabase.auth.signOut();

      if (!context.mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => const LoginScreen(),
        ),
        (route) => false,
      );
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Logout failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = supabase.auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Thuto Gov Dashboard'),
        actions: [
          IconButton(
            onPressed: () => logout(context),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Welcome${user?.email == null ? '' : ', ${user!.email}'}',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Dr Mokoena Institution & Indigenous Knowledge Systems',
          ),
          const SizedBox(height: 20),
          const DashboardCard(
            title: 'Supervisor Dashboard',
            subtitle: 'Supervisor features require role-based access.',
            icon: Icons.admin_panel_settings,
          ),
          const DashboardCard(
            title: 'Attendance',
            subtitle: 'Attendance functions are not connected yet.',
            icon: Icons.fact_check,
          ),
          const DashboardCard(
            title: 'Classrooms',
            subtitle: 'Classroom functions are not connected yet.',
            icon: Icons.class_,
          ),
          const DashboardCard(
            title: 'Private Marks',
            subtitle: 'Private marks are not connected yet.',
            icon: Icons.grade,
          ),
          const DashboardCard(
            title: 'Services',
            subtitle: 'Service listing is not connected yet.',
            icon: Icons.account_balance,
          ),
        ],
      ),
    );
  }
}

class DashboardCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const DashboardCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon, color: Colors.green, size: 32),
        title: Text(title),
        subtitle: Text(subtitle),
      ),
    );
  }
}