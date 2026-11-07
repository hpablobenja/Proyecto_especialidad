// lib/data/models/data_user_hive.dart

import 'package:hive/hive.dart';

part 'data_user_hive.g.dart';

/// Modelo Hive para persistencia local de datos del dashboard
/// Permite mostrar datos offline y sincronizar cuando sea necesario
@HiveType(typeId: 7)
class DataUserHive {
  @HiveField(0)
  String userId;

  @HiveField(1)
  int currentSessionMinutes;

  @HiveField(2)
  int totalSessionMinutes;

  @HiveField(3)
  DateTime? sessionStartTime;

  @HiveField(4)
  DateTime lastSessionEnd;

  @HiveField(5)
  Map<String, double> categoryProgress;

  @HiveField(6)
  double overallProgress;

  @HiveField(7)
  List<String> unlockedAchievements;

  @HiveField(8)
  DateTime updatedAt;

  @HiveField(9)
  int totalCourses;

  @HiveField(10)
  int completedCourses;

  @HiveField(11)
  int inProgressCourses;

  DataUserHive({
    required this.userId,
    this.currentSessionMinutes = 0,
    this.totalSessionMinutes = 0,
    this.sessionStartTime,
    required this.lastSessionEnd,
    required this.categoryProgress,
    required this.overallProgress,
    required this.unlockedAchievements,
    required this.updatedAt,
    this.totalCourses = 0,
    this.completedCourses = 0,
    this.inProgressCourses = 0,
  });

  /// Convierte desde DataUserModel
  factory DataUserHive.fromDataUserModel(
    dynamic dataUserModel, {
    int totalCourses = 0,
    int completedCourses = 0,
    int inProgressCourses = 0,
  }) {
    return DataUserHive(
      userId: dataUserModel.userId,
      currentSessionMinutes: dataUserModel.currentSessionMinutes,
      totalSessionMinutes: dataUserModel.totalSessionMinutes,
      sessionStartTime: dataUserModel.sessionStartTime,
      lastSessionEnd: dataUserModel.lastSessionEnd,
      categoryProgress: dataUserModel.categoryProgress,
      overallProgress: dataUserModel.overallProgress,
      unlockedAchievements: dataUserModel.unlockedAchievements,
      updatedAt: dataUserModel.updatedAt,
      totalCourses: totalCourses,
      completedCourses: completedCourses,
      inProgressCourses: inProgressCourses,
    );
  }

  /// Convierte a Map
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'currentSessionMinutes': currentSessionMinutes,
      'totalSessionMinutes': totalSessionMinutes,
      'sessionStartTime': sessionStartTime?.toIso8601String(),
      'lastSessionEnd': lastSessionEnd.toIso8601String(),
      'categoryProgress': categoryProgress,
      'overallProgress': overallProgress,
      'unlockedAchievements': unlockedAchievements,
      'updatedAt': updatedAt.toIso8601String(),
      'totalCourses': totalCourses,
      'completedCourses': completedCourses,
      'inProgressCourses': inProgressCourses,
    };
  }

  /// Formatear minutos a horas y minutos
  String formatMinutes(int minutes) {
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    if (hours > 0) {
      return '${hours}h ${mins}m';
    }
    return '${mins}m';
  }

  // Obtener tiempo de sesión actual formateado
  String get currentSessionFormatted => formatMinutes(currentSessionMinutes);

  // Obtener tiempo total formateado
  String get totalSessionFormatted =>
      formatMinutes(totalSessionMinutes + currentSessionMinutes);
}
