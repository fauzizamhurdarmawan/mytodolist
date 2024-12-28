import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:todolist/providers/task_provider.dart';

class TaskScreen extends StatefulWidget {
  const TaskScreen({super.key});

  @override
  _TaskScreenState createState() => _TaskScreenState();
}

class _TaskScreenState extends State<TaskScreen> {
  final TextEditingController _taskController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Fetch tasks and categories when the widget is first created
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final taskProvider = Provider.of<TaskProvider>(context, listen: false);
      taskProvider.fetchTasks();
      taskProvider.fetchCategories();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Tasks"),
        actions: [
          // IconButton(
          //   icon: const Icon(Icons.add),
          //   onPressed: () async {
          //     await _showAddTaskDialog(context);
          //   },
          // ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _searchController.clear(); // Clear the search field
              Provider.of<TaskProvider>(context, listen: false)
                  .fetchTasks(); // Reset tasks to original state
            },
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search Bar
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Search Tasks',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                Provider.of<TaskProvider>(context, listen: false)
                    .searchTasks(value);
              },
            ),
            const SizedBox(height: 16),
            // Category Dropdown
            const Text('Select Category', style: TextStyle(fontSize: 16)),
            DropdownButton<String>(
              value: Provider.of<TaskProvider>(context).selectedCategory,
              items: Provider.of<TaskProvider>(context)
                  .categories
                  .map((category) => DropdownMenuItem<String>(
                      value: category, child: Text(category)))
                  .toList(),
              onChanged: (category) {
                if (category != null) {
                  Provider.of<TaskProvider>(context, listen: false)
                      .updateSelectedCategory(category);
                }
              },
            ),
            const SizedBox(height: 5),
            // Row with buttons (Add New, Edit, Delete Category)
            Row(
              mainAxisAlignment:
                  MainAxisAlignment.center, // Tombol akan ditempatkan di tengah
              children: [
                ElevatedButton(
                  onPressed: () {
                    _showAddCategoryDialog(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color.fromRGBO(107, 33, 168, 1),
                    foregroundColor: Colors.white, // Warna teks putih
                    padding:
                        EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                    textStyle: TextStyle(
                      fontFamily: 'Roboto', // Font Roboto
                    ),
                  ),
                  child: Center(
                    child: const Text('Add Category'),
                  ),
                ),
                const SizedBox(width: 3),
                ElevatedButton(
                  onPressed: () {
                    _showEditCategoryDialog(
                        context,
                        Provider.of<TaskProvider>(context, listen: false)
                            .selectedCategory);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color.fromRGBO(107, 33, 168, 1),
                    foregroundColor: Colors.white, // Warna teks putih
                    padding:
                        EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                    textStyle: TextStyle(
                      fontFamily: 'Roboto', // Font Roboto
                    ),
                  ),
                  child: Center(
                    child: const Text('Edit Category'),
                  ),
                ),
                const SizedBox(width: 3),
                ElevatedButton(
                  onPressed: () {
                    _removeCategory(
                        context,
                        Provider.of<TaskProvider>(context, listen: false)
                            .selectedCategory);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color.fromRGBO(107, 33, 168, 1),
                    foregroundColor: Colors.white, // Warna teks putih
                    padding:
                        EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                    textStyle: TextStyle(
                      fontFamily: 'Roboto', // Font Roboto
                    ),
                  ),
                  child: Center(
                    child: const Text('Delete Category'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Filter Status Dropdown
            const Text('Filter by Status', style: TextStyle(fontSize: 16)),
            const SizedBox(height: 10),
            DropdownButton<String>(
              value:
                  Provider.of<TaskProvider>(context).selectedCompletionStatus,
              items: const [
                DropdownMenuItem<String>(
                    value: 'All', child: Text('All Tasks')),
                DropdownMenuItem<String>(
                    value: 'Completed', child: Text('Completed Tasks')),
                DropdownMenuItem<String>(
                    value: 'Incomplete', child: Text('Incomplete Tasks')),
              ],
              onChanged: (status) {
                if (status != null) {
                  Provider.of<TaskProvider>(context, listen: false)
                      .updateSelectedCompletionStatus(status);
                }
              },
            ),

            // Task List
            Expanded(
              child: Consumer<TaskProvider>(
                builder: (context, taskProvider, child) {
                  final filteredTasks = taskProvider.filteredTasks;
                  return ListView.builder(
                    itemCount: filteredTasks.length,
                    itemBuilder: (context, index) {
                      final task = filteredTasks[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(10),
                          title: Text(task['taskName']),
                          subtitle: Text(
                              'Due: ${task['taskDate'].toString().substring(0, 10)}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(
                                  task['isCompleted']
                                      ? Icons.check_box
                                      : Icons.check_box_outline_blank,
                                ),
                                onPressed: () {
                                  _toggleTaskCompletion(task);
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () {
                                  _showEditTaskDialog(context, task);
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () {
                                  _removeTask(context, task);
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showEditTaskDialog(
      BuildContext context, Map<String, dynamic> task) async {
    final TaskProvider taskProvider =
        Provider.of<TaskProvider>(context, listen: false);
    _taskController.text = task['taskName'];
    _selectedDate = task['taskDate'];

    return showDialog<void>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Edit Task'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _taskController,
                  decoration: const InputDecoration(labelText: 'Task Name'),
                ),
                ListTile(
                  title: Text('Task Date: ${_selectedDate.toLocal()}'),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final selectedDate = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2101),
                    );
                    if (selectedDate != null && selectedDate != _selectedDate) {
                      setState(() {
                        _selectedDate = selectedDate;
                      });
                    }
                  },
                ),
                DropdownButton<String>(
                  value: task['category'],
                  items: taskProvider.categories
                      .map((category) => DropdownMenuItem<String>(
                            value: category,
                            child: Row(
                              children: [
                                Icon(Icons.category),
                                const SizedBox(width: 8),
                                Text(category),
                              ],
                            ),
                          ))
                      .toList(),
                  onChanged: (category) {
                    if (category != null) {
                      setState(() {
                        task['category'] = category;
                      });
                    }
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  if (_taskController.text.isNotEmpty) {
                    taskProvider.updateTaskDetails(
                      task['id'],
                      _taskController.text,
                      _selectedDate,
                      task['category'],
                    );
                    _taskController.clear();
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Task updated successfully')),
                    );
                  }
                },
                child: const Text('Update Task'),
              ),
            ],
          );
        });
  }

  Future<void> _showAddTaskDialog(BuildContext context) async {
    final TaskProvider taskProvider =
        Provider.of<TaskProvider>(context, listen: false);
    return showDialog<void>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Add Task'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _taskController,
                  decoration: const InputDecoration(labelText: 'Task Name'),
                ),
                ListTile(
                  title: Text('Task Date: ${_selectedDate.toLocal()}'),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final selectedDate = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2101),
                    );
                    if (selectedDate != null && selectedDate != _selectedDate) {
                      setState(() {
                        _selectedDate = selectedDate;
                      });
                    }
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('Cancel'),
              ),
              // TextButton(
              //   onPressed: () {
              //     if (_taskController.text.isNotEmpty) {
              //       taskProvider.addTask(_taskController.text, _selectedDate,
              //           taskProvider.selectedCategory);
              //       _taskController.clear();
              //       Navigator.pop(context);
              //       ScaffoldMessenger.of(context).showSnackBar(
              //         const SnackBar(content: Text('Task added successfully')),
              //       );
              //     }
              //   },
              //   child: const Text('Add Task'),
              // ),
            ],
          );
        });
  }

  Future<void> _showEditCategoryDialog(
      BuildContext context, String category) async {
    final TaskProvider taskProvider =
        Provider.of<TaskProvider>(context, listen: false);
    _categoryController.text = category;

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Edit Category'),
          content: TextField(
            controller: _categoryController,
            decoration: const InputDecoration(labelText: 'Category Name'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (_categoryController.text.isNotEmpty) {
                  taskProvider.editCategory(category, _categoryController.text);
                  _categoryController.clear();
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Category updated successfully')),
                  );
                }
              },
              child: const Text('Update Category'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showAddCategoryDialog(BuildContext context) async {
    final TaskProvider taskProvider =
        Provider.of<TaskProvider>(context, listen: false);
    return showDialog<void>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Add New Category'),
            content: TextField(
              controller: _categoryController,
              decoration: const InputDecoration(labelText: 'Category Name'),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  if (_categoryController.text.isNotEmpty) {
                    taskProvider.addCategory(_categoryController.text);
                    _categoryController.clear();
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Category added successfully')),
                    );
                  }
                },
                child: const Text('Add Category'),
              ),
            ],
          );
        });
  }

  void _toggleTaskCompletion(Map<String, dynamic> task) {
    final TaskProvider taskProvider =
        Provider.of<TaskProvider>(context, listen: false);
    taskProvider.toggleTaskCompletion(task['id'], task['isCompleted']);
  }

  void _removeTask(BuildContext context, Map<String, dynamic> task) {
    final TaskProvider taskProvider =
        Provider.of<TaskProvider>(context, listen: false);
    taskProvider.removeTask(task['id']);
  }

  void _removeCategory(BuildContext context, String category) {
    final TaskProvider taskProvider =
        Provider.of<TaskProvider>(context, listen: false);
    taskProvider.removeCategory(category);
  }
}
