// lib/domain/usecases/auth/register_usecase.dart

import '../usecase.dart';
import '../../entities/user_entity.dart';
import '../../repositories/auth_repository.dart';

class RegisterUsecase implements Usecase<UserEntity, RegisterParams> {
  final AuthRepository repository;

  RegisterUsecase(this.repository);

  @override
  Future<UserEntity> call(RegisterParams params) async {
    return await repository.registerWithEmailAndPassword(
      params.email,
      params.password,
      params.name,
      params.role,
    );
  }
}

class RegisterParams {
  final String email;
  final String password;
  final String name;
  final String role;

  RegisterParams({
    required this.email,
    required this.password,
    required this.name,
    required this.role,
  });
}
