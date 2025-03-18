import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:todosync/data/models/task_model.dart';
import 'package:todosync/presentation/pages/add_task_screen.dart';
import 'package:todosync/presentation/pages/profile_screen.dart';
import 'package:todosync/presentation/pages/task_detail_screen.dart';
import 'package:todosync/presentation/widgets/task_card.dart';
import 'package:intl/intl.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  String _filter = 'all'; // 'all', 'completed', 'pending'

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('ToDoSync'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Filtros
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _buildFilterChip('Todas', 'all'),
                const SizedBox(width: 8),
                _buildFilterChip('Pendientes', 'pending'),
                const SizedBox(width: 8),
                _buildFilterChip('Completadas', 'completed'),
              ],
            ),
          ),

          // Fecha actual
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Text(
                  DateFormat('EEEE, d MMMM', 'es').format(DateTime.now()),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                Text(
                  'Mis Tareas',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),

          // Lista de tareas
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _getTasksStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error al cargar las tareas',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          size: 80,
                          color: Theme.of(context).textTheme.bodySmall!.color!.withOpacity(0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No hay tareas',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Theme.of(context).textTheme.bodySmall!.color,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Añade una nueva tarea para comenzar',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  );
                }

                final tasks = snapshot.data!.docs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return TaskModel(
                    id: doc.id,
                    title: data['title'] ?? '',
                    description: data['description'] ?? '',
                    isCompleted: data['isCompleted'] ?? false,
                    createdAt: data['createdAt'] != null
                        ? (data['createdAt'] as Timestamp).toDate()
                        : DateTime.now(),
                    dueDate: data['dueDate'] != null
                        ? (data['dueDate'] as Timestamp).toDate()
                        : null,
                  );
                }).toList();

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: tasks.length,
                  itemBuilder: (context, index) {
                    final task = tasks[index];
                    return TaskCard(
                      task: task,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => TaskDetailScreen(taskId: task.id),
                          ),
                        );
                      },
                      onStatusChanged: (value) {
                        _toggleTaskStatus(task.id, value ?? false);
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const AddTaskScreen()),
          );
        },
        backgroundColor: Theme.of(context).colorScheme.primary,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildFilterChip(String label, String filterValue) {
    final isSelected = _filter == filterValue;

    return GestureDetector(
      onTap: () {
        setState(() {
          _filter = filterValue;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Theme.of(context).colorScheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).textTheme.bodySmall!.color!,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Theme.of(context).textTheme.bodySmall!.color,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Stream<QuerySnapshot> _getTasksStream() {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream.empty();
    }

    var query = _firestore
        .collection('users')
        .doc(user.uid)
        .collection('tasks')
        .orderBy('createdAt', descending: true);

    if (_filter == 'completed') {
      query = query.where('isCompleted', isEqualTo: true);
    } else if (_filter == 'pending') {
      query = query.where('isCompleted', isEqualTo: false);
    }

    return query.snapshots();
  }

  Future<void> _toggleTaskStatus(String taskId, bool isCompleted) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('tasks')
        .doc(taskId)
        .update({'isCompleted': isCompleted});
  }
}
