import 'dart:convert';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'login_screen.dart';
import 'setting_screen.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  _AccountScreenState createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ImagePicker _picker = ImagePicker();
  File? _imageFile; // Untuk menyimpan gambar yang dipilih
  String? _base64Image; // Menyimpan gambar dalam bentuk base64

  // Fungsi untuk memeriksa dan membuat dokumen pengguna di Firestore
  Future<void> _createUserDocument() async {
    final user = _auth.currentUser;
    if (user != null) {
      final userDoc =
          FirebaseFirestore.instance.collection('users').doc(user.uid);

      // Memeriksa apakah dokumen sudah ada
      final docSnapshot = await userDoc.get();

      if (!docSnapshot.exists) {
        // Membuat dokumen pengguna jika tidak ada
        await userDoc.set({
          'email': user.email, // Menyimpan email pengguna
          'photoURL': '', // Menyimpan foto profil kosong atau default
        });
        print("Dokumen pengguna berhasil dibuat.");
      }
    }
  }

  // Fungsi untuk memilih gambar dari kamera atau galeri
  Future<void> _pickImage(ImageSource source) async {
    // Memastikan izin sudah diberikan
    await _checkPermissions();

    final pickedFile = await _picker.pickImage(source: source);

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });

      // Konversi gambar menjadi base64
      _convertImageToBase64(_imageFile!);
    }
  }

  // Fungsi untuk mengonversi gambar ke base64
  Future<void> _convertImageToBase64(File imageFile) async {
    final bytes = await imageFile.readAsBytes();
    String base64String = base64Encode(bytes);

    // Simpan base64 ke Firestore
    _saveProfileImage(base64String);
  }

  // Fungsi untuk menyimpan base64 gambar ke Firestore
  Future<void> _saveProfileImage(String base64Image) async {
    try {
      final userDoc = FirebaseFirestore.instance
          .collection('users')
          .doc(_auth.currentUser!.uid);

      // Memastikan dokumen pengguna ada
      final docSnapshot = await userDoc.get();

      if (docSnapshot.exists) {
        await userDoc.update({
          'photoURL': base64Image, // Menyimpan base64 ke Firestore
        });
        setState(() {
          _base64Image = base64Image;
        });
        print("Foto profil berhasil diperbarui.");
      } else {
        print("Dokumen pengguna tidak ditemukan.");
      }
    } catch (e) {
      print('Error saving image: $e');
    }
  }

  // Fungsi untuk mengambil gambar profil dari Firestore
  Future<String?> _getProfileImageBase64() async {
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(_auth.currentUser!.uid)
        .get();

    return userDoc.exists ? userDoc['photoURL'] : null;
  }

  // Fungsi untuk memeriksa izin kamera dan galeri
  Future<void> _checkPermissions() async {
    var statusCamera = await Permission.camera.request();
    var statusGallery = await Permission.photos.request();

    if (statusCamera.isGranted && statusGallery.isGranted) {
      print('Permissions granted');
    } else {
      print('Permissions not granted');
    }
  }

  // Fungsi untuk sign out
  Future<void> _signOut(BuildContext context) async {
    await _auth.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginScreen()),
    );
  }

  bool _isHovering = false; // Untuk mendeteksi hover

  @override
  Widget build(BuildContext context) {
    // Memanggil fungsi untuk membuat dokumen pengguna setelah login
    _createUserDocument();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Account', style: TextStyle(fontFamily: 'Roboto')),
        actions: [
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () {
              // Arahkan ke halaman setting
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SettingScreen()),
              );
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            const SizedBox(height: 50),
            // Menampilkan gambar profil jika ada, jika tidak tampilkan gambar default
            MouseRegion(
              onEnter: (_) => setState(() => _isHovering = true),
              onExit: (_) => setState(() => _isHovering = false),
              child: GestureDetector(
                onTap: () {
                  // Pilih gambar dari kamera atau galeri
                  showModalBottomSheet(
                    context: context,
                    builder: (context) {
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ListTile(
                            leading: const Icon(Icons.camera),
                            title: const Text('Take a photo',
                                style: TextStyle(fontFamily: 'Roboto')),
                            onTap: () {
                              _pickImage(ImageSource.camera);
                              Navigator.pop(context);
                            },
                          ),
                          ListTile(
                            leading: const Icon(Icons.image),
                            title: const Text('Choose from gallery',
                                style: TextStyle(fontFamily: 'Roboto')),
                            onTap: () {
                              _pickImage(ImageSource.gallery);
                              Navigator.pop(context);
                            },
                          ),
                        ],
                      );
                    },
                  );
                },
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    FutureBuilder<String?>(
                      future: _getProfileImageBase64(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const CircleAvatar(
                            radius: 50,
                            child: CircularProgressIndicator(),
                          );
                        } else if (snapshot.hasError) {
                          return const CircleAvatar(
                            radius: 50,
                            child: Icon(Icons.error),
                          );
                        } else {
                          String? base64Image = snapshot.data;
                          if (base64Image != null && base64Image.isNotEmpty) {
                            return CircleAvatar(
                              radius: 50,
                              backgroundImage:
                                  MemoryImage(base64Decode(base64Image)),
                            );
                          } else {
                            return const CircleAvatar(
                              radius: 50,
                              backgroundImage: AssetImage(
                                  'assets/images/default_profile.png'), // Default image
                            );
                          }
                        }
                      },
                    ),
                    if (_isHovering)
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.black.withOpacity(0.3),
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text('Welcome, ${_auth.currentUser?.email}',
                style: const TextStyle(fontFamily: 'Roboto')),
            const SizedBox(height: 30),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                padding:
                    const EdgeInsets.symmetric(vertical: 15, horizontal: 30),
              ),
              onPressed: () => _signOut(context),
              child: const Text(
                'Sign Out',
                style: TextStyle(
                    color: Colors.white,
                    fontFamily: 'Roboto'), // Mengubah warna teks menjadi putih
              ),
            ),
          ],
        ),
      ),
    );
  }
}
