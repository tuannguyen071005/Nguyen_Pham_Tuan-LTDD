import 'package:flutter/material.dart';
import 'package:nguyenphamtuan/ui/parent/qr_scanner_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/api_service.dart';
import '../login_screen.dart';
import 'child_profile_screen.dart';
import 'rule_screen.dart';
import 'location_tracking_screen.dart';

const _primary = Color(0xFF1976D2); // Màu xanh dương chuẩn Material

class ParentHomeScreen extends StatefulWidget {
  final String parentEmail; // Lấy email từ lúc đăng nhập truyền sang

  const ParentHomeScreen({super.key, required this.parentEmail});

  @override
  State<ParentHomeScreen> createState() => _ParentHomeScreenState();
}

class _ParentHomeScreenState extends State<ParentHomeScreen> {
  int _index = 0;

  // Khai báo danh sách các màn hình
  late final List<Widget> _pages = [
    DeviceManageScreen(onGoto: _goto), // Màn hình Quản lý thiết bị (Code ở bên dưới)
    const ChildProfileScreen(), // Chỗ để làm CRUD Child
    const RuleScreen(), // Chỗ để làm CRUD Rule
    const LocationTrackingScreen(), // Chỗ làm Bản đồ (Tính năng nâng cao)
    const _Placeholder('Thông báo & Cảnh báo'),
  ];

  // Khai báo Menu
  static const _menu = [
    (Icons.smartphone, 'Thiết bị của con'),
    (Icons.child_care, 'Hồ sơ trẻ em'),
    (Icons.rule_folder_outlined, 'Thiết lập Quy tắc'),
    (Icons.location_on_outlined, 'Định vị & Theo dõi'),
    (Icons.notifications_none, 'Thông báo'),
  ];

  void _goto(int i) => setState(() => _index = i);

  // Xử lý Đăng xuất
  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token'); // Xóa token

    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
          (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        title: Text(_menu[_index].$2),
      ),
      drawer: Drawer(
        child: Column(children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(color: _primary),
            currentAccountPicture: const CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.person, color: _primary, size: 40)),
            accountName: const Text("Phụ huynh"),
            accountEmail: Text(widget.parentEmail), // Hiển thị email
          ),
          Expanded(
            child: ListView(padding: EdgeInsets.zero, children: [
              for (var i = 0; i < _menu.length; i++)
                ListTile(
                  leading: Icon(_menu[i].$1, color: i == _index ? _primary : null),
                  title: Text(_menu[i].$2,
                      style: TextStyle(
                        fontWeight: i == _index ? FontWeight.bold : FontWeight.normal,
                        color: i == _index ? _primary : Colors.black87,
                      )),
                  selected: i == _index,
                  selectedTileColor: _primary.withOpacity(.08),
                  onTap: () {
                    Navigator.pop(context); // Đóng drawer
                    _goto(i); // Chuyển trang
                  },
                ),
            ]),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Đăng xuất', style: TextStyle(color: Colors.red)),
            onTap: _logout,
          ),
        ]),
      ),
      // IndexedStack giúp giữ nguyên state của các màn hình khi chuyển tab
      body: IndexedStack(index: _index, children: _pages),
    );
  }
}

// =====================================================================
// MÀN HÌNH 1: QUẢN LÝ THIẾT BỊ (Được tách riêng ra thành Widget)
// =====================================================================
class DeviceManageScreen extends StatefulWidget {
  final Function(int) onGoto;
  const DeviceManageScreen({super.key, required this.onGoto});

  @override
  State<DeviceManageScreen> createState() => _DeviceManageScreenState();
}

class _DeviceManageScreenState extends State<DeviceManageScreen> {
  List<dynamic> _devices = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDevices();
  }

  Future<void> _loadDevices() async {
    setState(() => _isLoading = true);
    final data = await ApiService.getDevices();
    setState(() {
      _devices = data;
      _isLoading = false;
    });
  }

  // 1. Hàm mở màn hình quét QR
  Future<void> _scanQRCode() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const QrScannerScreen()),
    );

    // 2. Nếu quét thành công có mã MAC trả về -> Hiện Popup nhập tên
    if (result != null) {
      _showAddDeviceDialog(result.toString());
    }
  }

  /// 3. Popup nhập tên thiết bị sau khi quét (Đã sửa lại để bắt chính xác context màn hình cha)
  void _showAddDeviceDialog(String macAddress) {
    TextEditingController nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Thêm thiết bị mới"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Đã quét được mã MAC:\n$macAddress", style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: "Tên thiết bị (VD: iPad của Tí)",
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text("Hủy", style: TextStyle(color: Colors.red))
          ),

          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1976D2), foregroundColor: Colors.white),
            onPressed: () async {
              if (nameController.text.trim().isEmpty) return;

              String deviceName = nameController.text.trim();

              // 1. Đóng popup trước bằng dialogContext riêng biệt
              Navigator.pop(dialogContext);

              // 2. Gọi API thêm thiết bị lên Backend C#
              bool success = await ApiService.addDevice(
                  deviceName,
                  macAddress,
                  "1" // ID phụ huynh (Tạm fix để test)
              );

              // 3. Kiểm tra xem màn hình chính còn sống không
              if (!mounted) return;

              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Thêm máy thành công!"))
                );

                // 🔥 GỌI LẠI HÀM LOAD DANH SÁCH - Lần này chắc chắn sẽ ăn vì dùng context của widget cha!
                _loadDevices();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Lỗi khi thêm thiết bị"))
                );
              }
            },
            child: const Text("Lưu thiết bị"),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _devices.isEmpty
          ? const Center(child: Text("Chưa có thiết bị nào. Hãy thêm mới!"))
          : ListView.builder(
        itemCount: _devices.length,
        itemBuilder: (context, index) {
          final device = _devices[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              leading: const Icon(Icons.smartphone, color: Color(0xFF1976D2), size: 40),
              title: Text(device['deviceName'] ?? "Không tên", style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text("MAC: ${device['macAddress']}"),
              trailing: IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () async {
                  // 1. Hiện hộp thoại hỏi lại người dùng cho chắc chắn
                  bool? confirm = await showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text("Xác nhận xóa"),
                      content: const Text("Bạn có chắc chắn muốn xóa thiết bị này không?"), // <-- Thêm chữ 'content:' vào đây
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text("Hủy"),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text("Xóa"),
                        ),
                      ],
                    ),
                  );

                  // 2. Nếu người dùng bấm "Xóa"
                  if (confirm == true) {
                    // Lấy ID của thiết bị (đảm bảo key 'id' khớp với JSON trả về từ C# API)
                    int deviceId = device['id'];

                    // Gọi API xóa thiết bị
                    bool success = await ApiService.deleteDevice(deviceId);

                    if (success) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Đã xóa thiết bị thành công!")),
                      );
                      _loadDevices(); // Tải lại danh sách thiết bị
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Xóa thiết bị thất bại!")),
                      );
                    }
                  }
                },
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF1976D2),
        foregroundColor: Colors.white,
        onPressed: _scanQRCode, // Thay bằng nút gọi hàm quét QR
        icon: const Icon(Icons.qr_code_scanner),
        label: const Text("Quét mã thêm máy"),
      ),
    );
  }
}

// =====================================================================
// WIDGET TẠM THỜI (Dành cho các màn hình chưa làm)
// =====================================================================
class _Placeholder extends StatelessWidget {
  final String name;
  const _Placeholder(this.name);

  @override
  Widget build(BuildContext context) =>
      Center(child: Text('$name (đang xây dựng)', style: const TextStyle(fontSize: 18, color: Colors.grey)));
}