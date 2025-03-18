import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:todosync/data/models/task_model.dart';
import 'package:todosync/domain/repositories/task_repository.dart';

class TaskRepositoryImpl implements TaskRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  @override
  Future<void> addTask(TaskModel task) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Usuario no autenticado');
    
    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('tasks')
        .doc(task.id)
        .set(task.toMap());
  }
  
  @override
  Future<void> updateTask(TaskModel task) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Usuario no autenticado');
    
    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('tasks')
        .doc(task.id)
        .update(task.toMap());
  }
  
  @override
  Future<void> deleteTask(String taskId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Usuario no autenticado');
    
    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('tasks')
        .doc(taskId)
        .delete();
  }
  
  @override
  Stream<List<TaskModel>> getTasks() {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Usuario no autenticado');
    
    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('tasks')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => TaskModel.fromMap(doc.data()))
              .toList();
        });
  }
}