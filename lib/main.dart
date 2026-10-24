
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const String supabaseUrl = 'YOUR_SUPABASE_PROJECT_URL';
const String supabasePublishableKey = 'YOUR_SUPABASE_PUBLISHABLE_KEY';

const Color green = Color(0xFF007A33);
const Color soil = Color(0xFF795548);
const Color background = Color(0xFFF5F7F4);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (supabaseUrl.startsWith('YOUR_') ||
      supabasePublishableKey.startsWith('YOUR_')) {
    runApp(const ConfigurationApp());
    return;
  }

  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabasePublishableKey,
  );

  runApp(const ThutoGovApp());
}

class ConfigurationApp extends StatelessWidget {
  const ConfigurationApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: green),
      ),
      home: const Scaffold(
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Supabase configuration is required. '
              'Add your project URL and publishable key in main.dart.',
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
        useMaterial3: true,
        scaffoldBackgroundColor: background,
        colorScheme: ColorScheme.fromSeed(
          seedColor: green,
          primary: green,
          secondary: soil,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: green,
          foregroundColor: Colors.white,
          centerTitle: true,
        ),
      ),
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final client = Supabase.instance.client;

    return StreamBuilder<AuthState>(
      stream: client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        final session = client.auth.currentSession ??
            snapshot.data?.session;

        if (session != null) {
          return const HomeScreen();
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
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
  final formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool isRegistering = false;
  bool isLoading = false;
  bool obscurePassword = true;

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> submit() async {
    if (!formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    try {
      final client = Supabase.instance.client;
      final email = emailController.text.trim();
      final password = passwordController.text;

      if (isRegistering) {
        final response = await client.auth.signUp(
          email: email,
          password: password,
          data: {
            'full_name': nameController.text.trim(),
          },
        );

        if (response.session == null && mounted) {
          showMessage(
            'Registration submitted. Check your email to confirm '
            'your account before signing in.',
          );
        }
      } else {
        await client.auth.signInWithPassword(
          email: email,
          password: password,
        );
      }
    } on AuthException catch (error) {
      showMessage(error.message);
    } catch (_) {
      showMessage(
        'The request could not be completed. Check your connection '
        'and Supabase configuration.',
      );
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(
                    Icons.school,
                    size: 76,
                    color: green,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'THUTO GOV',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: green,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Developed by Dr Mokoena Institution '
                    '& Indigenous Knowledge Systems',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 28),
                  Text(
                    isRegistering ? 'Create your account' : 'Sign in',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 23,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (isRegistering) ...[
                    TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Full name',
                        prefixIcon: Icon(Icons.person),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (isRegistering &&
                            (value == null || value.trim().isEmpty)) {
                          return 'Enter your full name.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                  ],
                  TextFormField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email address',
                      prefixIcon: Icon(Icons.email),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null ||
                          !value.contains('@') ||
                          !value.contains('.')) {
                        return 'Enter a valid email address.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: passwordController,
                    obscureText: obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock),
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        onPressed: () {
                          setState(() {
                            obscurePassword = !obscurePassword;
                          });
                        },
                        icon: Icon(
                          obscurePassword
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.length < 6) {
                        return 'Password must have at least 6 characters.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: isLoading ? null : submit,
                    style: FilledButton.styleFrom(
                      backgroundColor: green,
                      padding: const EdgeInsets.all(16),
                    ),
                    child: isLoading
                        ? const CircularProgressIndicator(
                            color: Colors.white,
                          )
                        : Text(
                            isRegistering ? 'Register' : 'Sign in',
                          ),
                  ),
                  TextButton(
                    onPressed: isLoading
                        ? null
                        : () {
                            setState(() {
                              isRegistering = !isRegistering;
                            });
                          },
                    child: Text(
                      isRegistering
                          ? 'Already registered? Sign in'
                          : 'New user? Create an account',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int selectedIndex = 0;
  String role = 'student';
  bool checkingRole = true;

  final List<String> titles = const [
    'Thuto Gov',
    'Classroom & Chatroom',
    'Private Marks',
    'Attendance Reports',
    'Supervisor Dashboard',
  ];

  @override
  void initState() {
    super.initState();
    loadRole();
  }

  Future<void> loadRole() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;

      if (user != null) {
        final profile = await Supabase.instance.client
            .from('profiles')
            .select('role')
            .eq('id', user.id)
            .maybeSingle();

        if (mounted && profile != null) {
          role = (profile['role'] as String?) ?? 'student';
        }
      }
    } catch (_) {
      // Keep the default role if the profile cannot be loaded.
    }

    if (mounted) {
      setState(() => checkingRole = false);
    }
  }

  Future<void> signOut() async {
    await Supabase.instance.client.auth.signOut();
  }

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      const DashboardScreen(),
      const ClassroomScreen(),
      const PrivateMarksScreen(),
      const AttendanceScreen(),
      SupervisorScreen(
        role: role,
        checkingRole: checkingRole,
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          titles[selectedIndex],
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            onPressed: signOut,
            tooltip: 'Sign out',
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: green),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Icon(Icons.school, color: Colors.white, size: 42),
                  SizedBox(height: 10),
                  Text(
                    'THUTO GOV',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 23,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Dr Mokoena Institution & IKS',
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
            _menu(Icons.home, 'Home', 0),
            _menu(Icons.forum, 'Classroom & Chatroom', 1),
            _menu(Icons.lock, 'Private Marks', 2),
            _menu(Icons.fact_check, 'Attendance Reports', 3),
            if (!checkingRole && role == 'admin')
              _menu(Icons.admin_panel_settings, 'Supervisor Dashboard', 4),
          ],
        ),
      ),
      body: SafeArea(child: pages[selectedIndex]),
    );
  }

  Widget _menu(IconData icon, String label, int index) {
    return ListTile(
      leading: Icon(icon, color: green),
      title: Text(label),
      selected: selectedIndex == index,
      onTap: () {
        setState(() => selectedIndex = index);
        Navigator.pop(context);
      },
    );
  }
}

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: green,
            borderRadius: BorderRadius.circular(18),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.account_balance, color: Colors.white, size: 42),
              SizedBox(height: 12),
              Text(
                'Welcome to Thuto Gov',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Education, accountability and transparent service delivery.',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const ServiceCard(
          icon: Icons.forum,
          title: 'Classroom & Chatroom',
          subtitle: 'Collaborate on projects and homework.',
        ),
        const ServiceCard(
          icon: Icons.lock,
          title: 'Private Marks',
          subtitle: 'Access individual academic results securely.',
        ),
        const ServiceCard(
          icon: Icons.fact_check,
          title: 'Attendance Reports',
          subtitle: 'Review attendance and incomplete check-outs.',
        ),
      ],
    );
  }
}

class ServiceCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const ServiceCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: const Color(0xFFE3F1E6),
          child: Icon(icon, color: green),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(subtitle),
      ),
    );
  }
}

class ClassroomScreen extends StatefulWidget {
  const ClassroomScreen({super.key});

  @override
  State<ClassroomScreen> createState() => _ClassroomScreenState();
}

class _ClassroomScreenState extends State<ClassroomScreen> {
  final controller = TextEditingController();
  final List<String> messages = [];

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void sendMessage() {
    final message = controller.text.trim();
    if (message.isEmpty) return;

    setState(() {
      messages.add(message);
      controller.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'Classroom & Chatroom',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: messages.isEmpty
              ? const Center(
                  child: Text(
                    'Classroom messages will appear here.',
                    textAlign: TextAlign.center,
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: messages.length,
                  itemBuilder: (context, index) => Card(
                    child: ListTile(
                      leading: const Icon(Icons.forum, color: green),
                      title: Text(messages[index]),
                    ),
                  ),
                ),
        ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  decoration: const InputDecoration(
                    hintText: 'Write a message...',
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: (_) => sendMessage(),
                ),
              ),
              IconButton(
                onPressed: sendMessage,
                icon: const Icon(Icons.send, color: green),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class PrivateMarksScreen extends StatelessWidget {
  const PrivateMarksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const InformationScreen(
      icon: Icons.lock,
      title: 'Private Academic Results',
      message:
          'Your marks must be loaded from student_marks using '
          'authenticated user permissions. Database policies must ensure '
          'that learners can only access their own results.',
    );
  }
}

class AttendanceScreen extends StatelessWidget {
  const AttendanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const InformationScreen(
      icon: Icons.fact_check,
      title: 'Attendance Reports',
      message:
          'The attendance module is ready for database integration. '
          'Connect check-in, check-out and reporting queries to your '
          'attendance table before using real records.',
    );
  }
}

class SupervisorScreen extends StatelessWidget {
  final String role;
  final bool checkingRole;

  const SupervisorScreen({
    super.key,
    required this.role,
    required this.checkingRole,
  });

  @override
  Widget build(BuildContext context) {
    if (checkingRole) {
      return const Center(child: CircularProgressIndicator());
    }

    if (role != 'admin') {
      return const InformationScreen(
        icon: Icons.lock,
        title: 'Access restricted',
        message:
            'This dashboard is available only to authorised administrators.',
      );
    }

    return const InformationScreen(
      icon: Icons.admin_panel_settings,
      title: 'Supervisor Dashboard',
      message:
          'Administrator access confirmed from the profile role. '
          'Attendance summaries, missing check-outs and classroom oversight '
          'must still be connected to protected database queries.',
    );
  }
}

class InformationScreen extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const InformationScreen({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Icon(icon, size: 62, color: green),
        const SizedBox(height: 16),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 23,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          message,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
