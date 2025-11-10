import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../data/classes/class_model.dart';

class ClassService {
  ClassService._();
  static final instance = ClassService._();

  final _db = FirebaseFirestore.instance;

  // ---------- CLASES ----------

  Future<ClassRoom> createClass({
    required String teacherId,
    required String subject,
    required String grade,
    required String group,
  }) async {
    final code = await _generateUniqueCode();

    final docRef = _db.collection('classes').doc();
    await docRef.set({
      'code': code,
      'subject': subject,
      'grade': grade,
      'group': group,
      'teacherId': teacherId,
      'createdAt': FieldValue.serverTimestamp(),
    });

    await docRef.collection('members').doc(teacherId).set({
      'role': 'teacher',
      'joinedAt': FieldValue.serverTimestamp(),
    });

    final snap =
    await docRef.get() as DocumentSnapshot<Map<String, dynamic>>;
    return ClassRoom.fromDoc(snap);
  }

  Future<void> joinByCode({
    required String studentId,
    required String code,
  }) async {
    final query = await _db
        .collection('classes')
        .where('code', isEqualTo: code.trim().toUpperCase())
        .limit(1)
        .get();

    if (query.docs.isEmpty) {
      throw Exception('No existe una clase con ese código.');
    }

    final classDoc = query.docs.first;

    final memberRef =
    classDoc.reference.collection('members').doc(studentId);
    final memberSnap = await memberRef.get();

    if (!memberSnap.exists) {
      await memberRef.set({
        'role': 'student',
        'joinedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  Stream<List<ClassRoom>> teacherClasses(String teacherId) {
    return _db
        .collection('classes')
        .where('teacherId', isEqualTo: teacherId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs
        .map((d) =>
        ClassRoom.fromDoc(d as DocumentSnapshot<Map<String, dynamic>>))
        .toList());
  }

  Stream<List<ClassRoom>> studentClasses(String studentId) {
    return _db.collection('classes').snapshots().asyncMap((snapshot) async {
      final result = <ClassRoom>[];
      for (final doc in snapshot.docs) {
        final member = await doc.reference
            .collection('members')
            .doc(studentId)
            .get();
        if (member.exists) {
          result.add(
            ClassRoom.fromDoc(
                doc as DocumentSnapshot<Map<String, dynamic>>),
          );
        }
      }
      return result;
    });
  }

  Stream<ClassRoom?> classStream(String classId) {
    return _db
        .collection('classes')
        .doc(classId)
        .snapshots()
        .map((doc) => doc.exists
        ? ClassRoom.fromDoc(
        doc as DocumentSnapshot<Map<String, dynamic>>)
        : null);
  }

  Stream<List<ClassMember>> classMembers(String classId) {
    return _db
        .collection('classes')
        .doc(classId)
        .collection('members')
        .snapshots()
        .map((s) => s.docs
        .map((d) => ClassMember.fromDoc(
        d as DocumentSnapshot<Map<String, dynamic>>))
        .toList());
  }

  // ---------- EVALUACIONES ----------

  Future<void> addEvaluation({
    required String classId,
    required String studentId,
    required double score,
    required double maxScore,
    String? learningStyle,
  }) async {
    final col = _db
        .collection('classes')
        .doc(classId)
        .collection('evaluations');

    await col.add({
      'studentId': studentId,
      'score': score,
      'maxScore': maxScore,
      'learningStyle': learningStyle,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<ClassEvaluation>> studentEvaluations(
      String classId, String studentId) {
    final col = _db
        .collection('classes')
        .doc(classId)
        .collection('evaluations');

    return col
        .where('studentId', isEqualTo: studentId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
        .map((d) => ClassEvaluation.fromDoc(
        d as DocumentSnapshot<Map<String, dynamic>>, classId))
        .toList());
  }

  Stream<ClassMetrics> metricsForClass(String classId) {
    final col = _db
        .collection('classes')
        .doc(classId)
        .collection('evaluations');

    return col.snapshots().map((snap) {
      if (snap.docs.isEmpty) {
        return ClassMetrics(
          averagePercent: 0,
          medianPercent: 0,
          totalEvaluations: 0,
          learningStyleCounts: const {},
        );
      }

      final scores = <double>[];
      final styleCounts = <String, int>{};

      for (final doc in snap.docs) {
        final e = ClassEvaluation.fromDoc(
            doc as DocumentSnapshot<Map<String, dynamic>>, classId);
        final percent = e.percent;
        scores.add(percent);

        final style = e.learningStyle ?? 'sin_clasificar';
        styleCounts[style] = (styleCounts[style] ?? 0) + 1;
      }

      scores.sort();
      final n = scores.length;
      final avg = scores.reduce((a, b) => a + b) / n;
      final median = n.isOdd
          ? scores[n ~/ 2]
          : (scores[n ~/ 2 - 1] + scores[n ~/ 2]) / 2;

      return ClassMetrics(
        averagePercent: avg,
        medianPercent: median,
        totalEvaluations: n,
        learningStyleCounts: styleCounts,
      );
    });
  }

  // ---------- ACTIVIDAD ----------

  Future<void> logActivity({
    required String classId,
    required String studentId,
    required String type, // 'formula_view', 'evaluation', etc.
    String? formulaId,
    String? topic,
  }) async {
    final col = _db
        .collection('classes')
        .doc(classId)
        .collection('activity');

    await col.add({
      'studentId': studentId,
      'type': type,
      'formulaId': formulaId,
      'topic': topic,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // ---------- Helper para código único ----------

  Future<String> _generateUniqueCode() async {
    const chars = 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';
    final rand = Random.secure();

    while (true) {
      final code =
      List.generate(6, (_) => chars[rand.nextInt(chars.length)]).join();
      final snap = await _db
          .collection('classes')
          .where('code', isEqualTo: code)
          .limit(1)
          .get();
      if (snap.docs.isEmpty) return code;
    }
  }
}
