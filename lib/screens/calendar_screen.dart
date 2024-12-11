import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  _CalendarScreenState createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  List<Map<String, dynamic>> _tasks = [];
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    _fetchTasksForDate(_focusedDay);
    _initializeNotifications();
  }

  // Menginisialisasi notifikasi
  Future<void> _initializeNotifications() async {
    tz.initializeTimeZones();
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('task_icon');
    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  // Menampilkan notifikasi
  Future<void> _showNotification(String title, String body) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'your_channel_id',
      'your_channel_name',
      importance: Importance.high,
      priority: Priority.high,
      ticker: 'ticker',
    );

    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await flutterLocalNotificationsPlugin.show(
        0, title, body, platformChannelSpecifics);
  }

  // Menambahkan tugas ke Firestore
  Future<void> _addTask(String task, DateTime date) async {
    try {
      await FirebaseFirestore.instance.collection('tasks').add({
        'task': task,
        'date': Timestamp.fromDate(date), // Simpan sebagai Timestamp
        'createdAt': Timestamp.fromDate(DateTime.now()),
        'isCompleted': false, // Ganti notified menjadi isCompleted
      });

      // Notifikasi sukses
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Tugas berhasil ditambahkan!')),
      );
      _fetchTasksForDate(date); // Refresh daftar tugas setelah menambahkan
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menambahkan tugas: $e')),
      );
    }
  }

  // Memuat tugas berdasarkan tanggal
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
          return {
            'task': doc['task'],
            'createdAt': doc['createdAt']?.toDate(),
            'isCompleted': doc['isCompleted'], // Menambahkan status isCompleted
          };
        }).toList();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching tasks: $e')),
      );
    }
  }

  // Memeriksa notifikasi untuk tugas yang terlambat atau untuk besok
  Future<void> _checkForNotifications() async {
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);

    // Query untuk tugas yang terlambat
    final overdueTasksQuery = FirebaseFirestore.instance
        .collection('tasks')
        .where('date', isLessThan: Timestamp.fromDate(now))
        .get();

    // Query untuk tugas yang akan datang besok
    final upcomingTasksQuery = FirebaseFirestore.instance
        .collection('tasks')
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(tomorrow))
        .where('date',
            isLessThan: Timestamp.fromDate(tomorrow.add(Duration(days: 1))))
        .get();

    final overdueTasksSnapshot = await overdueTasksQuery;
    final upcomingTasksSnapshot = await upcomingTasksQuery;

    // Mempersiapkan daftar tugas yang terlewat dan besok
    List<String> overdueTasks = [];
    List<String> upcomingTasks = [];

    if (overdueTasksSnapshot.docs.isNotEmpty) {
      for (var task in overdueTasksSnapshot.docs) {
        overdueTasks.add('Tugas Terlambat: ${task['task']}');
      }
    }

    if (upcomingTasksSnapshot.docs.isNotEmpty) {
      for (var task in upcomingTasksSnapshot.docs) {
        upcomingTasks.add('Tugas Besok: ${task['task']}');
      }
    }

    // Menampilkan dialog dengan detail tugas
    if (overdueTasks.isNotEmpty || upcomingTasks.isNotEmpty) {
      _showTaskDialog(overdueTasks, upcomingTasks);
    }
  }

  // Menampilkan dialog dengan tugas terlewat dan besok
  void _showTaskDialog(List<String> overdueTasks, List<String> upcomingTasks) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Notifikasi Tugas'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (overdueTasks.isNotEmpty)
                  Text(
                    'Tugas yang Terlambat:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ...overdueTasks.map((task) => Text(task)),
                if (overdueTasks.isNotEmpty && upcomingTasks.isNotEmpty)
                  SizedBox(height: 16),
                if (upcomingTasks.isNotEmpty)
                  Text(
                    'Tugas Besok:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ...upcomingTasks.map((task) => Text(task)),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Tutup'),
            ),
          ],
        );
      },
    );
  }

  // Menangani pemilihan tanggal
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
        actions: [
          IconButton(
            icon: Icon(Icons.notifications),
            onPressed:
                _checkForNotifications, // Memeriksa dan menampilkan notifikasi saat tombol lonceng ditekan
          ),
        ],
      ),
      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2100, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) {
              return isSameDay(_selectedDay, day);
            },
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
                      return ListTile(
                        title: Text(task['task']),
                        subtitle: Text('Dibuat pada: ${task['createdAt']}'),
                      );
                    },
                  ),
          ),
          // Tombol untuk menambahkan tugas baru
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton(
              onPressed: () {
                _showAddTaskDialog(context);
              },
              child: Text('Tambah Tugas'),
            ),
          ),
        ],
      ),
    );
  }

  // Dialog untuk menambah tugas
  void _showAddTaskDialog(BuildContext context) {
    final TextEditingController taskController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Tambah Tugas'),
          content: TextField(
            controller: taskController,
            decoration: InputDecoration(hintText: 'Masukkan tugas'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Batal'),
            ),
            TextButton(
              onPressed: () {
                String task = taskController.text.trim();
                if (task.isNotEmpty) {
                  _addTask(task, _focusedDay);
                  Navigator.of(context).pop();
                }
              },
              child: Text('Tambah'),
            ),
          ],
        );
      },
    );
  }
}
