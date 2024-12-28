import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:permission_handler/permission_handler.dart';
import 'package:todolist/services/encryption_service.dart';
import 'package:todolist/services/weather_service.dart';
import 'package:weather_icons/weather_icons.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  _CalendarScreenState createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  final WeatherService _weatherService = WeatherService();
  String _weatherInfo = 'Loading...';
  final EncryptionService _encryptionService = EncryptionService();
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  List<Map<String, dynamic>> _tasks = [];
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    _requestPermission();
    _initializeNotifications();
    _fetchWeather(); // Memuat data cuaca
    _fetchTasksForDate(_focusedDay); // Memuat tugas untuk tanggal fokus
  }

  Future<void> _fetchWeather() async {
    try {
      String weather = await _weatherService.getWeather('Bandung');
      setState(() {
        _weatherInfo = weather;
      });
    } catch (e) {
      setState(() {
        _weatherInfo = 'Error fetching weather';
      });
    }
  }

  IconData _getWeatherIcon(String condition) {
    switch (condition.toLowerCase()) {
      case 'clear sky':
        return WeatherIcons.day_sunny;
      case 'few clouds':
        return WeatherIcons.day_cloudy;
      case 'rain':
        return WeatherIcons.rain;
      case 'thunderstorm':
        return WeatherIcons.thunderstorm;
      case 'snow':
        return WeatherIcons.snow;
      case 'mist':
        return WeatherIcons.fog;
      default:
        return WeatherIcons.day_sunny;
    }
  }

  Future<void> _requestPermission() async {
    PermissionStatus status = await Permission.notification.request();
    if (!status.isGranted) {
      print("Izin notifikasi ditolak");
    }
  }

  Future<void> _initializeNotifications() async {
    tz.initializeTimeZones();
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('task_icon');
    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  Future<void> _addTask(String task, DateTime date) async {
    try {
      final encryptedTask = _encryptionService.encryptData(task);
      await FirebaseFirestore.instance.collection('tasks').add({
        'task_name': encryptedTask,
        'date': Timestamp.fromDate(date),
        'createdAt': Timestamp.fromDate(DateTime.now()),
        'isCompleted': false,
      });
      _fetchTasksForDate(date);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menambahkan tugas: $e')),
      );
    }
  }

  Future<void> _fetchTasksForDate(DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('tasks')
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
          .get();

      setState(() {
        _tasks = querySnapshot.docs.map((doc) {
          final encryptedTaskName = doc['task_name'] as String;
          final decryptedTaskName =
              _encryptionService.decryptData(encryptedTaskName);
          return {
            'task': decryptedTaskName,
            'date': doc['date'].toDate(),
            'isCompleted': doc['isCompleted'],
          };
        }).toList();
      });
    } catch (e) {
      print('Error fetching tasks: $e');
    }
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    setState(() {
      _selectedDay = selectedDay;
      _focusedDay = focusedDay;
    });
    _fetchTasksForDate(selectedDay);
  }

  void _showAddTaskDialog(BuildContext context) {
    final TextEditingController taskController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Tambah Tugas'),
          content: TextField(
            controller: taskController,
            decoration: const InputDecoration(hintText: 'Masukkan tugas'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                final task = taskController.text;
                if (task.isNotEmpty) {
                  _addTask(task, _focusedDay);
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Tambah'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kalender & Tugas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              // Tambahkan logika untuk notifikasi di sini
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: ListTile(
                leading: Icon(
                  _getWeatherIcon(_weatherInfo),
                  size: 40.0,
                ),
                title: Text(
                  _weatherInfo,
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: const Text('Cuaca hari ini di Bandung'),
              ),
            ),
          ),
          TableCalendar(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2100, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: _onDaySelected,
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _tasks.isEmpty
                ? const Center(child: Text('Tidak ada tugas untuk hari ini'))
                : ListView.builder(
                    itemCount: _tasks.length,
                    itemBuilder: (context, index) {
                      final task = _tasks[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        child: ListTile(
                          title: Text(task['task']),
                          subtitle: Text('Tanggal: ${task['date']}'),
                        ),
                      );
                    },
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton.icon(
              onPressed: () => _showAddTaskDialog(context),
              icon: const Icon(Icons.add),
              label: const Text('Tambah Tugas'),
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
