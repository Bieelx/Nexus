import 'package:cloud_firestore/cloud_firestore.dart';

// A classe `CourseProgress` continua a mesma
class CourseProgress {
  final Set<String> completed;
  final Map<String, int> lastPage;
  final int lastCompletedOrder;
  final int totalModules;
  final double progress;

  CourseProgress({
    required this.completed,
    required this.lastPage,
    required this.lastCompletedOrder,
    required this.totalModules,
    required this.progress,
  });

  factory CourseProgress.empty() => CourseProgress(
        completed: <String>{},
        lastPage: <String, int>{},
        lastCompletedOrder: -1,
        totalModules: 0,
        progress: 0.0,
      );

  factory CourseProgress.fromMap(Map<String, dynamic> m) => CourseProgress(
        completed: (m['completed'] as List?)?.map((e) => e.toString()).toSet() ?? <String>{},
        lastPage: (m['lastPage'] as Map?)?.map((k, v) => MapEntry(k.toString(), (v ?? 0) as int)) ??
            <String, int>{},
        lastCompletedOrder: (m['lastCompletedOrder'] ?? -1) as int,
        totalModules: (m['totalModules'] ?? 0) as int,
        progress: (m['progress'] as num?)?.toDouble() ?? 0.0,
      );
}

class CourseProgressService {
  final _db = FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> _progressDoc(String uid, String courseId) =>
      _db.collection('users').doc(uid).collection(courseId).doc('progress');
  
  // Helper para o documento principal do usuário
  DocumentReference<Map<String, dynamic>> _userDoc(String uid) =>
      _db.collection('users').doc(uid);


  Stream<CourseProgress> watch(String uid, String courseId) {
    return _progressDoc(uid, courseId).snapshots().map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) {
        return CourseProgress.empty();
      }
      return CourseProgress.fromMap(snapshot.data()!);
    });
  }

  // --- NOVA FUNÇÃO ---
  /// Atualiza o documento principal do usuário com informações sobre o último curso acessado.
  Future<void> updateLastAccessed({
    required String uid,
    required String courseId,
    required String courseName,
  }) async {
    await _userDoc(uid).set({
      'lastAccessedCourse': {
        'id': courseId,
        'name': courseName,
        'lastAccess': FieldValue.serverTimestamp(),
      }
    }, SetOptions(merge: true));
  }
  // --------------------

  Future<void> markCompleted({
    required String uid,
    required String courseId,
    required String moduleId,
    int? moduleOrder,
    required int totalModules,
  }) async {
    final progressRef = _progressDoc(uid, courseId);
    await _db.runTransaction((transaction) async {
      final snapshot = await transaction.get(progressRef);
      if (!snapshot.exists) {
        transaction.set(progressRef, {
          'completed': [moduleId], 'totalModules': totalModules,
          'progress': totalModules > 0 ? 1 / totalModules : 0.0,
          'lastCompletedOrder': moduleOrder ?? -1,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        final data = snapshot.data()!;
        final List<dynamic> completedList = List.from(data['completed'] ?? []);
        if (!completedList.contains(moduleId)) completedList.add(moduleId);
        final newProgress = totalModules > 0 ? completedList.length / totalModules : 0.0;
        transaction.update(progressRef, {
          'completed': completedList, 'totalModules': totalModules,
          'progress': newProgress,
          'lastCompletedOrder': moduleOrder ?? data['lastCompletedOrder'],
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    });
  }

  Future<void> setLastPage({
    required String uid,
    required String courseId,
    required String moduleId,
    required int page,
  }) async {
    final progressRef = _progressDoc(uid, courseId);
    await progressRef.set({
      'lastPage': {moduleId: page},
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}