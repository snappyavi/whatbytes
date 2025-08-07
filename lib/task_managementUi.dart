import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:whatbytes/login_screen.dart';

class TaskManagementUI extends StatefulWidget {
  const TaskManagementUI({super.key});

  @override
  State<TaskManagementUI> createState() => _TaskManagementUIState();
}

class _TaskManagementUIState extends State<TaskManagementUI> {
  late Database database;
  List<Task> allTasks = [];
  String searchQuery = '';
  String selectedPriority = 'All';
  String selectedStatus = 'All';

  @override
  void initState() {
    super.initState();
    _initDatabase();
  }

  Future<void> _initDatabase() async {
    final path = join(await getDatabasesPath(), 'tasks.db');
    database = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) {
        return db.execute(
          'CREATE TABLE tasks(id INTEGER PRIMARY KEY, title TEXT, description TEXT, dueDate TEXT, priority TEXT, isCompleted INTEGER)',
        );
      },
    );
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    final List<Map<String, dynamic>> maps = await database.query('tasks');
    setState(() {
      allTasks =
          maps
              .map(
                (map) => Task(
                  id: map['id'],
                  title: map['title'],
                  description: map['description'],
                  dueDate: DateTime.parse(map['dueDate']),
                  priority: map['priority'],
                  isCompleted: map['isCompleted'] == 1,
                ),
              )
              .toList();
    });
  }

  Future<void> _addTask(Task task) async {
    final id = await database.insert('tasks', {
      'title': task.title,
      'description': task.description,
      'dueDate': task.dueDate.toIso8601String(),
      'priority': task.priority,
      'isCompleted': task.isCompleted ? 1 : 0,
    });

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      await FirebaseFirestore.instance.collection('tasks').add({
        'title': task.title,
        'description': task.description,
        'dueDate': task.dueDate.toIso8601String(),
        'priority': task.priority,
        'isCompleted': task.isCompleted,
      });
      print("Uploaded to Firestore: ${task.title}");
    }

    _loadTasks();
  }

  Future<void> _updateTask(Task task) async {
    await database.update(
      'tasks',
      {
        'title': task.title,
        'description': task.description,
        'dueDate': task.dueDate.toIso8601String(),
        'priority': task.priority,
        'isCompleted': task.isCompleted ? 1 : 0,
      },
      where: 'id = ?',
      whereArgs: [task.id],
    );

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null && task.id != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('tasks')
          .doc(task.id.toString())
          .set(task.toMap(task.id));
    }

    _loadTasks();
  }

  Future<void> _deleteTask(int id) async {
    await database.delete('tasks', where: 'id = ?', whereArgs: [id]);

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('tasks')
          .doc(id.toString())
          .delete();
    }

    _loadTasks();
  }

  void _toggleComplete(Task task) async {
    task.isCompleted = !task.isCompleted;
    await _updateTask(task);
  }

  void _openTaskDialog({Task? task, required BuildContext context}) {
    final titleController = TextEditingController(text: task?.title ?? '');
    final descController = TextEditingController(text: task?.description ?? '');
    DateTime? dueDate = task?.dueDate;
    String priority = task?.priority ?? 'Low';

    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: Text(task == null ? 'Add Task' : 'Edit Task'),
            content: SingleChildScrollView(
              child: Column(
                children: [
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(labelText: 'Title'),
                  ),
                  TextField(
                    controller: descController,
                    decoration: const InputDecoration(labelText: 'Description'),
                  ),
                  DropdownButtonFormField(
                    value: priority,
                    decoration: const InputDecoration(labelText: 'Priority'),
                    items:
                        ['Low', 'Medium', 'High']
                            .map(
                              (e) => DropdownMenuItem(value: e, child: Text(e)),
                            )
                            .toList(),
                    onChanged: (val) => priority = val!,
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: dueDate ?? DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        setState(() => dueDate = picked);
                      }
                    },
                    child: Text(
                      dueDate == null
                          ? 'Pick Date'
                          : dueDate!.toString().split(' ')[0],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (titleController.text.isNotEmpty && dueDate != null) {
                    final newTask = Task(
                      id: task?.id,
                      title: titleController.text,
                      description: descController.text,
                      dueDate: dueDate!,
                      priority: priority,
                      isCompleted: task?.isCompleted ?? false,
                    );
                    task == null ? _addTask(newTask) : _updateTask(newTask);
                    Navigator.pop(context);
                  }
                },
                child: Text(task == null ? 'Add' : 'Update'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredTasks =
        allTasks.where((task) {
            final matchesSearch = task.title.toLowerCase().contains(
              searchQuery.toLowerCase(),
            );
            final matchesPriority =
                selectedPriority == 'All' || task.priority == selectedPriority;
            final matchesStatus =
                selectedStatus == 'All' ||
                (selectedStatus == 'Completed' && task.isCompleted) ||
                (selectedStatus == 'Incomplete' && !task.isCompleted);
            return matchesSearch && matchesPriority && matchesStatus;
          }).toList()
          ..sort((a, b) => a.dueDate.compareTo(b.dueDate));

    return Scaffold(
      appBar: AppBar(
        actions: [
          Theme(
            data: Theme.of(
              context,
            ).copyWith(iconTheme: const IconThemeData(color: Colors.white)),
            child: PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded),
              onSelected: (value) async {
                if (value == 'signout') {
                  await FirebaseAuth.instance.signOut();
                  if (context.mounted) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                    );
                  }
                }
              },
              itemBuilder:
                  (context) => [
                    const PopupMenuItem<String>(
                      value: 'signout',
                      child: Text('Sign Out'),
                    ),
                  ],
            ),
          ),
        ],
        automaticallyImplyLeading: false,
        leading: Icon(Icons.menu, color: Colors.white),
        title: const Text(
          'Task Manager',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF6C63FF),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Search Tasks',
              ),
              onChanged: (val) => setState(() => searchQuery = val),
            ),
            Row(
              children: [
                Expanded(
                  child: DropdownButton<String>(
                    value: selectedPriority,
                    items:
                        ['All', 'Low', 'Medium', 'High']
                            .map(
                              (e) => DropdownMenuItem(
                                value: e,
                                child: Text('Priority: $e'),
                              ),
                            )
                            .toList(),
                    onChanged: (val) => setState(() => selectedPriority = val!),
                  ),
                ),
                Expanded(
                  child: DropdownButton<String>(
                    value: selectedStatus,
                    items:
                        ['All', 'Completed', 'Incomplete']
                            .map(
                              (e) => DropdownMenuItem(
                                value: e,
                                child: Text('Status: $e'),
                              ),
                            )
                            .toList(),
                    onChanged: (val) => setState(() => selectedStatus = val!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: filteredTasks.length,
                itemBuilder: (_, index) {
                  final task = filteredTasks[index];
                  return Card(
                    child: ListTile(
                      leading: Checkbox(
                        value: task.isCompleted,
                        onChanged: (_) => _toggleComplete(task),
                      ),
                      title: Text(task.title),
                      subtitle: Text(
                        '${task.description}\nDue: ${task.dueDate.toString().split(' ')[0]}\nPriority: ${task.priority}',
                      ),
                      isThreeLine: true,
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed:
                                () => _openTaskDialog(
                                  task: task,
                                  context: context,
                                ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deleteTask(task.id!),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openTaskDialog(context: context),
        backgroundColor: const Color(0xFF6C63FF),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

class Task {
  final int? id;
  final String title;
  final String description;
  final DateTime dueDate;
  final String priority;
  bool isCompleted;

  Task({
    this.id,
    required this.title,
    required this.description,
    required this.dueDate,
    required this.priority,
    this.isCompleted = false,
  });

  Map<String, dynamic> toMap(int? idOverride) {
    return {
      'id': idOverride ?? id,
      'title': title,
      'description': description,
      'dueDate': dueDate.toIso8601String(),
      'priority': priority,
      'isCompleted': isCompleted,
    };
  }

  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'],
      title: map['title'],
      description: map['description'],
      dueDate: DateTime.parse(map['dueDate']),
      priority: map['priority'],
      isCompleted: map['isCompleted'] == true || map['isCompleted'] == 1,
    );
  }
}
