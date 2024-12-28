import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SettingScreen extends StatefulWidget {
  const SettingScreen({super.key});

  @override
  _SettingScreenState createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  String _errorMessage = '';

  // Fungsi untuk memverifikasi kata sandi lama
  Future<void> _verifyCurrentPassword(String currentPassword) async {
    final user = _auth.currentUser;

    if (user != null) {
      try {
        // Memverifikasi kata sandi lama dengan re-authentication
        final credentials = EmailAuthProvider.credential(
          email: user.email!,
          password: currentPassword,
        );

        // Melakukan re-authentication untuk memverifikasi kata sandi lama
        await user.reauthenticateWithCredential(credentials);
        _errorMessage = '';
      } catch (e) {
        setState(() {
          _errorMessage = 'Password is incorrect. Please try again.';
        });
      }
    }
  }

  // Fungsi untuk mengubah kata sandi
  Future<void> _updatePassword() async {
    final user = _auth.currentUser;

    if (user != null) {
      try {
        await user.updatePassword(_newPasswordController.text);
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Password successfully updated')));
      } catch (e) {
        setState(() {
          _errorMessage = 'Error updating password: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings', style: TextStyle(fontFamily: 'Roboto')),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Change Password',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            TextField(
              controller: _currentPasswordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Current Password',
                border: OutlineInputBorder(),
                errorText: _errorMessage.isNotEmpty ? _errorMessage : null,
              ),
            ),
            SizedBox(height: 10),
            TextField(
              controller: _newPasswordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'New Password',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                // Pertama, verifikasi kata sandi lama
                await _verifyCurrentPassword(_currentPasswordController.text);
                if (_errorMessage.isEmpty) {
                  // Jika kata sandi lama benar, lanjutkan untuk mengubah kata sandi
                  await _updatePassword();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color.fromRGBO(107, 33, 168, 1),
                padding:
                    const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
              ),
              child: const Text(
                'Update Password',
                style: TextStyle(
                  color: Colors.white, // Warna teks putih
                  fontFamily: 'Roboto', // Menetapkan font menjadi Roboto
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
