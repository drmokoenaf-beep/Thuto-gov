
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const String supabaseUrl =
    'https://uqmjkehzirlqpktwcdhh.supabase.co';

// Replace this placeholder with your complete sb_publishable_ key.
const String supabasePublishableKey =
    'PASTE_YOUR_FULL_SB_PUBLISHABLE_KEY_HERE';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: supabaseUrl,
    publishableKey: supabasePublishableKey,
  );

  List<CameraDescription> cameras = [];

  try {
    cameras = await availableCameras();
  } catch (e) {
    debugPrint('Camera unavailable: $e');
  }

  runApp(ThutoGovApp(cameras: cameras));
}

class ThutoGovApp extends StatelessWidget {
  final List<CameraDescription> cameras;

  const ThutoGovApp({super.key, required this.cameras});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Thuto Gov - Dr Mokoena',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: AuthScreen(cameras: cameras),
    );
  }
}

class AuthScreen extends StatefulWidget {
  final List<CameraDescription> cameras;

  const AuthScreen({super.key, required this.cameras});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _idController = TextEditingController();

  bool _isLogin = false;
  bool _loading = false;
  bool _obscurePassword = true;

  String? _department = 'Education';
  String? _position = 'Teacher';
  String? _supervisor = 'Principal';

  File? _faceImage;
  CameraController? _cameraController;
  bool _cameraReady = false;

  Position? _currentPosition;
  String _address = 'Location not yet retrieved';
  bool _gettingLocation = false;

  final List<String> _departments = [
    'Education',
    'Health',
    'Public Works',
    'Home Affairs',
    'Finance',
  ];

  final List<String> _positions = [
    'Teacher',
    'Principal',
    'HOD',
    'Clerk',
    'Manager',
    'Director',
  ];

  final List<String> _supervisors = [
    'Principal',
    'Circuit Manager',
    'District Director',
    'HOD',
  ];

  SupabaseClient get _supabase => Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _getCurrentLocation();
  }

  Future<void> _initializeCamera() async {
    if (widget.cameras.isEmpty) return;

    final camera = widget.cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.front,
      orElse: () => widget.cameras.first,
    );

    final controller = CameraController(
      camera,
      ResolutionPreset.medium,
      enableAudio: false,
    );

    try {
      await controller.initialize();

      if (!mounted) {
        await controller.dispose();
        return;
      }

      _cameraController = controller;
      setState(() => _cameraReady = true);
    } catch (e) {
      await controller.dispose();
      debugPrint('Camera initialization failed: $e');
    }
  }

  Future<void> _getCurrentLocation() async {
    if (!mounted) return;
    setState(() => _gettingLocation = true);

    try {
      bool enabled = await Geolocator.isLocationServiceEnabled();

      if (!enabled) {
        throw Exception('Please enable your phone location service.');
      }

      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw Exception('Location permission was not granted.');
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      String address = 
          '${position.latitude}, ${position.longitude}';

      try {
        final placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );

        if (placemarks.isNotEmpty) {
          final place = placemarks.first;
          final parts = [
            place.street,
            place.locality,
            place.administrativeArea,
          ].where((part) => part != null && part.trim().isNotEmpty);

          if (parts.isNotEmpty) {
            address = parts.join(', ');
          }
        }
      } catch (_) {
        // Coordinates remain available if reverse geocoding fails.
      }

      if (!mounted) return;

      setState(() {
        _currentPosition = position;
        _address = address;
        _gettingLocation = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _address = 'Location unavailable: $e';
        _gettingLocation = false;
      });
    }
  }

  Future<void> _takePicture() async {
    final controller = _cameraController;

    if (controller == null || !controller.value.isInitialized) {
      _showMessage('Camera is not available. Check camera permission.');
      return;
    }

    try {
      final picture = await controller.takePicture();

      if (!mounted) return;

      setState(() => _faceImage = File(picture.path));
    } catch (e) {
      _showMessage('Could not capture photo: $e');
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _ensureUserProfile(User user) async {
    final existing = await _supabase
        .from('profiles')
        .select('id')
        .eq('id', user.id)
        .maybeSingle();

    if (existing != null) return;

    final metadata = user.userMetadata ?? {};

    await _supabase.from('profiles').insert({
      'id': user.id,
      'email': user.email,
      'full_name': (metadata['full_name'] as String?) ?? '',
      'id_number': metadata['id_number'],
      'position': metadata['position'],
      'role': 'user',
      'face_verified': false,
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_isLogin && _faceImage == null) {
      _showMessage('Please capture your face photo to continue.');
      return;
    }

    if (_isLogin) {
      await _login();
    } else {
      await _createAccount();
    }
  }

  Future<void> _createAccount() async {
    setState(() => _loading = true);

    try {
      final response = await _supabase.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        data: {
          'full_name': _nameController.text.trim(),
          'id_number': _idController.text.trim(),
          'position': _position,
        },
      );

      final user = response.user;

      if (user == null) {
        throw Exception('Account creation did not return a user.');
      }

      // Create the profile directly only when a session exists.
      // If email confirmation is required, create it after login.
      if (response.session != null) {
        await _ensureUserProfile(user);
      }

      if (!mounted) return;

      setState(() => _isLogin = true);

      _showMessage(
        response.session == null
            ? 'Account created. Check your email to confirm it, then log in.'
            : 'Account created successfully. Please log in.',
      );
    } on AuthException catch (e) {
      _showMessage('Account creation failed: ${e.message}');
    } on PostgrestException catch (e) {
      _showMessage(
        'Account was created, but profile setup failed. '
        'Check profiles RLS policies: ${e.message}',
      );
    } catch (e) {
      _showMessage('Could not create account: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _login() async {
    setState(() => _loading = true);

    try {
      final response = await _supabase.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      final user = response.user;

      if (user == null) {
        throw Exception('Login did not return a user.');
      }

      await _ensureUserProfile(user);

      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => AccountHomeScreen(
            cameras: widget.cameras,
          ),
        ),
      );
    } on AuthException catch (e) {
      _showMessage('Login failed: ${e.message}');
    } on PostgrestException catch (e) {
      _showMessage(
        'Login succeeded, but profile access failed. '
        'Check profiles RLS policies: ${e.message}',
      );
    } catch (e) {
      _showMessage('Could not log in: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _idController.dispose();
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('THUTO GOV - DR MOKOENA'),
        backgroundColor: Colors.green.shade800,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  _isLogin ? 'LOGIN' : 'CREATE ACCOUNT',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Government Accountability - Dr Mokoena Institution',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),

                if (!_isLogin) ...[
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Full Name',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person),
                    ),
                    validator: (value) {
                      if (!_isLogin &&
                          (value == null || value.trim().isEmpty)) {
                        return 'Enter your full name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                ],

                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email Address',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email),
                  ),
                  validator: (value) {
                    if (value == null ||
                        !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                            .hasMatch(value.trim())) {
                      return 'Enter a valid email address';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      onPressed: () => setState(
                        () => _obscurePassword = !_obscurePassword,
                      ),
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.length < 8) {
                      return 'Password must be at least 8 characters';
                    }
                    return null;
                  },
                ),

                if (!_isLogin) ...[
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _idController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'South African ID Number (13 digits)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.badge),
                    ),
                    validator: (value) {
                      if (!_isLogin &&
                          (value == null ||
                              !RegExp(r'^\d{13}$').hasMatch(value.trim()))) {
                        return 'Enter a 13-digit ID number';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),

                  DropdownButtonFormField<String>(
                    value: _department,
                    decoration: const InputDecoration(
                      labelText: 'Department',
                      border: OutlineInputBorder(),
                    ),
                    items: _departments
                        .map((item) => DropdownMenuItem(
                              value: item,
                              child: Text(item),
                            ))
                        .toList(),
                    onChanged: (value) =>
                        setState(() => _department = value),
                  ),
                  const SizedBox(height: 12),

                  DropdownButtonFormField<String>(
                    value: _position,
                    decoration: const InputDecoration(
                      labelText: 'Position',
                      border: OutlineInputBorder(),
                    ),
                    items: _positions
                        .map((item) => DropdownMenuItem(
                              value: item,
                              child: Text(item),
                            ))
                        .toList(),
                    onChanged: (value) =>
                        setState(() => _position = value),
                  ),
                  const SizedBox(height: 12),

                  DropdownButtonFormField<String>(
                    value: _supervisor,
                    decoration: const InputDecoration(
                      labelText: 'Supervisor',
                      border: OutlineInputBorder(),
                    ),
                    items: _supervisors
                        .map((item) => DropdownMenuItem(
                              value: item,
                              child: Text(item),
                            ))
                        .toList(),
                    onChanged: (value) =>
                        setState(() => _supervisor = value),
                  ),
                  const SizedBox(height: 20),

                  const Text(
                    'Face Photo',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),

                  SizedBox(
                    height: 220,
                    child: _faceImage != null
                        ? Image.file(_faceImage!, fit: BoxFit.cover)
                        : _cameraReady &&
                                _cameraController != null
                            ? CameraPreview(_cameraController!)
                            : const Center(
                                child: Text(
                                  'Camera unavailable. Check permissions.',
                                ),
                              ),
                  ),
                  const SizedBox(height: 8),

                  ElevatedButton.icon(
                    onPressed: _takePicture,
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('CAPTURE FACE PHOTO'),
                  ),

                  const SizedBox(height: 16),
                  const Text(
                    'GPS Location',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(_address),
                  if (_gettingLocation)
                    const LinearProgressIndicator(),
                  TextButton.icon(
                    onPressed: _gettingLocation
                        ? null
                        : _getCurrentLocation,
                    icon: const Icon(Icons.location_on),
                    label: const Text('REFRESH LOCATION'),
                  ),
                ],

                const SizedBox(height: 20),

                ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade800,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.all(16),
                  ),
                  child: _loading
                      ? const CircularProgressIndicator(
                          color: Colors.white,
                        )
                      : Text(_isLogin ? 'LOGIN' : 'CREATE ACCOUNT'),
                ),

                const SizedBox(height: 8),

                TextButton(
                  onPressed: _loading
                      ? null
                      : () => setState(() => _isLogin = !_isLogin),
                  child: Text(
                    _isLogin
                        ? 'New user? Create an account'
                        : 'Already registered? Log in',
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

class AccountHomeScreen extends StatelessWidget {
  final List<CameraDescription> cameras;

  const AccountHomeScreen({
    super.key,
    required this.cameras,
  });

  Future<void> _logout(BuildContext context) async {
    await Supabase.instance.client.auth.signOut();

    if (!context.mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => AuthScreen(cameras: cameras),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('THUTO GOV'),
        backgroundColor: Colors.green.shade800,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Log out',
            onPressed: () => _logout(context),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.verified_user,
                size: 64,
                color: Colors.green,
              ),
              const SizedBox(height: 16),
              const Text(
                'You are logged in to Thuto Gov.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(user?.email ?? ''),
              const SizedBox(height: 12),
              const Text(
                'Account access is connected. '
                'Supervisor Dashboard, attendance, classrooms, '
                'and private marks still need to be connected '
                'to their respective screens.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () => _logout(context),
                icon: const Icon(Icons.logout),
                label: const Text('LOG OUT'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
