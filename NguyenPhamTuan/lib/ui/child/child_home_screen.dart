import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/api_service.dart';
import '../login_screen.dart';

const _primary = Color(0xFF1976D2);

class ChildHomeScreen extends StatefulWidget {
  final String childEmail;
  const ChildHomeScreen({super.key, required this.childEmail});

  @override
  State<ChildHomeScreen> createState() => _ChildHomeScreenState();
}

class _ChildHomeScreenState extends State<ChildHomeScreen> {
  final String _deviceMac = "AA:BB:CC:11:22:33";
  final int _deviceId = 1;
  List<dynamic> _rules = [];
  bool _isLoading = true;
  String _locationStatus = "Đang lấy vị trí...";

  @override
  void initState() {
    super.initState();
    _loadRules();
    _updateLocation();
  }

  Future<void> _loadRules() async {
    setState(() => _isLoading = true);
    final data = await ApiService.getRules();
    setState(() {
      _rules = data;
      _isLoading = false;
    });
  }

  Future<void> _updateLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    await ApiService.sendLocation(_deviceId, position.latitude, position.longitude);
    setState(() {
      _locationStatus = "Đã gửi GPS: ${position.latitude.toStringAsFixed(3)}, ${position.longitude.toStringAsFixed(3)}";
    });
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Thiết bị con', style: TextStyle(color: Colors.white)), backgroundColor: _primary, actions: [
        IconButton(icon: const Icon(Icons.logout, color: Colors.white), onPressed: _logout)
      ]),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(child: Padding(padding: const EdgeInsets.all(16), child: Row(children: [
              const Icon(Icons.location_on, color: Colors.red, size: 36),
              const SizedBox(width: 12),
              Expanded(child: Text(_locationStatus, style: const TextStyle(fontWeight: FontWeight.bold)))
            ]))),
            const SizedBox(height: 20),
            QrImageView(data: _deviceMac, size: 180.0),
            Text("MAC: $_deviceMac", style: const TextStyle(color: Colors.grey)),
            const Divider(height: 30),
            const Align(alignment: Alignment.centerLeft, child: Text("Quy tắc giới hạn", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
            const SizedBox(height: 10),
            _isLoading ? const CircularProgressIndicator() : ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _rules.length,
              itemBuilder: (context, index) {
                final r = _rules[index];
                return Card(child: ListTile(title: Text("Khung giờ: ${r['startTime']} - ${r['endTime']}"), subtitle: Text("Cấm: ${r['blockedApps']}")));
              },
            )
          ],
        ),
      ),
    );
  }
}