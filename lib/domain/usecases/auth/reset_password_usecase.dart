import '../../repositories/auth_repository.dart';
import '../usecase.dart';

class ResetPasswordUsecase implements Usecase<void, String> {
  final AuthRepository repository;

  const ResetPasswordUsecase(this.repository);

  @override
  Future<void> call(String email) async {
    if (email.isEmpty) {
      throw ArgumentError('Email cannot be empty');
    }

    try {
      await repository.resetPassword(email);
    } catch (e) {
      throw Exception('Failed to reset password: ${e.toString()}');
    }
  }
}
