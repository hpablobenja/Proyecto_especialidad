// lib/domain/entities/question_entity.dart

import 'package:equatable/equatable.dart';

class QuestionEntity extends Equatable {
  final String id;
  final String text;
  final List<String> options; // 3 opciones
  final int correctAnswerIndex; // Índice de la respuesta correcta (0-2)

  const QuestionEntity({
    required this.id,
    required this.text,
    required this.options,
    required this.correctAnswerIndex,
  });

  @override
  List<Object?> get props => [id, text, options, correctAnswerIndex];

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'text': text,
      'options': options,
      'correctAnswerIndex': correctAnswerIndex,
    };
  }

  factory QuestionEntity.fromMap(Map<String, dynamic> map) {
    return QuestionEntity(
      id: map['id'] as String,
      text: map['text'] as String,
      options: List<String>.from(map['options'] as List),
      correctAnswerIndex: map['correctAnswerIndex'] as int,
    );
  }
}

