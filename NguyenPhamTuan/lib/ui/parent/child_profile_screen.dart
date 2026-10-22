import 'package:flutter/material.dart';
import '../../../services/api_service.dart';

const _primary = Color(0xFF1976D2);

class ChildProfileScreen extends StatefulWidget {
  const ChildProfileScreen({super.key});

  @override
  State<ChildProfileScreen> createState() => _ChildProfileScreenState();
}

class _ChildProfileScreenState extends State<ChildProfileScreen> {
  List<dynamic> _children = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadChildren();
  }

  Future<void> _loadChildren() async {
    setState(() => _isLoading = true);
    final data = await ApiService.getChildren();
    setState(() {
      _children = data;
      _isLoading = false;
    });
  }

  // Hiển thị Popup thêm con
  void _showAddChildDialog() {
    TextEditingController nameController = TextEditingController();
    TextEditingController ageController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog( // 🔥 Đổi thành dialogContext để phân biệt với context của màn hình chính
        title: const Text("Thêm hồ sơ con"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: "Tên của con (VD: Nguyễn Văn Tí)", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: ageController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Tuổi", border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext), // Đóng bằng dialogContext
            child: const Text("Hủy", style: TextStyle(color: Colors.red)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _primary, foregroundColor: Colors.white),
            onPressed: () async {
              if (nameController.text.trim().isEmpty || ageController.text.trim().isEmpty) return;

              String childName = nameController.text.trim();
              int age = int.tryParse(ageController.text.trim()) ?? 6;

              // 1. Đóng popup trước bằng dialogContext riêng biệt
              Navigator.pop(dialogContext);

              // 2. Gọi API thêm hồ sơ trẻ em lên Backend C#
              bool success = await ApiService.addChild(
                  childName,
                  age,
                  "default_avatar.png",
                  "1" // Hoặc truyền ID/Email của phụ huynh
              );

              // 3. Kiểm tra xem màn hình chính còn tồn tại không
              if (!mounted) return;

              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Thêm hồ sơ thành công!")));

                // 🔥 Gọi lại hàm load danh sách trẻ - Chắc chắn sẽ render lại UI ngay lập tức!
                _loadChildren();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Lỗi khi thêm hồ sơ")));
              }
            },
            child: const Text("Lưu"),
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
          : _children.isEmpty
          ? const Center(child: Text("Chưa có hồ sơ trẻ em nào được tạo."))
          : ListView.builder(
        itemCount: _children.length,
        itemBuilder: (context, index) {
          final child = _children[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              leading: const CircleAvatar(
                backgroundColor: _primary,
                child: Icon(Icons.child_care, color: Colors.white),
              ),
              title: Text(child['name'] ?? "Không tên", style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text("Tuổi: ${child['age']}"),
              trailing: IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () async {
                  // 1. Hiện hộp thoại xác nhận xóa
                  bool? confirm = await showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text("Xác nhận xóa"),
                      content: Text("Bạn có chắc chắn muốn xóa hồ sơ của ${child['name']} không?"),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text("Hủy"),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text("Xóa"),
                        ),
                      ],
                    ),
                  );

                  // 2. Nếu bấm Xóa -> Gọi API
                  if (confirm == true) {
                    int childId = child['id'];
                    bool success = await ApiService.deleteChild(childId);

                    if (!mounted) return;

                    if (success) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Đã xóa hồ sơ thành công!")),
                      );
                      _loadChildren(); // Tải lại danh sách
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Xóa hồ sơ thất bại!")),
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
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        onPressed: _showAddChildDialog,
        icon: const Icon(Icons.add),
        label: const Text("Thêm hồ sơ con"),
      ),
    );
  }
}