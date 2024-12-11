import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class TaskProvider with ChangeNotifier {
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
      _tasks = taskData.docs.map((doc) {
        return {
          'id': doc.id,
          'taskName': doc['task'],
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
  Future<void> addTask(String taskName, DateTime date, String category) async {
    try {
      await FirebaseFirestore.instance.collection('tasks').add({
        'task': taskName,
        'date': date,
        'category': category,
        'createdAt': FieldValue.serverTimestamp(),
        'isCompleted': false, // Default task is not completed
      });
      fetchTasks(); // Refresh tasks list
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
      DateTime newDate, String newCategory) async {
    try {
      await FirebaseFirestore.instance.collection('tasks').doc(taskId).update({
        'task': newTaskName,
        'date': newDate,
        'category': newCategory,
      });
      fetchTasks(); // Refresh tasks list after updating
    } catch (e) {
      print('Error updating task details: $e');
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
          'taskName': doc['task'],
          'taskDate': (doc['date'] as Timestamp).toDate(),
          'category': doc['category'],
          'isCompleted': doc['isCompleted'] ?? false,
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
          .where('task', isGreaterThanOrEqualTo: keyword)
          .where('task', isLessThanOrEqualTo: '$keyword\\uf8ff')
          .get();
      _tasks = taskData.docs.map((doc) {
        return {
          'id': doc.id,
          'taskName': doc['task'],
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
    _tasks.sort((a, b) => a['priority'].compareTo(b['priority']));
    notifyListeners();
  }
}
