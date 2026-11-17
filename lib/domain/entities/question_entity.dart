// lib/domain/entities/question_entity.dart

import 'package:equatable/equatable.dart';

class QuestionEntity extends Equatable {
  final String id;
  final String text;
  final List<String> options; // 3 opciones
  final int? correctAnswerIndex; // Índice de la respuesta correcta (0-2), solo presente para admin o evaluación

  const QuestionEntity({
    required this.id,
    required this.text,
    required this.options,
    this.correctAnswerIndex,
  });

  QuestionEntity copyWith({
    String? id,
    String? text,
    List<String>? options,
    int? correctAnswerIndex,
  }) {
    return QuestionEntity(
      id: id ?? this.id,
      text: text ?? this.text,
      options: options ?? this.options,
      correctAnswerIndex: correctAnswerIndex ?? this.correctAnswerIndex,
    );
  }

  @override
  List<Object?> get props => [id, text, options, correctAnswerIndex];

  Map<String, dynamic> toMap({bool includeCorrectAnswer = false}) {
    final map = <String, dynamic>{
      'id': id,
      'text': text,
      'options': options,
    };
    if (includeCorrectAnswer && correctAnswerIndex != null) {
      map['correctAnswerIndex'] = correctAnswerIndex;
    }
    return map;
  }

  factory QuestionEntity.fromMap(Map<String, dynamic> map) {
    return QuestionEntity(
      id: map['id'] as String,
      text: map['text'] as String,
      options: List<String>.from(map['options'] as List),
      correctAnswerIndex: map['correctAnswerIndex'] as int?,
    );
  }
}
