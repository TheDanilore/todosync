import 'package:cloud_firestore/cloud_firestore.dart';
import '../data/models/task_model.dart';

class FirestoreService {
  final CollectionReference tasksRef = FirebaseFirestore.instance.collection('tasks');

  Future<void> addTask(TaskModel task) async {
    await tasksRef.doc(task.id).set(task.toMap());
  }

  Future<void> updateTask(TaskModel task) async {
    await tasksRef.doc(task.id).update({'isCompleted': task.isCompleted});
  }

  Stream<List<TaskModel>> getTasks() {
    return tasksRef.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => TaskModel.fromMap(doc.data() as Map<String, dynamic>)).toList();
    });
  }

  Future<void> deleteTask(String taskId) async {
    await tasksRef.doc(taskId).delete();
  }
}
