
import 'package:flutter/material.dart';

void main() {
  runApp(const ThutoGovApp());
}

const green = Color(0xFF007A33);
const soil = Color(0xFF795548);
const background = Color(0xFFF5F7F4);

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
      home: const HomeScreen(),
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

  final List<Widget> pages = const [
    DashboardScreen(),
    ClassroomScreen(),
    PrivateMarksScreen(),
    AttendanceScreen(),
    SupervisorScreen(),
  ];

  final List<String> titles = const [
    'Thuto Gov',
    'Classroom & Chatroom',
    'Private Marks',
    'Attendance Reports',
    'Supervisor Dashboard',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          titles[selectedIndex],
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
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
                    'Developed by Dr Mokoena Institution & IKS',
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
            _menu(Icons.home, 'Home', 0),
            _menu(Icons.forum, 'Classroom & Chatroom', 1),
            _menu(Icons.lock, 'Private Marks', 2),
            _menu(Icons.fact_check, 'Attendance Reports', 3),
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
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
          const Text(
            'YOUR SERVICES',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
          ),
          const SizedBox(height: 12),
          const ServiceCard(
            icon: Icons.forum,
            title: 'Classroom & Chatroom',
            subtitle: 'Teachers and learners collaborate on homework.',
          ),
          const ServiceCard(
            icon: Icons.lock_outline,
            title: 'Private Marks',
            subtitle: 'A private space for individual academic results.',
          ),
          const ServiceCard(
            icon: Icons.fact_check,
            title: 'Attendance',
            subtitle: 'Check-in, check-out and attendance reports.',
          ),
          const ServiceCard(
            icon: Icons.admin_panel_settings,
            title: 'Supervisor Dashboard',
            subtitle: 'Review reports and identify missing check-outs.',
          ),
          const SizedBox(height: 16),
          const Text(
            'Use the menu at the top left to open each section.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
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
      elevation: 1,
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
  final TextEditingController messageController = TextEditingController();
  final List<String> messages = [];

  @override
  void dispose() {
    messageController.dispose();
    super.dispose();
  }

  void sendMessage() {
    final text = messageController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      messages.add(text);
      messageController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Classroom & Chatroom',
                style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 6),
              Text('Discuss lessons, projects and homework.'),
            ],
          ),
        ),
        Expanded(
          child: messages.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.forum_outlined, size: 55, color: green),
                        SizedBox(height: 12),
                        Text(
                          'Welcome to your classroom',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Write a message below to start a local conversation.',
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: messages.length,
                  itemBuilder: (context, index) => Card(
                    child: ListTile(
                      leading: const CircleAvatar(
                        child: Icon(Icons.person),
                      ),
                      title: Text(messages[index]),
                    ),
                  ),
                ),
        ),
        Container(
          padding: const EdgeInsets.all(12),
          color: Colors.white,
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: messageController,
                  decoration: const InputDecoration(
                    hintText: 'Write homework or project message...',
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: (_) => sendMessage(),
                ),
              ),
              IconButton(
                onPressed: sendMessage,
                icon: const Icon(Icons.send, color: green),
                tooltip: 'Send message',
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
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Icon(Icons.lock_outline, size: 60, color: green),
        const SizedBox(height: 12),
        const Text(
          'Private Academic Results',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        const Text(
          'Learners must sign in before viewing their own marks. '
          'Only authorised teachers may enter or update marks.',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        const Card(
          child: Padding(
            padding: EdgeInsets.all(18),
            child: Column(
              children: [
                Icon(Icons.verified_user, color: green, size: 34),
                SizedBox(height: 8),
                Text(
                  'Privacy protection required',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  'Connect Supabase authentication and Row Level Security '
                  'before displaying real learner results.',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class AttendanceScreen extends StatelessWidget {
  const AttendanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Icon(Icons.fact_check, size: 56, color: green),
        const SizedBox(height: 12),
        const Text(
          'Attendance Reports',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        const ServiceCard(
          icon: Icons.login,
          title: 'Check-in',
          subtitle: 'Record the authorised arrival time.',
        ),
        const ServiceCard(
          icon: Icons.logout,
          title: 'Check-out',
          subtitle: 'Record the departure time.',
        ),
        const ServiceCard(
          icon: Icons.warning_amber,
          title: 'Missing check-outs',
          subtitle: 'Flag incomplete records for supervisor review.',
        ),
        const Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'No live attendance records are loaded yet. '
              'Connect the Supabase attendance table to enable real reports.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    );
  }
}

class SupervisorScreen extends StatelessWidget {
  const SupervisorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const CircleAvatar(
          radius: 38,
          backgroundColor: green,
          child: Icon(
            Icons.admin_panel_settings,
            color: Colors.white,
            size: 42,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Supervisor Dashboard',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text(
          'Manage authorised reviews of attendance, classrooms and reports.',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        const ServiceCard(
          icon: Icons.assessment,
          title: 'Attendance Summary',
          subtitle: 'Connect the database to view actual attendance totals.',
        ),
        const ServiceCard(
          icon: Icons.warning_amber,
          title: 'Records Requiring Review',
          subtitle: 'Identify missing check-outs and investigate exceptions.',
        ),
        const ServiceCard(
          icon: Icons.school,
          title: 'Classroom Oversight',
          subtitle: 'Review classroom activity with appropriate permissions.',
        ),
        const ServiceCard(
          icon: Icons.security,
          title: 'Access Control',
          subtitle: 'Supervisor access must be verified using Supabase roles.',
        ),
        const SizedBox(height: 12),
        const Text(
          'Important: this screen is a user interface, not an access-control '
          'system. Protect supervisor functions with server-side permissions.',
          textAlign: TextAlign.center,
          style: TextStyle(color: soil),
        ),
      ],
    );
  }
}
