import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../services/api_service.dart';

const _primary = Color(0xFF1976D2);

class LocationTrackingScreen extends StatefulWidget {
  const LocationTrackingScreen({super.key});

  @override
  State<LocationTrackingScreen> createState() => _LocationTrackingScreenState();
}

class _LocationTrackingScreenState extends State<LocationTrackingScreen> {
  List<dynamic> _devices = [];
  int? _selectedDeviceId;
  LatLng? _currentPosition;
  bool _isLoading = true;
  final MapController _mapController = MapController();
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _timer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (_selectedDeviceId != null) _fetchLocation(_selectedDeviceId!, silent: true);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    final devices = await ApiService.getDevices();
    setState(() {
      _devices = devices;
      if (_devices.isNotEmpty) {
        // Nếu danh sách mới không chứa thiết bị đang chọn, reset lại
        if (!_devices.any((d) => d['id'] == _selectedDeviceId)) {
          _selectedDeviceId = _devices[0]['id'];
        }
      } else {
        _selectedDeviceId = null;
      }
    });

    if (_selectedDeviceId != null) {
      await _fetchLocation(_selectedDeviceId!);
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchLocation(int deviceId, {bool silent = false}) async {
    if (!silent) setState(() => _isLoading = true);
    final locData = await ApiService.getLatestLocation(deviceId);
    if (!mounted) return;
    if (locData != null) {
      final pos = LatLng((locData['latitude'] as num).toDouble(), (locData['longitude'] as num).toDouble());
      setState(() { _currentPosition = pos; _isLoading = false; });
      _mapController.move(pos, 15.0);
    } else {
      setState(() { _currentPosition = const LatLng(10.7769, 106.7009); _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _devices.isEmpty
          ? const Center(child: Text("Chưa có thiết bị nào"))
          : Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(initialCenter: _currentPosition ?? const LatLng(10.7769, 106.7009), initialZoom: 15.0),
            children: [
              TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', userAgentPackageName: 'com.example.nguyenphamtuan'),
              if (_currentPosition != null) MarkerLayer(markers: [Marker(point: _currentPosition!, width: 50, height: 50, child: const Icon(Icons.location_on, color: Colors.red, size: 45))])
            ],
          ),
          Positioned(
            top: 16, left: 16, right: 16,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: DropdownButton<int>(
                  value: _selectedDeviceId,
                  isExpanded: true,
                  underline: const SizedBox(),
                  items: _devices.map<DropdownMenuItem<int>>((dev) => DropdownMenuItem(value: dev['id'], child: Text(dev['deviceName']))).toList(),
                  onChanged: (id) {
                    if (id != null) {
                      setState(() => _selectedDeviceId = id);
                      _fetchLocation(id);
                    }
                  },
                ),
              ),
            ),
          )
        ],
      ),
      // Bổ sung nút bấm làm mới dữ liệu
      floatingActionButton: FloatingActionButton(
        backgroundColor: _primary,
        onPressed: _loadInitialData,
        child: const Icon(Icons.refresh, color: Colors.white),
      ),
    );
  }
}