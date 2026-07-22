// lib/domain/entities/user_entity.dart

import 'package:equatable/equatable.dart';

class UserEntity extends Equatable {
  final String uid;
  final String email;
  final String name;
  final String role; // 'maestro' o 'admin'
  final String? workArea; // 'Urbano' o 'Rural'
  final String? specialty; // 'Educación Inicial', 'Educación Primaria', 'Matemática', 'Biología y Geografía', 'Física', 'Química', 'Lengua Extranjera', 'Artes Plásticas', 'Educación Musical', 'Otros'

  const UserEntity({
    required this.uid,
    required this.email,
    required this.name,
    required this.role,
    this.workArea,
    this.specialty,
  });

  @override
  List<Object?> get props => [uid, email, name, role, workArea, specialty];
}
