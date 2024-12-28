import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'providers/task_provider.dart';
import 'screens/home_screen.dart';
import 'widgets/initial_display_widget.dart'; // Import InitialdisplayWidget
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inisialisasi Firebase dan NotificationService
  await Firebase.initializeApp();
  await NotificationService().init();

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Provider untuk Task
        ChangeNotifierProvider(create: (context) => TaskProvider()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'My ToDo List',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home:
            InitialDisplayWrapper(), // Gunakan wrapper untuk menentukan halaman awal
      ),
    );
  }
}

// Wrapper untuk menentukan alur awal aplikasi
class InitialDisplayWrapper extends StatefulWidget {
  const InitialDisplayWrapper({super.key});

  @override
  _InitialDisplayWrapperState createState() => _InitialDisplayWrapperState();
}

class _InitialDisplayWrapperState extends State<InitialDisplayWrapper> {
  bool showInitialDisplay = true;

  @override
  void initState() {
    super.initState();
    // Delay 3 detik untuk menampilkan halaman awal
    Future.delayed(const Duration(seconds: 3), () {
      setState(() {
        showInitialDisplay = false; // Setelah 3 detik, alihkan ke StreamBuilder
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    // Tampilkan InitialdisplayWidget selama 3 detik
    if (showInitialDisplay) {
      return InitialdisplayWidget(); // Halaman Awal yang Anda buat
    } else {
      // Setelah 3 detik, mulai pengecekan status autentikasi
      return StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          // Jika status autentikasi dalam pemrosesan
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          // Jika sudah login, tampilkan HomeScreen
          if (snapshot.hasData) {
            return HomeScreen();
          } else {
            // Jika belum login, tampilkan LoginScreen
            return InitialdisplayWidget(); // Tombol untuk login dan register
          }
        },
      );
    }
  }
}
