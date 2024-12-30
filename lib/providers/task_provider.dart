import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:todolist/services/encryption_service.dart';

class TaskProvider with ChangeNotifier {
  // final FirebaseFirestore _firestore =
  //     FirebaseFirestore.instance; // Inisialisasi Firestore
  final EncryptionService _encryptionService =
      EncryptionService(); // Inisialisasi EncryptionService
  List<Map<String, dynamic>> _tasks = [];
  List<String> _categories = ['All'];
  String _selectedCategory = 'All'; // Kategori default adalah 'All'
  String _selectedCompletionStatus =
      'All'; // Status completion default adalah 'All'

  List<Map<String, dynamic>> get tasks => _tasks;
  List<String> get categories => _categories;
  String get selectedCategory => _selectedCategory;
  String get selectedCompletionStatus => _selectedCompletionStatus;

  // Filter tasks berdasarkan kategori dan status completion
  List<Map<String, dynamic>> get filteredTasks {
    return _tasks.where((task) {
      bool categoryMatch =
          _selectedCategory == 'All' || task['category'] == _selectedCategory;
      bool completionMatch = false;

      if (_selectedCompletionStatus == 'All') {
        completionMatch = true;
      } else if (_selectedCompletionStatus == 'Completed' &&
          task['isCompleted']) {
        completionMatch = true;
      } else if (_selectedCompletionStatus == 'Incomplete' &&
          !task['isCompleted']) {
        completionMatch = true;
      }

      return categoryMatch && completionMatch;
    }).toList();
  }

  // Mengubah kategori yang dipilih
  void updateSelectedCategory(String category) {
    _selectedCategory = category;
    notifyListeners();
  }

  // Memperbarui status completion yang dipilih
  void updateSelectedCompletionStatus(String status) {
    _selectedCompletionStatus = status;
    notifyListeners();
  }

  // Fetch tasks from Firestore
  Future<void> fetchTasks() async {
    try {
      final taskData =
          await FirebaseFirestore.instance.collection('tasks').get();

      // Print dokumen untuk memeriksa semua data yang ada
      print('Fetched tasks: ${taskData.docs.map((doc) => doc.data())}');

      _tasks = taskData.docs.map((doc) {
        // Cek apakah field task_name ada
        final taskNameEncrypted =
            doc.data().containsKey('task_name') ? doc['task_name'] : null;

        final decryptedTaskName = taskNameEncrypted != null
            ? _encryptionService.decryptData(taskNameEncrypted)
            : 'Unknown Task'; // Jika tidak ada task_name, beri nilai default

        return {
          'id': doc.id,
          'taskName': decryptedTaskName,
          'taskDate': (doc['date'] as Timestamp).toDate(),
          'category': doc['category'],
          'isCompleted': doc['isCompleted'] ?? false,
        };
      }).toList();
      notifyListeners();
    } catch (e) {
      print('Error fetching tasks: $e');
    }
  }

  // Fetch categories from Firestore
  Future<void> fetchCategories() async {
    try {
      final categoryData =
          await FirebaseFirestore.instance.collection('categories').get();
      _categories =
          categoryData.docs.map((doc) => doc['name'] as String).toList();
      _categories.insert(0, 'All'); // Tambahkan kategori 'All' di awal
      notifyListeners();
    } catch (e) {
      print('Error fetching categories: $e');
    }
  }

  // Add a new task to Firestore
  Future<void> addTask(
      String taskName, DateTime taskDate, String category) async {
    try {
      if (taskName.isNotEmpty) {
        // Enkripsi task name sebelum menyimpan ke database
        String encryptedTaskName = _encryptionService.encryptData(taskName);
        if (encryptedTaskName.isNotEmpty) {
          // Simpan task name yang terenkripsi dan plaintext ke Firestore
          await FirebaseFirestore.instance.collection('tasks').add({
            'task_name': encryptedTaskName, // Data terenkripsi
            'task_name_plaintext': taskName, // Data plaintext untuk pencarian
            'date': taskDate,
            'category': category,
            'isCompleted': false,
          });
          print('Task added successfully');
          fetchTasks();
        } else {
          print('Task name encryption failed.');
        }
      } else {
        print('Task name is empty.');
      }
    } catch (e) {
      print('Error adding task: $e');
    }
  }

  // Remove task from Firestore
  Future<void> removeTask(String taskId) async {
    try {
      await FirebaseFirestore.instance.collection('tasks').doc(taskId).delete();
      fetchTasks(); // Refresh tasks list after removing task
    } catch (e) {
      print('Error deleting task: $e');
    }
  }

  // Toggle task completion status
  Future<void> toggleTaskCompletion(String taskId, bool isCompleted) async {
    try {
      await FirebaseFirestore.instance.collection('tasks').doc(taskId).update({
        'isCompleted': !isCompleted,
      });
      fetchTasks(); // Refresh tasks list after updating completion status
    } catch (e) {
      print('Error updating task completion: $e');
    }
  }

  // Add category to Firestore
  Future<void> addCategory(String category) async {
    if (!_categories.contains(category)) {
      try {
        await FirebaseFirestore.instance.collection('categories').add({
          'name': category,
        });
        fetchCategories(); // Refresh categories list
      } catch (e) {
        print('Error adding category: $e');
      }
    }
  }

  // Remove category from Firestore
  Future<void> removeCategory(String category) async {
    if (category != 'All') {
      try {
        // Remove category from Firestore
        final snapshot = await FirebaseFirestore.instance
            .collection('categories')
            .where('name', isEqualTo: category)
            .get();
        for (var doc in snapshot.docs) {
          await doc.reference.delete();
        }

        // Update tasks that have this category to 'All'
        final taskSnapshot = await FirebaseFirestore.instance
            .collection('tasks')
            .where('category', isEqualTo: category)
            .get();
        for (var taskDoc in taskSnapshot.docs) {
          await taskDoc.reference.update({'category': 'All'});
        }
        fetchCategories(); // Refresh categories list
        fetchTasks(); // Refresh tasks list after category removal
      } catch (e) {
        print('Error removing category: $e');
      }
    }
  }

  // Edit category name in Firestore
  Future<void> editCategory(String oldCategory, String newCategory) async {
    if (oldCategory != 'All') {
      try {
        // Update category name in Firestore
        final snapshot = await FirebaseFirestore.instance
            .collection('categories')
            .where('name', isEqualTo: oldCategory)
            .get();
        for (var doc in snapshot.docs) {
          await doc.reference.update({'name': newCategory});
        }

        // Update tasks that have the old category to the new category
        final taskSnapshot = await FirebaseFirestore.instance
            .collection('tasks')
            .where('category', isEqualTo: oldCategory)
            .get();
        for (var taskDoc in taskSnapshot.docs) {
          await taskDoc.reference.update({'category': newCategory});
        }
        fetchCategories(); // Refresh categories list
        fetchTasks(); // Refresh tasks list after category update
      } catch (e) {
        print('Error editing category: $e');
      }
    }
  }

  // Update task category
  Future<void> updateTaskCategory(String taskId, String category) async {
    try {
      await FirebaseFirestore.instance.collection('tasks').doc(taskId).update({
        'category': category,
      });
      fetchTasks(); // Refresh tasks list after updating category
    } catch (e) {
      print('Error updating task category: $e');
    }
  }

  // Update task details
  Future<void> updateTaskDetails(String taskId, String newTaskName,
      DateTime taskDate, String category) async {
    try {
      // Ambil task yang akan diupdate
      final taskDoc = await FirebaseFirestore.instance
          .collection('tasks')
          .doc(taskId)
          .get();

      if (taskDoc.exists) {
        // Enkripsi nama task yang baru
        String encryptedNewTaskName =
            _encryptionService.encryptData(newTaskName);

        // Update task di Firestore dengan task name yang baru, plaintext dan tanggal baru
        await taskDoc.reference.update({
          'task_name': encryptedNewTaskName, // Enkripsi task name
          'task_name_plaintext':
              newTaskName, // Simpan plaintext untuk pencarian
          'date': taskDate, // Task date
          'category': category, // Kategori
        });

        print('Task updated successfully');
        fetchTasks();
      } else {
        print('Task not found');
      }
    } catch (e) {
      print('Error updating task: $e');
    }
  }

  // Filter tasks by date range
  Future<void> filterTasksByDate(DateTime startDate, DateTime endDate) async {
    try {
      final taskData = await FirebaseFirestore.instance
          .collection('tasks')
          .where('date', isGreaterThanOrEqualTo: startDate)
          .where('date', isLessThanOrEqualTo: endDate)
          .get();
      _tasks = taskData.docs.map((doc) {
        return {
          'id': doc.id,
          'taskName': doc['task_name'],
          'taskDate': (doc['date'] as Timestamp).toDate(),
          'category': doc['category'],
          'isCompleted': doc['isCompleted'] ?? false,
          'priority': doc['priority'] ?? 0, // Tambahkan priority
        };
      }).toList();
      notifyListeners();
    } catch (e) {
      print('Error filtering tasks by date: $e');
    }
  }

  // Search tasks by keyword
  Future<void> searchTasks(String keyword) async {
    try {
      final taskData = await FirebaseFirestore.instance
          .collection('tasks')
          .where('task_name_plaintext', isGreaterThanOrEqualTo: keyword)
          .where('task_name_plaintext', isLessThanOrEqualTo: '$keyword\uf8ff')
          .get();

      _tasks = taskData.docs.map((doc) {
        // Ambil versi terenkripsi dari task_name
        final encryptedTaskName = doc['task_name'];
        final decryptedTaskName =
            _encryptionService.decryptData(encryptedTaskName);

        return {
          'id': doc.id,
          'taskName':
              decryptedTaskName, // Menampilkan task name yang telah didekripsi
          'taskDate': (doc['date'] as Timestamp).toDate(),
          'category': doc['category'],
          'isCompleted': doc['isCompleted'] ?? false,
        };
      }).toList();
      notifyListeners();
    } catch (e) {
      print('Error searching tasks: $e');
    }
  }

  // Sort tasks by date
  void sortTasksByDate() {
    _tasks.sort((a, b) => a['taskDate'].compareTo(b['taskDate']));
    notifyListeners();
  }

  // Sort tasks by priority
  void sortTasksByPriority() {
    _tasks.sort((a, b) {
      int priorityA = a['priority'] ?? 0; // Pastikan ada kolom priority
      int priorityB = b['priority'] ?? 0; // Pastikan ada kolom priority
      return priorityA.compareTo(priorityB);
    });
    notifyListeners();
  }
}
