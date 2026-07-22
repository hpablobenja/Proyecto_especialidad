import 'package:cloud_firestore/cloud_firestore.dart';

class DataUserModel {
  final String userId;
  int currentSessionMinutes; // Minutos en la sesión actual
  int totalSessionMinutes; // Total de minutos acumulados
  DateTime? sessionStartTime; // Hora de inicio de la sesión actual
  DateTime lastSessionEnd; // Hora de fin de la última sesión
  Map<String, double> categoryProgress; // Progreso por categoría
  double overallProgress; // Progreso general
  List<String> unlockedAchievements; // Logros desbloqueados
  DateTime updatedAt;

  DataUserModel({
    required this.userId,
    this.currentSessionMinutes = 0,
    this.totalSessionMinutes = 0,
    this.sessionStartTime,
    required this.lastSessionEnd,
    required this.categoryProgress,
    required this.overallProgress,
    required this.unlockedAchievements,
    required this.updatedAt,
  });

  factory DataUserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    // Safely parse category progress to handle ints stored in Firestore as doubles
    Map<String, double> parsedCategoryProgress = {
      'Ciencias Sociales': 0.0,
      'Ciencias Naturales': 0.0,
      'Comunicación y Lenguaje': 0.0,
      'Alternativa': 0.0,
      'Otro(Especificar)': 0.0,
    };

    if (data['categoryProgress'] != null) {
      final map = data['categoryProgress'] as Map<String, dynamic>;
      map.forEach((key, value) {
        parsedCategoryProgress[key] = (value as num).toDouble();
      });
    }

    return DataUserModel(
      userId: doc.id,
      currentSessionMinutes: data['currentSessionMinutes'] ?? 0,
      totalSessionMinutes: data['totalSessionMinutes'] ?? 0,
      sessionStartTime: data['sessionStartTime'] != null 
          ? (data['sessionStartTime'] as Timestamp).toDate() 
          : null,
      lastSessionEnd: data['lastSessionEnd'] != null
          ? (data['lastSessionEnd'] as Timestamp).toDate()
          : DateTime.now(),
      categoryProgress: parsedCategoryProgress,
      overallProgress: (data['overallProgress'] as num?)?.toDouble() ?? 0.0,
      unlockedAchievements: List<String>.from(data['unlockedAchievements'] ?? []),
      updatedAt: data['updatedAt'] != null 
          ? (data['updatedAt'] as Timestamp).toDate() 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'currentSessionMinutes': currentSessionMinutes,
      'totalSessionMinutes': totalSessionMinutes,
      if (sessionStartTime != null) 'sessionStartTime': Timestamp.fromDate(sessionStartTime!),
      'lastSessionEnd': Timestamp.fromDate(lastSessionEnd),
      'categoryProgress': categoryProgress,
      'overallProgress': overallProgress,
      'unlockedAchievements': unlockedAchievements,
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  DataUserModel copyWith({
    String? userId,
    int? currentSessionMinutes,
    int? totalSessionMinutes,
    DateTime? sessionStartTime,
    DateTime? lastSessionEnd,
    Map<String, double>? categoryProgress,
    double? overallProgress,
    List<String>? unlockedAchievements,
    DateTime? updatedAt,
  }) {
    return DataUserModel(
      userId: userId ?? this.userId,
      currentSessionMinutes: currentSessionMinutes ?? this.currentSessionMinutes,
      totalSessionMinutes: totalSessionMinutes ?? this.totalSessionMinutes,
      sessionStartTime: sessionStartTime ?? this.sessionStartTime,
      lastSessionEnd: lastSessionEnd ?? this.lastSessionEnd,
      categoryProgress: categoryProgress ?? this.categoryProgress,
      overallProgress: overallProgress ?? this.overallProgress,
      unlockedAchievements: unlockedAchievements ?? this.unlockedAchievements,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Formatear minutos a horas y minutos
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
  
  // Obtener tiempo total formateado (incluye el tiempo de la sesión actual para ser exacto en tiempo real)
  String get totalSessionFormatted => formatMinutes(totalSessionMinutes + currentSessionMinutes);
}
