import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static final String baseUrl = dotenv.env['API_BASE_URL'] ?? "";

  static Future<Map<String, dynamic>?> login(String email, String password) async {
    final url = Uri.parse('$baseUrl/Authenticate/login');
    try {
      final response = await http.post(url,
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({"email": email, "password": password}));
      if (response.statusCode == 200) return jsonDecode(response.body);
      return null;
    } catch (e) {
      return null;
    }
  }

  // Trả về null nếu thành công, ngược lại trả về thông báo lỗi
  static Future<String?> register(String name, String email, String password, String role) async {
    final url = Uri.parse('$baseUrl/Authenticate/register');
    try {
      final response = await http.post(url,
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({"name": name, "email": email, "password": password, "role": role}));
      print("register ${response.statusCode}: ${response.body}");
      if (response.statusCode == 200) return null;
      try {
        final body = jsonDecode(response.body);
        return body['message'] ?? body['Message'] ?? body['title'] ?? "Đăng ký thất bại (${response.statusCode})";
      } catch (_) {
        return "Server lỗi ${response.statusCode}";
      }
    } catch (e) {
      print("register error: $e");
      return "Không kết nối được server: $e";
    }
  }

  // Devices API
  static Future<List<dynamic>> getDevices() async {
    final url = Uri.parse('$baseUrl/DeviceApi');
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token') ?? '';
    final response = await http.get(url, headers: {"Authorization": "Bearer $token"});
    return response.statusCode == 200 ? jsonDecode(response.body) : [];
  }

  static Future<bool> addDevice(String name, String mac, String parentId) async {
    final url = Uri.parse('$baseUrl/DeviceApi');
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token') ?? '';
    final response = await http.post(url,
        headers: {"Content-Type": "application/json", "Authorization": "Bearer $token"},
        body: jsonEncode({"deviceName": name, "macAddress": mac, "parentId": int.tryParse(parentId) ?? 1}));
    return response.statusCode == 200 || response.statusCode == 201;
  }

  static Future<bool> deleteDevice(int id) async {
    final url = Uri.parse('$baseUrl/DeviceApi/$id');
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token') ?? '';
    final response = await http.delete(url, headers: {"Authorization": "Bearer $token"});
    return response.statusCode == 200;
  }

  static Future<Map<String, dynamic>?> getDeviceByMac(String mac) async {
    final url = Uri.parse('$baseUrl/DeviceApi/by-mac/${Uri.encodeComponent(mac)}');
    try {
      final response = await http.get(url);
      return response.statusCode == 200 ? jsonDecode(response.body) : null;
    } catch (e) {
      return null;
    }
  }

  // Children API
  static Future<List<dynamic>> getChildren() async {
    final url = Uri.parse('$baseUrl/ChildrenApi');
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token') ?? '';
    final response = await http.get(url, headers: {"Authorization": "Bearer $token"});
    return response.statusCode == 200 ? jsonDecode(response.body) : [];
  }

  static Future<bool> addChild(String name, int age, String avatar, String parentId) async {
    final url = Uri.parse('$baseUrl/ChildrenApi');
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token') ?? '';
    final response = await http.post(url,
        headers: {"Content-Type": "application/json", "Authorization": "Bearer $token"},
        body: jsonEncode({"name": name, "age": age, "avatar": avatar, "parentId": parentId}));
    return response.statusCode == 200 || response.statusCode == 201;
  }

  static Future<bool> deleteChild(int id) async {
    final url = Uri.parse('$baseUrl/ChildrenApi/$id');
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token') ?? '';
    final response = await http.delete(url, headers: {"Authorization": "Bearer $token"});
    return response.statusCode == 200;
  }

  // Rules API
  static Future<List<dynamic>> getRules() async {
    final url = Uri.parse('$baseUrl/RulesApi');
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token') ?? '';
    final response = await http.get(url, headers: {"Authorization": "Bearer $token"});
    return response.statusCode == 200 ? jsonDecode(response.body) : [];
  }

  static Future<bool> addRule(int deviceId, String startTime, String endTime, String blockedApps) async {
    final url = Uri.parse('$baseUrl/RulesApi');
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token') ?? '';
    final response = await http.post(url,
        headers: {"Content-Type": "application/json", "Authorization": "Bearer $token"},
        body: jsonEncode({"deviceId": deviceId, "startTime": startTime, "endTime": endTime, "blockedApps": blockedApps}));
    return response.statusCode == 200 || response.statusCode == 201;
  }

  static Future<bool> deleteRule(int id) async {
    final url = Uri.parse('$baseUrl/RulesApi/$id');
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token') ?? '';
    final response = await http.delete(url, headers: {"Authorization": "Bearer $token"});
    return response.statusCode == 200;
  }

  // Location API
  static Future<bool> sendLocation(int deviceId, double lat, double lng) async {
    final url = Uri.parse('$baseUrl/LocationApi');
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token') ?? '';
    final response = await http.post(url,
        headers: {"Content-Type": "application/json", "Authorization": "Bearer $token"},
        body: jsonEncode({"deviceId": deviceId, "latitude": lat, "longitude": lng}));
    print("sendLocation($deviceId) ${response.statusCode}: ${response.body}");
    return response.statusCode == 200 || response.statusCode == 201;
  }

  static Future<Map<String, dynamic>?> getLatestLocation(int deviceId) async {
    final url = Uri.parse('$baseUrl/LocationApi/latest/$deviceId');
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token') ?? '';
    final response = await http.get(url, headers: {"Authorization": "Bearer $token"});
    print("getLatestLocation($deviceId) ${response.statusCode}: ${response.body}");
    return response.statusCode == 200 ? jsonDecode(response.body) : null;
  }
}