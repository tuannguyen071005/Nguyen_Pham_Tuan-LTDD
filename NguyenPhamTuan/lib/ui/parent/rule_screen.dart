import 'package:flutter/material.dart';
import '../../../services/api_service.dart';

const _primary = Color(0xFF1976D2);

class RuleScreen extends StatefulWidget {
  const RuleScreen({super.key});

  @override
  State<RuleScreen> createState() => _RuleScreenState();
}

class _RuleScreenState extends State<RuleScreen> {
  List<dynamic> _rules = [];
  List<dynamic> _devices = []; // Danh sách thiết bị
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // Tải đồng thời cả quy tắc và danh sách thiết bị
  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final rulesData = await ApiService.getRules();
    final devicesData = await ApiService.getDevices();
    setState(() {
      _rules = rulesData;
      _devices = devicesData;
      _isLoading = false;
    });
  }

  // Hiển thị Popup thêm quy tắc mới
  Future<void> _showAddRuleDialog() async {
    if (_devices.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Vui lòng quét mã QR để thêm thiết bị trước khi tạo quy tắc!")),
      );
      return;
    }

    int selectedDeviceId = _devices[0]['id'];
    final startController = TextEditingController(text: "19:00:00");
    final endController = TextEditingController(text: "21:00:00");
    final appsController = TextEditingController(text: "youtube,tiktok");

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: const Text("Thêm khung giờ & cấm ứng dụng"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Chọn thiết bị áp dụng:", style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                DropdownButtonFormField<int>(
                  value: selectedDeviceId,
                  decoration: const InputDecoration(border: OutlineInputBorder()),
                  items: _devices.map<DropdownMenuItem<int>>((device) {
                    return DropdownMenuItem<int>(
                      value: device['id'],
                      child: Text(device['deviceName'] ?? "Thiết bị ${device['id']}"),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    if (newValue != null) {
                      setStateDialog(() => selectedDeviceId = newValue);
                    }
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: startController,
                  decoration: const InputDecoration(labelText: "Giờ bắt đầu (HH:mm:ss)", border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: endController,
                  decoration: const InputDecoration(labelText: "Giờ kết thúc (HH:mm:ss)", border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: appsController,
                  decoration: const InputDecoration(labelText: "App cấm (phân cách bằng dấu phẩy)", border: OutlineInputBorder()),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, null),
              child: const Text("Hủy", style: TextStyle(color: Colors.red)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: _primary, foregroundColor: Colors.white),
              onPressed: () {
                Navigator.pop(ctx, {
                  "deviceId": selectedDeviceId,
                  "start": startController.text.trim(),
                  "end": endController.text.trim(),
                  "apps": appsController.text.trim(),
                });
              },
              child: const Text("Lưu"),
            ),
          ],
        ),
      ),
    );

    if (result != null) {
      bool success = await ApiService.addRule(
        result["deviceId"],
        result["start"],
        result["end"],
        result["apps"],
      );

      if (success) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Thêm quy tắc thành công!")));
        _loadData(); // 🔥 Load lại ngay lập tức
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Lỗi khi thêm quy tắc")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _rules.isEmpty
          ? const Center(child: Text("Chưa có quy tắc nào được thiết lập."))
          : ListView.builder(
        itemCount: _rules.length,
        itemBuilder: (context, index) {
          final rule = _rules[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              leading: const Icon(Icons.access_time_filled, color: _primary, size: 40),
              title: Text("Khung giờ: ${rule['startTime']} - ${rule['endTime']}", style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text("Thiết bị ID: ${rule['deviceId']} | App cấm: ${rule['blockedApps']}"),
              trailing: IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () async {
                  bool success = await ApiService.deleteRule(rule['id']);
                  if (!mounted) return;
                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Đã xóa quy tắc!")));
                    _loadData();
                  }
                },
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        onPressed: _showAddRuleDialog,
        icon: const Icon(Icons.add),
        label: const Text("Thêm quy tắc"),
      ),
    );
  }
}