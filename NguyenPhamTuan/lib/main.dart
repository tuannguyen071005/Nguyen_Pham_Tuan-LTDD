import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'ui/login_screen.dart'; // Import file vừa tạo

Future<void> main() async {
  await dotenv.load(fileName: ".env");
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Quản lý trẻ em',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const LoginScreen(), // Đặt Login làm màn hình chính
      debugShowCheckedModeBanner: false,
    );
  }
}