import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_screen.dart'; // Pastikan halaman LoginScreen diimpor

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignupScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  Future<void> _signUp() async {
    // Memeriksa apakah password dan konfirmasi password cocok
    if (_passwordController.text != _confirmPasswordController.text) {
      // Menampilkan SnackBar jika konfirmasi password salah
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Konfirmasi password salah'),
      ));
      return;
    }

    try {
      // Proses pendaftaran dengan email dan password
      await _auth.createUserWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );
      // Menampilkan snack bar jika pendaftaran berhasil
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Akun berhasil dibuat!'),
      ));
      // Arahkan ke halaman login setelah registrasi berhasil
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()),
      );
    } catch (e) {
      // Menampilkan pesan error jika ada masalah saat pendaftaran
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Pendaftaran gagal: $e'),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Daftar')),
      body: Stack(
        children: <Widget>[
          // Gambar vektor pertama (misalnya di pojok kanan atas)
          Positioned(
            top: 30,
            right: 30,
            child: SvgPicture.asset(
              'assets/images/vector1.svg', // Sesuaikan dengan path file SVG kamu
              width: 100,
              height: 100,
            ),
          ),
          // Gambar vektor kedua (misalnya di pojok kanan atas)
          Positioned(
            top: 120,
            right: 30,
            child: SvgPicture.asset(
              'assets/images/vector2.svg', // Sesuaikan dengan path file SVG kamu
              width: 100,
              height: 100,
            ),
          ),
          // Background warna putih atau elemen lainnya
          Container(
            width: double.infinity,
            height: double.infinity,
            color: Colors.white,
          ),
          // Teks judul dan deskripsi
          Positioned(
            top: 40,
            left: 23,
            child: Text(
              'Register',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color.fromRGBO(107, 33, 168, 1),
                fontFamily: 'Poppins',
                fontSize: 29,
              ),
            ),
          ),

          Positioned(
            top: 80,
            left: 25,
            child: Text(
              'Welcome! Sign up to get started.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color.fromRGBO(201, 177, 223, 1),
                fontFamily: 'Roboto',
                fontSize: 20,
              ),
            ),
          ),

          // Gambar register.png diletakkan di atas TextField email
          Positioned(
            top: 120, // Posisikan gambar tepat di atas TextField email
            left: 20,
            right: 20,
            child: Image.asset(
              'assets/images/register.png', // Sesuaikan dengan path file PNG kamu
              width: 300,
              height: 270,
            ),
          ),

          // Menggunakan SizedBox untuk memberi jarak antar elemen
          Positioned(
            top: 360, // Sesuaikan posisi untuk input email setelah gambar
            left: 38,
            child: Container(
              width: 330,
              height: 45,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(5),
                color: Colors.white,
                border: Border.all(
                    color: Color.fromRGBO(107, 33, 168, 1), width: 1),
              ),
              child: TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  hintText: 'Email',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(10),
                ),
              ),
            ),
          ),
          // Memberikan jarak menggunakan SizedBox
          SizedBox(height: 10),

          // Form input untuk password
          Positioned(
            top: 420,
            left: 38,
            child: Container(
              width: 330,
              height: 45,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(5),
                color: Colors.white,
                border: Border.all(
                    color: Color.fromRGBO(107, 33, 168, 1), width: 1),
              ),
              child: TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  hintText: 'Password',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(10),
                ),
              ),
            ),
          ),

          // Memberikan jarak menggunakan SizedBox
          SizedBox(height: 20),

          // Form input untuk konfirmasi password
          Positioned(
            top: 480,
            left: 38,
            child: Container(
              width: 330,
              height: 45,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(5),
                color: Colors.white,
                border: Border.all(
                    color: Color.fromRGBO(107, 33, 168, 1), width: 1),
              ),
              child: TextField(
                controller: _confirmPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  hintText: 'Confirm Password',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(10),
                ),
              ),
            ),
          ),

          // Memberikan jarak menggunakan SizedBox
          SizedBox(height: 20),

          // Tombol Daftar
          Positioned(
            top: 545,
            left: 38,
            child: ElevatedButton(
              onPressed: _signUp,
              style: ElevatedButton.styleFrom(
                backgroundColor: Color.fromRGBO(
                    107, 33, 168, 1), // Warna latar belakang ungu
                minimumSize: Size(MediaQuery.of(context).size.width - 76,
                    45), // Lebar tombol mengikuti lebar layar
              ),
              child: Text(
                'Daftar',
                style: TextStyle(
                  color: Colors.white,
                  fontFamily: 'Roboto',
                  fontSize: 20,
                ),
                // Warna teks putih
              ),
            ),
          ),
          Positioned(
            top: 590, // Menempatkan teks di bawah tombol
            left: 48,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center, // Agar teks terpusat
              children: [
                Text(
                  'Sudah punya akun? ',
                  style: TextStyle(
                    color: Colors.black,
                    fontFamily: 'Roboto',
                    fontSize: 16,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    // Navigasi ke halaman login
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => LoginScreen()),
                    );
                  },
                  child: Text(
                    'Login',
                    style: TextStyle(
                      color: Color.fromRGBO(107, 33, 168, 1), // Warna teks ungu
                      fontFamily: 'Roboto',
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
