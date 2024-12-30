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
        title: const Text("My Tasks",
            style: TextStyle(fontSize: 20, color: Colors.black)),
        centerTitle: true,
        backgroundColor: const Color.fromARGB(255, 211, 203, 218),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _searchController.clear();
              Provider.of<TaskProvider>(context, listen: false).fetchTasks();
            },
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [const Color.fromARGB(255, 193, 185, 200), Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Search Bar
              TextField(
                controller: _searchController,
                style: const TextStyle(color: Colors.black),
                decoration: InputDecoration(
                  labelText: 'Search Tasks',
                  labelStyle: const TextStyle(color: Colors.black),
                  prefixIcon: const Icon(Icons.search, color: Colors.black),
                  filled: true,
                  fillColor: Colors.black.withOpacity(0.2),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.black),
                  ),
                ),
                onChanged: (value) {
                  Provider.of<TaskProvider>(context, listen: false)
                      .searchTasks(value);
                },
              ),
              const SizedBox(height: 16),
              // Category Dropdown
              const Text(
                'Select Category',
                style: TextStyle(fontSize: 16, color: Colors.black),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButton<String>(
                  dropdownColor: const Color.fromARGB(255, 202, 198, 211),
                  value: Provider.of<TaskProvider>(context).selectedCategory,
                  items: Provider.of<TaskProvider>(context)
                      .categories
                      .toSet()
                      .map((category) => DropdownMenuItem<String>(
                            value: category,
                            child: Text(
                              category,
                              style: const TextStyle(color: Colors.black),
                            ),
                          ))
                      .toList(),
                  onChanged: (category) {
                    if (category != null) {
                      Provider.of<TaskProvider>(context, listen: false)
                          .updateSelectedCategory(category);
                    }
                  },
                  isExpanded: true,
                  underline: const SizedBox(),
                  icon: const Icon(Icons.arrow_drop_down, color: Colors.black),
                ),
              ),
              const SizedBox(height: 16),
              // Add Category Button
              Center(
                child: ElevatedButton.icon(
                  onPressed: () {
                    _showAddCategoryDialog(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.deepPurple,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 20),
                  ),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Category'),
                ),
              ),
              const SizedBox(height: 16),
              // Filter by Status
              const Text(
                'Filter by Status',
                style: TextStyle(fontSize: 16, color: Colors.black),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButton<String>(
                  dropdownColor: const Color.fromARGB(255, 202, 198, 211),
                  value: Provider.of<TaskProvider>(context)
                      .selectedCompletionStatus,
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
                  isExpanded: true,
                  underline: const SizedBox(),
                  icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                ),
              ),
              const SizedBox(height: 16),
              // Task List
              Expanded(
                child: Consumer<TaskProvider>(
                  builder: (context, taskProvider, child) {
                    final filteredTasks = taskProvider.filteredTasks;
                    if (filteredTasks.isEmpty) {
                      return const Center(
                        child: Text(
                          'No tasks found!',
                          style: TextStyle(color: Colors.white),
                        ),
                      );
                    }
                    return ListView.builder(
                      itemCount: filteredTasks.length,
                      itemBuilder: (context, index) {
                        final task = filteredTasks[index];
                        return Card(
                          color: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(12),
                            title: Text(
                              task['taskName'],
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.deepPurple),
                            ),
                            subtitle: Text(
                              'Due: ${task['taskDate'].toString().substring(0, 10)}',
                              style: const TextStyle(color: Colors.black54),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(
                                    task['isCompleted']
                                        ? Icons.check_circle
                                        : Icons.radio_button_unchecked,
                                    color: task['isCompleted']
                                        ? Colors.green
                                        : Colors.grey,
                                  ),
                                  onPressed: () {
                                    _toggleTaskCompletion(task);
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.edit,
                                      color: Colors.blue),
                                  onPressed: () {
                                    _showEditTaskDialog(context, task);
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete,
                                      color: Colors.red),
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
                  value: task['category'] ??
                      '', // Pastikan task['category'] tidak null
                  items: taskProvider.categories
                      .toSet() // Menghapus duplikasi kategori
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
                )
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
}
