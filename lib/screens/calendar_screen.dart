import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:weather_icons/weather_icons.dart';
import 'package:todolist/services/encryption_service.dart';
import 'package:todolist/services/weather_service.dart';
import 'package:todolist/services/notification_service.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  _CalendarScreenState createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  final WeatherService _weatherService = WeatherService();
  final EncryptionService _encryptionService = EncryptionService();
  final NotificationService _notificationService = NotificationService();

  String _weatherInfo = 'Loading...';
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  List<Map<String, dynamic>> _tasks = [];

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    await _notificationService.init();
    _requestPermission();
    _fetchWeather();
    _fetchTasksForDate(_focusedDay);
  }

  Future<void> _requestPermission() async {
    PermissionStatus status = await Permission.notification.request();
    if (!status.isGranted) {
      print("Izin notifikasi ditolak");
    }
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

  Future<void> _notifyTomorrowTasks() async {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    final startOfTomorrow =
        DateTime(tomorrow.year, tomorrow.month, tomorrow.day);
    final endOfTomorrow =
        DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 23, 59, 59);

    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('tasks')
          .where('date',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startOfTomorrow))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endOfTomorrow))
          .get();

      if (querySnapshot.docs.isEmpty) {
        await _notificationService.showNotification(
          id: 1,
          title: 'Tugas Besok',
          body: 'Tidak ada tugas untuk besok.',
        );
      } else {
        String taskList = querySnapshot.docs.map((doc) {
          final encryptedTaskName = doc['task_name'] as String;
          return _encryptionService.decryptData(encryptedTaskName);
        }).join(', ');

        await _notificationService.showNotification(
          id: 1,
          title: 'Tugas Besok',
          body: 'Tugas yang harus diselesaikan besok: $taskList',
        );
      }
    } catch (e) {
      print('Error fetching tomorrow tasks: $e');
    }
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    setState(() {
      _selectedDay = selectedDay;
      _focusedDay = focusedDay;
    });
    _fetchTasksForDate(selectedDay);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kalender & Tugas'),
        backgroundColor: const Color.fromARGB(255, 211, 203, 218),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              _notifyTomorrowTasks();
            },
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color.fromARGB(255, 193, 185, 200), // Warna gradien pertama
              Colors.white, // Warna gradien kedua
            ],
            begin: Alignment.topLeft, // Gradien mulai dari kiri atas
            end: Alignment.bottomRight, // Gradien berakhir di kanan bawah
          ),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                  child: Row(
                    children: [
                      Icon(
                        _getWeatherIcon(_weatherInfo),
                        size: 64,
                        color: Colors.orange,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Cuaca Hari Ini',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              _weatherInfo,
                              style: const TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TableCalendar(
                    firstDay: DateTime.utc(2020, 1, 1),
                    lastDay: DateTime.utc(2100, 12, 31),
                    focusedDay: _focusedDay,
                    selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                    onDaySelected: _onDaySelected,
                    calendarStyle: CalendarStyle(
                      selectedDecoration: BoxDecoration(
                        color: Colors.orange,
                        shape: BoxShape.circle,
                      ),
                      todayDecoration: BoxDecoration(
                        color: Colors.blueAccent,
                        shape: BoxShape.circle,
                      ),
                      markerDecoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                      outsideDaysVisible: false,
                    ),
                    headerStyle: HeaderStyle(
                      formatButtonVisible: false,
                      titleCentered: true,
                      titleTextStyle: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _tasks.isEmpty
                  ? const Center(
                      child: Text(
                        'Tidak ada tugas untuk hari ini',
                        style: TextStyle(fontSize: 16),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _tasks.length,
                      itemBuilder: (context, index) {
                        final task = _tasks[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 6,
                          child: ListTile(
                            title: Text(
                              task['task'],
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              'Tanggal: ${task['date']}',
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
