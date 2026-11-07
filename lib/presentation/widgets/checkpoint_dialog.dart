// lib/presentation/widgets/checkpoint_dialog.dart

import 'package:flutter/material.dart';
import '../../domain/entities/checkpoint_entity.dart';

/// Dialog para mostrar preguntas de checkpoint
/// Se muestra automáticamente cuando el video alcanza una posición de checkpoint
class CheckpointDialog extends StatefulWidget {
  final CheckpointEntity checkpoint;
  final Function(int) onAnswerSelected;

  const CheckpointDialog({
    super.key,
    required this.checkpoint,
    required this.onAnswerSelected,
  });

  @override
  State<CheckpointDialog> createState() => _CheckpointDialogState();
}

class _CheckpointDialogState extends State<CheckpointDialog> {
  int? _selectedIndex;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.quiz, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          const Text('Checkpoint'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pregunta ${widget.checkpoint.triggerPositionSeconds ~/ 60}:${(widget.checkpoint.triggerPositionSeconds % 60).toString().padLeft(2, '0')}',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            Text(
              widget.checkpoint.question,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            ...widget.checkpoint.options.asMap().entries.map((entry) {
              final index = entry.key;
              final option = entry.value;
              final isSelected = _selectedIndex == index;

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _selectedIndex = index;
                    });
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color:
                            isSelected
                                ? Theme.of(context).colorScheme.primary
                                : Colors.grey[300]!,
                        width: isSelected ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(8),
                      color:
                          isSelected
                              ? Theme.of(
                                context,
                              ).colorScheme.primary.withOpacity(0.1)
                              : Colors.transparent,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color:
                                  isSelected
                                      ? Theme.of(context).colorScheme.primary
                                      : Colors.grey[400]!,
                              width: 2,
                            ),
                          ),
                          child:
                              isSelected
                                  ? Center(
                                    child: Icon(
                                      Icons.check,
                                      size: 16,
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                    ),
                                  )
                                  : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            option,
                            style: TextStyle(
                              color:
                                  isSelected
                                      ? Theme.of(context).colorScheme.primary
                                      : Colors.black87,
                              fontWeight:
                                  isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed:
              _selectedIndex != null
                  ? () {
                    widget.onAnswerSelected(_selectedIndex!);
                  }
                  : null,
          child: const Text('Confirmar'),
        ),
      ],
    );
  }
}
