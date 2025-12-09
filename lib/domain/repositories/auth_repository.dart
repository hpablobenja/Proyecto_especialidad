// lib/domain/repositories/auth_repository.dart

import '../entities/user_entity.dart';

abstract class AuthRepository {
  Future<UserEntity> registerWithEmailAndPassword(
    String email,
    String password,
    String name,
    String role,
  );
  Future<UserEntity> signInWithEmailAndPassword(String email, String password);
  Future<void> signOut();
  Future<UserEntity?> getCurrentUser();
  Future<void> updateUser(UserEntity user);
}
