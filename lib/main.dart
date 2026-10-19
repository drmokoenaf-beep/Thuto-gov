
import 'package:flutter/material.dart';

void main() {
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
          seedColor: const Color(0xFF14532D),
        ),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF14532D),
        foregroundColor: Colors.white,
        title: const Text(
          'THUTO GOV',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              _message(context, 'Ha ho ditsebiso tse ntjha.');
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Color(0xFF14532D)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Icon(Icons.account_balance,
                      color: Colors.white, size: 42),
                  SizedBox(height: 8),
                  Text('Thuto Gov',
                      style: TextStyle(
                          color: Colors.white, fontSize: 24)),
                  Text('Accountability for Everyone',
                      style: TextStyle(color: Colors.white70)),
                ],
              ),
            ),
            _menuItem(context, Icons.home, 'Home'),
            _menuItem(context, Icons.person_add, 'Registration'),
            _menuItem(context, Icons.fact_check, 'Attendance'),
            _menuItem(context, Icons.assignment, 'Applications'),
            _menuItem(context, Icons.location_on, 'GPS Location'),
            _menuItem(context, Icons.admin_panel_settings,
                'Supervisor Dashboard'),
            _menuItem(context, Icons.settings, 'Settings'),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: const Color(0xFF14532D),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.public, color: Colors.white, size: 42),
                  SizedBox(height: 12),
                  Text(
                    'Welcome to Thuto Gov',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'A global platform for accountability, '
                    'attendance and public service.',
                    style: TextStyle(
                        color: Colors.white, fontSize: 15),
                  ),
                  SizedBox(height: 14),
                  Text(
                    'Developed by Dr Mokoena Institution '
                    '& Indigenous Knowledge Systems',
                    style: TextStyle(
                        color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Main Services',
              style: TextStyle(
                  fontSize: 21, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.05,
              children: [
                _serviceCard(
                  context,
                  Icons.person_add_alt_1,
                  'Registration',
                  'Create your profile',
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const RegistrationPage(),
                    ),
                  ),
                ),
                _serviceCard(
                  context,
                  Icons.fact_check,
                  'Attendance',
                  'Check in or out',
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AttendancePage(),
                    ),
                  ),
                ),
                _serviceCard(
                  context,
                  Icons.assignment_outlined,
                  'Applications',
                  'Manage your requests',
                  () => _message(
                      context, 'Applications service is being prepared.'),
                ),
                _serviceCard(
                  context,
                  Icons.admin_panel_settings,
                  'Supervisor',
                  'Accountability dashboard',
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const SupervisorPage(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Card(
              child: ListTile(
                leading: const Icon(Icons.security,
                    color: Color(0xFF14532D), size: 32),
                title: const Text('Security and Privacy'),
                subtitle: const Text(
                  'Your information must be protected '
                  'through secure authentication and access controls.',
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Center(
              child: Text(
                'Thuto Gov • Version 1.0.0',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Widget _serviceCard(
  BuildContext context,
  IconData icon,
  String title,
  String subtitle,
  VoidCallback onTap,
) {
  return Card(
    elevation: 2,
    child: InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 36, color: const Color(0xFF14532D)),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 5),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    ),
  );
}

Widget _menuItem(
  BuildContext context,
  IconData icon,
  String title,
) {
  return ListTile(
    leading: Icon(icon),
    title: Text(title),
    onTap: () {
      Navigator.pop(context);
      if (title == 'Registration') {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const RegistrationPage(),
          ),
        );
      } else if (title == 'Attendance') {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const AttendancePage(),
          ),
        );
      } else if (title == 'Supervisor Dashboard') {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const SupervisorPage(),
          ),
        );
      } else if (title != 'Home') {
        _message(context, '$title service is being prepared.');
      }
    },
  );
}

class RegistrationPage extends StatefulWidget {
  const RegistrationPage({super.key});

  @override
  State<RegistrationPage> createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registration')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Create your profile',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: nameController,
            decoration: const InputDecoration(
              labelText: 'Full name',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Email address',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: phoneController,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'Phone number',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: () {
              if (nameController.text.trim().isEmpty ||
                  !emailController.text.contains('@')) {
                _message(
                  context,
                  'Enter your full name and a valid email address.',
                );
                return;
              }
              _message(
                context,
                'Form completed. Database registration '
                'must be connected before details can be saved.',
              );
            },
            child: const Text('Submit Registration'),
          ),
        ],
      ),
    );
  }
}

class AttendancePage extends StatelessWidget {
  const AttendancePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Attendance')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.fact_check,
                  size: 70, color: Color(0xFF14532D)),
              const SizedBox(height: 16),
              const Text(
                'Attendance Check-in / Check-out',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              const Text(
                'GPS and secure database integration are '
                'required to record verified attendance.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () => _message(
                  context,
                  'GPS attendance is not active yet. '
                  'Location permissions and database '
                  'integration must be configured.',
                ),
                icon: const Icon(Icons.login),
                label: const Text('Check In'),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () => _message(
                  context,
                  'Check-out recording is not active yet.',
                ),
                icon: const Icon(Icons.logout),
                label: const Text('Check Out'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SupervisorPage extends StatelessWidget {
  const SupervisorPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Supervisor Dashboard')),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.admin_panel_settings,
                  size: 70, color: Color(0xFF14532D)),
              SizedBox(height: 16),
              Text(
                'Supervisor Dashboard',
                style: TextStyle(
                    fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 12),
              Text(
                'Supervisor login, user management and '
                'reports will require secure authentication '
                'and database permissions.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void _message(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message)),
  );
}
