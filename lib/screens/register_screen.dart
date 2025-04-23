import 'package:flutter/material.dart';
import '../database/db_helper.dart';
import '../models/user_model.dart';
import 'login_screen.dart';

class RegisterScreen extends StatelessWidget {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  // ✅ Fungsi validasi email
  bool isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  void _register(BuildContext context) async {
    String name = nameController.text.trim();
    String email = emailController.text.trim();
    String password = passwordController.text.trim();

    // if (!isValidEmail(email)) {
    //   ScaffoldMessenger.of(
    //     context,
    //   ).showSnackBar(SnackBar(content: Text('Format email tidak valid.')));
    //   return;
    // }

    // if (password.length < 7) {
    //   ScaffoldMessenger.of(
    //     context,
    //   ).showSnackBar(SnackBar(content: Text('Password minimal 7 karakter.')));
    //   return;
    // }

    if (email.isNotEmpty && password.isNotEmpty) {
      try {
        await DBHelper.insertUser(
          UserModel(name: name, email: email, password: password),
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Register berhasil! Silakan login.')),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => LoginScreen()),
        );
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Email sudah terdaftar.')));
      }
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Isi semua field.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Register')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: 'Nama Lengkap',
                // hintText: 'Dimas Pratama',
              ),
            ),
            // SizedBox(height: 16),
            TextField(
              controller: emailController,
              decoration: InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: passwordController,
              decoration: InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            SizedBox(height: 20),
            TextButton(
              onPressed: () async {
                String name = nameController.text.trim();
                String email = emailController.text.trim();
                String password = passwordController.text.trim();

                if (name.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Nama tidak boleh kosong.')),
                  );
                  return;
                }

                if (!isValidEmail(email)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Format email tidak valid.')),
                  );
                  return;
                }

                if (password.length < 7) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Password minimal 7 karakter.')),
                  );
                  return;
                }

                await DBHelper.insertUser(
                  UserModel(name: name, email: email, password: password),
                );

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Pendaftaran berhasil!')),
                );

                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => LoginScreen()),
                );
              },

              child: Text("Daftar"),
            ),
          ],
        ),
      ),
    );
  }
}
