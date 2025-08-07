import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:whatbytes/taskModel.dart';
import 'package:whatbytes/taskRepository.dart';


final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  final repo = TaskRepository();
  repo.init(); // initialize DB
  return repo;
});

class TaskNotifier extends StateNotifier<List<Task>> {
  final TaskRepository repository;

  TaskNotifier(this.repository) : super([]) {
    loadTasks();
  }

  Future<void> loadTasks() async {
    state = await repository.getTasks();
  }

  Future<void> addTask(Task task) async {
    await repository.addTask(task);
    await loadTasks();
  }

  Future<void> updateTask(Task task) async {
    await repository.updateTask(task);
    await loadTasks();
  }

  Future<void> deleteTask(int id) async {
    await repository.deleteTask(id);
    await loadTasks();
  }

  Future<void> toggleCompletion(Task task) async {
    final updated = task.copyWith(isCompleted: !task.isCompleted);
    await updateTask(updated);
  }
}

final taskListProvider = StateNotifierProvider<TaskNotifier, List<Task>>((ref) {
  final repo = ref.watch(taskRepositoryProvider);
  return TaskNotifier(repo);
});
