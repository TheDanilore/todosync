// lib/presentation/widgets/task_card.dart
import 'package:flutter/material.dart';
import 'package:todosync/config/theme.dart';
import 'package:todosync/data/models/task_model.dart';
import 'package:intl/intl.dart';

class TaskCard extends StatelessWidget {
  final TaskModel task;
  final VoidCallback onTap;
  final Function(bool?) onStatusChanged;
  
  const TaskCard({
    super.key,
    required this.task,
    required this.onTap,
    required this.onStatusChanged,
  });
  
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Checkbox para marcar como completada
              Checkbox(
                value: task.isCompleted,
                onChanged: onStatusChanged,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
                activeColor: AppTheme.primaryColor,
              ),
              const SizedBox(width: 12),
              // Contenido de la tarea
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        decoration: task.isCompleted
                            ? TextDecoration.lineThrough
                            : TextDecoration.none,
                        color: task.isCompleted
                            ? AppTheme.textSecondaryColor
                            : AppTheme.textPrimaryColor,
                      ),
                    ),
                    if (task.description.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        task.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.textSecondaryColor,
                          decoration: task.isCompleted
                              ? TextDecoration.lineThrough
                              : TextDecoration.none,
                        ),
                      ),
                    ],
                    if (task.dueDate != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 14,
                            color: _getDueDateColor(task.dueDate!),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            DateFormat('dd MMM, yyyy').format(task.dueDate!),
                            style: TextStyle(
                              fontSize: 12,
                              color: _getDueDateColor(task.dueDate!),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              // Indicador de prioridad o categoría (opcional)
              Container(
                width: 4,
                height: 40,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Color _getDueDateColor(DateTime dueDate) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dueDay = DateTime(dueDate.year, dueDate.month, dueDate.day);
    
    if (dueDay.isBefore(today)) {
      return AppTheme.errorColor; // Vencida
    } else if (dueDay.isAtSameMomentAs(today)) {
      return AppTheme.warningColor; // Hoy
    } else {
      return AppTheme.textSecondaryColor; // Futura
    }
  }
}