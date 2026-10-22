import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:nguyenphamtuan/ui/parent/parent_home_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import '../services/api_service.dart';
import 'child/child_home_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final LocalAuthentication _auth = LocalAuthentication();
  bool _isLoading = false;
  bool _obscure = true;

  Future<void> _handleLogin() async {
    setState(() {
      _isLoading = true;
    });

    // 1. Gọi API Đăng nhập
    final response = await ApiService.login(
      _emailController.text.trim(),
      _passwordController.text.trim(),
    );

    setState(() {
      _isLoading = false;
    });

    if (response != null && response['token'] != null) {
      String token = response['token'];

      // 2. Lưu token vào SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('jwt_token', token);
      await prefs.setString('bio_token', token);

      // 3. Giải mã JWT để lấy Role
      Map<String, dynamic> decodedToken = JwtDecoder.decode(token);

      // Lưu ý: Trong ASP.NET Core Identity, claim Role thường có key rất dài
      // Nếu backend trả về key là 'role' thì dùng decodedToken['role']
      String role = decodedToken['http://schemas.microsoft.com/ws/2008/06/identity/claims/role']
          ?? decodedToken['role'] ?? "User";

      // 4. Phân quyền người dùng (Điều hướng)
      if (!mounted) return;

      if (role == 'Admin') {
        _showMsg("Chào mừng Admin");
      } else if (role == 'Parent') {
        Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (_) => ParentHomeScreen( // Bỏ chữ 'const' ở đây
                    parentEmail: _emailController.text.trim()
                )
            )
        );
      } else if (role == 'Child') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => ChildHomeScreen(childEmail: _emailController.text.trim())),
        );
      } else {
        _showMsg("Đăng nhập thành công nhưng không rõ Role: $role");
      }
    }
  }

  void _showMsg(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _authenticateWithBiometrics() async {
    try {
      // 1. Kiểm tra xem thiết bị có hỗ trợ vân tay/khuôn mặt hay không
      bool canCheckBiometrics = await _auth.canCheckBiometrics;
      bool isSupported = await _auth.isDeviceSupported();

      if (!canCheckBiometrics && !isSupported) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Thiết bị này không hỗ trợ bảo mật sinh trắc học!")),
        );
        return;
      }

      // 2. Bật hộp thoại quét vân tay của hệ thống điện thoại
      bool didAuthenticate = await _auth.authenticate(
        localizedReason: 'Xác thực vân tay để đăng nhập ứng dụng',
        options: const AuthenticationOptions(
          biometricOnly: true, // Chỉ dùng vân tay/khuôn mặt, không dùng mã PIN phụ
          stickyAuth: true,
        ),
      );

      // 3. Nếu quét thành công
      if (didAuthenticate) {
        // Kiểm tra xem trước đó đã lưu token hoặc email nào chưa
        final prefs = await SharedPreferences.getInstance();
        final savedToken = prefs.getString('bio_token');

        if (savedToken != null && savedToken.isNotEmpty) {
          // Giải mã token cũ để lấy role và chuyển hướng luôn
          if (JwtDecoder.isExpired(savedToken)) {
            if (!mounted) return;
            _showMsg("Phiên đã hết hạn, vui lòng đăng nhập lại bằng mật khẩu");
            return;
          }
          await prefs.setString('jwt_token', savedToken); // khôi phục token cho ApiService
          Map<String, dynamic> decodedToken = JwtDecoder.decode(savedToken);
          String role = decodedToken['http://schemas.microsoft.com/ws/2008/06/identity/claims/role'] ?? 'Parent';
          String email = decodedToken['http://schemas.xmlsoap.org/ws/2005/05/identity/claims/name'] ?? 'user@gmail.com';

          if (!mounted) return;
          if (role.toLowerCase() == 'child') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => ChildHomeScreen(childEmail: email)),
            );
          } else {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => ParentHomeScreen(parentEmail: email)),
            );
          }
        } else {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Vui lòng đăng nhập bằng mật khẩu ít nhất 1 lần trước khi dùng vân tay!")),
          );
        }
      }
    } catch (e) {
      print("Lỗi sinh trắc học: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Đăng nhập hệ thống")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.only(top: 60),
          children: [
            // Ô nhập email & password hiện tại của bạn...
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: "Email"),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _passwordController,
              obscureText: _obscure,
              decoration: InputDecoration(
                labelText: "Mật khẩu",
                suffixIcon: IconButton(
                  icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Nút đăng nhập thường
            ElevatedButton(
              onPressed: _handleLogin,
              child: const Text("Đăng nhập"),
            ),
            TextButton(
              onPressed: () => Navigator.push(
                  context, MaterialPageRoute(builder: (_) => const RegisterScreen())),
              child: const Text("Chưa có tài khoản? Đăng ký"),
            ),

            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),

            // 🔥 NÚT BẤM ĐĂNG NHẬP BẰNG VÂN TAY (Chức năng nâng cao 5.a)
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              onPressed: _authenticateWithBiometrics,
              icon: const Icon(Icons.fingerprint, size: 28, color: Color(0xFF1976D2)),
              label: const Text(
                "Đăng nhập bằng vân tay / Sinh trắc học",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}