import '../../entities/user_entity.dart';
import '../../repositories/auth_repository.dart';
import '../usecase.dart';

class UpdateUserUsecase implements Usecase<void, UserEntity> {
  final AuthRepository repository;

  const UpdateUserUsecase(this.repository);

  @override
  Future<void> call(UserEntity params) async {
    if (params.uid.isEmpty) {
      throw ArgumentError('User ID cannot be empty');
    }
    if (params.email.isEmpty) {
      throw ArgumentError('Email cannot be empty');
    }
    if (params.name.isEmpty) {
      throw ArgumentError('Name cannot be empty');
    }

    try {
      await repository.updateUser(params);
    } catch (e) {
      throw Exception('Failed to update user: ${e.toString()}');
    }
  }
}
