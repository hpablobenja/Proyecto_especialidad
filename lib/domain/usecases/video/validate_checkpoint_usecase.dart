// lib/domain/usecases/video/validate_checkpoint_usecase.dart

import '../../repositories/video_tracking_repository.dart';
import '../../../core/services/checkpoint_service.dart';

/// Use case para validar la respuesta de un checkpoint
class ValidateCheckpointUsecase {
  final CheckpointRepository checkpointRepository;
  final CheckpointService checkpointService;

  ValidateCheckpointUsecase({
    required this.checkpointRepository,
    required this.checkpointService,
  });

  /// Ejecuta el use case
  /// Retorna el resultado de la validación
  Future<CheckpointValidationResult> call({
    required String checkpointId,
    required int selectedOptionIndex,
  }) async {
    // Validar respuesta usando el servicio (que tiene los checkpoints en memoria)
    final result = checkpointService.validateAnswer(
      checkpointId: checkpointId,
      selectedOptionIndex: selectedOptionIndex,
    );

    // Si la validación falló porque no encontró el checkpoint, retornar error
    if (!result.isCorrect && result.message == 'Checkpoint no encontrado') {
      return result;
    }

    // Actualizar estado en repositorio
    if (result.isCorrect) {
      await checkpointRepository.markCheckpointPassed(checkpointId);
    } else {
      await checkpointRepository.incrementCheckpointAttempts(checkpointId);
    }

    return result;
  }
}
