import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:whatbytes/taskModel.dart';


class TaskRepository {
  late Database _database;

  Future<void> init() async {
    final dbPath = join(await getDatabasesPath(), 'tasks.db');
    _database = await openDatabase(
      dbPath,
      version: 1,
      onCreate: (db, version) {
        return db.execute(
          'CREATE TABLE tasks(id INTEGER PRIMARY KEY AUTOINCREMENT, title TEXT, description TEXT, dueDate TEXT, priority TEXT, isCompleted INTEGER)',
        );
      },
    );
  }

  Future<List<Task>> getTasks() async {
    final maps = await _database.query('tasks');
    return maps.map((map) => Task.fromMap(map)).toList();
  }

  Future<void> addTask(Task task) async {
    await _database.insert('tasks', task.toMap());
  }

  Future<void> updateTask(Task task) async {
    await _database.update('tasks', task.toMap(), where: 'id = ?', whereArgs: [task.id]);
  }

  Future<void> deleteTask(int id) async {
    await _database.delete('tasks', where: 'id = ?', whereArgs: [id]);
  }
}
