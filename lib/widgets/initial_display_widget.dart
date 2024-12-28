import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';
import 'package:todolist/screens/login_screen.dart'; // Halaman login
import 'package:todolist/screens/signup_screen.dart'; // Halaman register

class InitialdisplayWidget extends StatelessWidget {
  const InitialdisplayWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          color: Color.fromRGBO(255, 255, 255, 1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Welcome to My ToDo List',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color.fromRGBO(107, 33, 168, 1),
                fontFamily: 'Poppins',
                fontSize: 29,
                fontWeight: FontWeight.normal,
              ),
            ),
            SizedBox(height: 30),
            Container(
              width: 225,
              height: 266,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/Welcome1.png'),
                  fit: BoxFit.fitWidth,
                ),
              ),
            ),
            SizedBox(height: 40),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Color.fromRGBO(107, 33, 168, 1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                minimumSize: Size(250, 44),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => LoginScreen()),
                );
              },
              child: Text(
                'Login',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                ),
              ),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                side: BorderSide(
                    color: Color.fromRGBO(107, 33, 168, 1), width: 1),
                minimumSize: Size(250, 44),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          SignupScreen()), // Navigasi ke halaman register
                );
              },
              child: Text(
                'Register',
                style: TextStyle(
                  color: Color.fromRGBO(107, 33, 168, 1),
                  fontSize: 18,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
