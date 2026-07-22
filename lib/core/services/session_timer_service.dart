import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SessionTimerService {
  static final SessionTimerService _instance = SessionTimerService._internal();
  factory SessionTimerService() => _instance;
  SessionTimerService._internal();

  Timer? _timer;
  int _currentSessionMinutes = 0;
  int _totalSessionMinutes = 0;
  DateTime? _sessionStartTime;
  bool _isRunning = false;

  static const String _currentSessionKey = 'current_session_minutes';
  static const String _totalSessionKey = 'total_session_minutes';
  static const String _sessionStartKey = 'session_start_time';

  int get currentSessionMinutes => _currentSessionMinutes;
  int get totalSessionMinutes => _totalSessionMinutes;
  bool get isRunning => _isRunning;

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    _currentSessionMinutes = prefs.getInt(_currentSessionKey) ?? 0;
    _totalSessionMinutes = prefs.getInt(_totalSessionKey) ?? 0;
    
    final startTimeMillis = prefs.getInt(_sessionStartKey);
    if (startTimeMillis != null) {
      _sessionStartTime = DateTime.fromMillisecondsSinceEpoch(startTimeMillis);
    }
  }

  Future<void> _saveToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_currentSessionKey, _currentSessionMinutes);
    await prefs.setInt(_totalSessionKey, _totalSessionMinutes);
    
    if (_sessionStartTime != null) {
      await prefs.setInt(_sessionStartKey, _sessionStartTime!.millisecondsSinceEpoch);
    }
  }

  Future<void> startSession() async {
    if (_isRunning) return;
    
    await _loadFromPrefs();
    
    _sessionStartTime = DateTime.now();
    _currentSessionMinutes = 0;
    _isRunning = true;
    
    await _saveToPrefs();
    await _updateFirestore();
    
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(minutes: 1), (timer) async {
      _currentSessionMinutes++;
      _totalSessionMinutes++;
      
      await _saveToPrefs();
      await _updateFirestore();
    });
  }

  Future<void> stopSession() async {
    if (!_isRunning) return;
    
    _timer?.cancel();
    _timer = null;
    _isRunning = false;
    
    await _saveToPrefs();
    await _updateFirestore();
    
    // Reset current session but keep total
    _currentSessionMinutes = 0;
    _sessionStartTime = null;
    await _saveToPrefs();
  }

  Future<void> _updateFirestore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');
      
      if (userId == null) return;
      
      final firestore = FirebaseFirestore.instance;
      
      await firestore.collection('dataUser').doc(userId).set({
        'currentSessionMinutes': _currentSessionMinutes,
        'totalSessionMinutes': _totalSessionMinutes,
        'sessionStartTime': _sessionStartTime != null 
            ? Timestamp.fromDate(_sessionStartTime!)
            : null,
        'lastSessionEnd': Timestamp.now(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      print('Error updating Firestore session data: $e');
    }
  }

  Future<void> resetCurrentSession() async {
    _currentSessionMinutes = 0;
    _sessionStartTime = null;
    await _saveToPrefs();
    await _updateFirestore();
  }

  void dispose() {
    _timer?.cancel();
    _timer = null;
  }
}
