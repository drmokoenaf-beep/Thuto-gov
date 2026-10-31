
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const String supabaseUrl =
    'https://uqmjkehzirlqpktwcdhh.supabase.co';

const String supabasePublishableKey =
    'sb_publishable_xE5Ftz-osVEAxVAeX32qTg_5UpKkRSi';

final SupabaseClient supabase = Supabase.instance.client;

/// Checks general DNS and Supabase DNS, then tests Supabase HTTPS.
Future<String> checkSupabaseConnection() async {
  const googleHost = 'google.com';
  const supabaseHost = 'uqmjkehzirlqpktwcdhh.supabase.co';

  final results = <String>[];
  bool supabaseDnsOk = false;

  Future<bool> checkDns(String host) async {
    try {
      final addresses = await InternetAddress.lookup(host)
          .timeout(const Duration(seconds: 15));

      if (addresses.isEmpty) {
        final result = 'DNS_FAIL: $host returned no IP address';
        debugPrint(result);
        results.add(result);
        return false;
      }

      final result = 'DNS_OK: $host -> ${addresses.first.address}';
      debugPrint(result);
      results.add(result);
      return true;
    } catch (e) {
      final result = 'DNS_FAIL: $host -> $e';
      debugPrint(result);
      results.add(result);
      return false;
    }
  }

  await checkDns(googleHost);
  supabaseDnsOk = await checkDns(supabaseHost);

  if (!supabaseDnsOk) {
    return results.join('\n');
  }

  final client = HttpClient();

  try {
    final request = await client
        .getUrl(Uri.parse('$supabaseUrl/auth/v1/health'))
        .timeout(const Duration(seconds: 15));

    final response = await request.close()
        .timeout(const Duration(seconds: 15));

    final statusCode = response.statusCode;
    await response.drain();

    final result = 'SUPABASE_HTTPS_OK: HTTP $statusCode';
    debugPrint(result);
    results.add(result);
  } catch (e) {
    final result = 'SUPABASE_HTTPS_FAIL: $e';
    debugPrint(result);
    results.add(result);
  } finally {
    client.close(force: true);
  }

  return results.join('\n');
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: supabaseUrl,
    publishableKey: supabasePublishableKey,
  );

  runApp(const ThutoGovApp());
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

  Future<void> login() async {
    final email = emailController.text.trim();
    final password = passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() {
        message = 'Enter your email and password.';
      });
      return;
    }

    setState(() {
      loading = true;
      message = 'Checking internet connection...';
    });

    try {
      final diagnostic = await checkSupabaseConnection();

      debugPrint(diagnostic);

      if (!diagnostic.contains(
        'DNS_OK: uqmjkehzirlqpktwcdhh.supabase.co',
      )) {
        if (mounted) {
          setState(() => message = diagnostic);
        }
        return;
      }

      if (!diagnostic.contains('SUPABASE_HTTPS_OK')) {
        if (mounted) {
          setState(() => message =
              '$diagnostic\nSupabase HTTPS connection failed.');
        }
        return;
      }

      if (mounted) {
        setState(() => message = 'Connecting to your account...');
      }

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
        setState(() => message = e.message);
      }
    } catch (e) {
      if (mounted) {
        setState(() => message = 'Login failed: $e');
      }
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
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
              const Icon(
                Icons.account_balance,
                size: 72,
                color: Colors.green,
              ),
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
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: loading ? null : login,
                  child: Text(
                    loading ? 'Checking connection...' : 'Login',
                  ),
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
  String message = '';

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
      });
      return;
    }

    setState(() {
      loading = true;
      message = 'Checking internet connection...';
    });

    try {
      final diagnostic = await checkSupabaseConnection();

      debugPrint(diagnostic);

      if (!diagnostic.contains(
        'DNS_OK: uqmjkehzirlqpktwcdhh.supabase.co',
      )) {
        if (mounted) {
          setState(() => message = diagnostic);
        }
        return;
      }

      if (!diagnostic.contains('SUPABASE_HTTPS_OK')) {
        if (mounted) {
          setState(() => message =
              '$diagnostic\nSupabase HTTPS connection failed.');
        }
        return;
      }

      if (mounted) {
        setState(() => message = 'Creating your account...');
      }

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

      final user = response.user;

      if (user == null) {
        throw const AuthException(
          'Registration did not return a user. Please try again.',
        );
      }

      if (response.session != null) {
        await supabase.from('profiles').upsert({
          'id': user.id,
          'email': email,
          'full_name': name,
          'id_number': idNumber,
          'department': department,
          'position': position,
          'role': 'user',
          'face_verified': false,
        }, onConflict: 'id');
      }

      if (!mounted) return;

      if (response.session == null) {
        setState(() {
          message =
              'Account created. Check your email to confirm it, then log in.';
        });
      } else {
        setState(() {
          message = 'Registration successful.';
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
        setState(() => message = e.message);
      }
    } catch (e) {
      if (mounted) {
        setState(() => message = 'Registration failed: $e');
      }
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Account')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Full name',
              ),
            ),
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email',
              ),
            ),
            TextField(
              controller: idController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'South African ID number (optional)',
              ),
            ),
            TextField(
              controller: departmentController,
              decoration: const InputDecoration(
                labelText: 'Department',
              ),
            ),
            TextField(
              controller: positionController,
              decoration: const InputDecoration(
                labelText: 'Position',
              ),
            ),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Password (minimum 6 characters)',
              ),
            ),
            const SizedBox(height: 20),
            if (message.isNotEmpty)
              SelectableText(
                message,
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: loading ? null : register,
                child: Text(
                  loading ? 'Checking connection...' : 'Register',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<void> logout(BuildContext context) async {
    await supabase.auth.signOut();

    if (!context.mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => const LoginScreen(),
      ),
      (route) => false,
    );
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
            tooltip: 'Logout',
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
        leading: Icon(
          icon,
          color: Colors.green,
          size: 32,
        ),
        title: Text(title),
        subtitle: Text(subtitle),
      ),
    );
  }
}
