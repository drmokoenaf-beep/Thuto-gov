import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'dart:io';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final cameras = await availableCameras();
  runApp(ThutoGovApp(cameras: cameras));
}

class ThutoGovApp extends StatelessWidget {
  final List<CameraDescription> cameras;
  const ThutoGovApp({super.key, required this.cameras});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Thuto Gov',
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      home: RegistrationScreen(cameras: cameras),
      debugShowCheckedModeBanner: false,
    );
  }
}

class RegistrationScreen extends StatefulWidget {
  final List<CameraDescription> cameras;
  const RegistrationScreen({super.key, required this.cameras});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _idController = TextEditingController();
  final _nameController = TextEditingController();
  String? _selectedDept = 'Education';
  String? _selectedPosition = 'Teacher';
  String? _selectedSupervisor = 'Principal';
  File? _faceImage;
  Position? _currentPosition;
  String _address = 'Fetching location...';
  bool _isLoadingLocation = false;

  final List<String> _departments = ['Education', 'Health', 'Public Works', 'Home Affairs', 'Finance'];
  final List<String> _positions = ['Teacher', 'Principal', 'HOD', 'Clerk', 'Manager', 'Director'];
  final List<String> _supervisors = ['Principal', 'Circuit Manager', 'District Director', 'HOD'];

  CameraController? _cameraController;
  bool _isCameraInitialized = false;

  @override
  void initState() {
    super.initState();
    _initCamera();
    _getCurrentLocation();
  }

  
Future<void> _initCamera() async {
  if (widget.cameras.isEmpty) return;

  final camera = widget.cameras.firstWhere(
    (c) => c.lensDirection == CameraLensDirection.front,
    orElse: () => widget.cameras.first,
  );

  try {
    final controller = CameraController(
      camera,
      ResolutionPreset.medium,
    );

    _cameraController = controller;
    await controller.initialize();

    if (mounted) {
      setState(() => _isCameraInitialized = true);
    }
  } catch (e) {
    debugPrint('Camera initialization failed: $e');
  }
}


  Future<void> _getCurrentLocation() async {
    setState(() => _isLoadingLocation = true);
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      Position pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      List<Placemark> placemarks = await placemarkFromCoordinates(pos.latitude, pos.longitude);
      setState(() {
        _currentPosition = pos;
        _address = placemarks.isNotEmpty
            ? '${placemarks[0].street}, ${placemarks[0].locality}'
            : '${pos.latitude}, ${pos.longitude}';
        _isLoadingLocation = false;
      });
    } catch (e) {
      setState(() {
        _address = 'Location permission needed';
        _isLoadingLocation = false;
      });
    }
  }

  Future<void> _takePicture() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) return;
    final XFile file = await _cameraController!.takePicture();
    setState(() => _faceImage = File(file.path));
  }

  void _submit() {
    if (_formKey.currentState!.validate() && _faceImage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'THUTO GOV Registered: ${_nameController.text} | ID: ${_idController.text} | $_address',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } else if (_faceImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please capture Face Photo!'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'THUTO GOV - DR MOKOENA',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        backgroundColor: Colors.blue[900],
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                color: Colors.blue[50],
                child: Column(
                  children: [
                    const Text(
                      'Government Accountability - ID+Face+Position',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Position: $_address',
                      style: const TextStyle(fontSize: 12),
                    ),
                    if (_isLoadingLocation) const LinearProgressIndicator(),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (v) => v == null || v.trim().isEmpty ? 'Enter your name' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _idController,
                decoration: const InputDecoration(
                  labelText: 'ID Number (13 digits)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.badge),
                ),
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Enter ID number';
                  if (v.trim().length != 13) return 'ID must be 13 digits';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedDept,
                items: _departments
                    .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                    .toList(),
                onChanged: (v) => setState(() => _selectedDept = v),
                decoration: const InputDecoration(
                  labelText: 'Department',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedPosition,
                items: _positions
                    .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                    .toList(),
                onChanged: (v) => setState(() => _selectedPosition = v),
                decoration: const InputDecoration(
                  labelText: 'Position',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedSupervisor,
                items: _supervisors
                    .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                    .toList(),
                onChanged: (v) => setState(() => _selectedSupervisor = v),
                decoration: const InputDecoration(
                  labelText: 'Supervisor',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Face Verification',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Container(
                height: 250,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: _faceImage != null
                    ? Image.file(_faceImage!, fit: BoxFit.cover)
                    : _isCameraInitialized
                        ? CameraPreview(_cameraController!)
                        : const Center(child: CircularProgressIndicator()),
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: _takePicture,
                icon: const Icon(Icons.camera_alt),
                label: const Text('CAPTURE FACE'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[900],
                  foregroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[700],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(16),
                ),
                child: const Text('REGISTER'),
              ),
              const SizedBox(height: 8),
              Text(
                'Lat: ${_currentPosition?.latitude} | Lng: ${_currentPosition?.longitude}',
                style: const TextStyle(fontSize: 10, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
