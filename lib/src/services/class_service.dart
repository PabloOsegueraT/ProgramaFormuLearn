// lib/src/services/class_service.dart
import 'dart:math';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../data/classes/class_model.dart';

class ClassService {
  ClassService._();
  static final instance = ClassService._();

  final _db = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;

  /* ===================== CLASES ===================== */

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
      'displayName': null,
      'uid': teacherId,
    });

    final snap = await docRef.get() as DocumentSnapshot<Map<String, dynamic>>;
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
    final memberRef = classDoc.reference.collection('members').doc(studentId);

    await memberRef.set({
      'role': 'student',
      'joinedAt': FieldValue.serverTimestamp(),
      'displayName': null,
      'uid': studentId,
    }, SetOptions(merge: true));
  }

  /// Clases del profesor (SIN índices compuestos)
  Future<List<ClassRoom>> teacherClassesOnce(String teacherId) async {
    // Solo filtramos por teacherId (sin orderBy) y ordenamos en memoria.
    final q = await _db
        .collection('classes')
        .where('teacherId', isEqualTo: teacherId)
        .get();

    final list = q.docs
        .map((d) =>
        ClassRoom.fromDoc(d as DocumentSnapshot<Map<String, dynamic>>))
        .toList();

    list.sort((a, b) {
      final ta = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final tb = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return tb.compareTo(ta); // desc
    });
    return list;
  }

  /// Clases donde el usuario es miembro (sin collectionGroup)
  Future<List<ClassRoom>> studentClassesOnce(String uid) async {
    final classesSnap = await _db.collection('classes').get();
    final result = <ClassRoom>[];

    for (final doc in classesSnap.docs) {
      final member =
      await doc.reference.collection('members').doc(uid).get();
      if (member.exists) {
        result.add(ClassRoom.fromDoc(
            doc as DocumentSnapshot<Map<String, dynamic>>));
      }
    }

    result.sort((a, b) {
      final ta = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final tb = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return tb.compareTo(ta);
    });
    return result;
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

  Future<void> leaveClass({
    required String classId,
    required String uid,
  }) async {
    final doc = await _db.collection('classes').doc(classId).get();
    final data = doc.data() ?? {};
    final owner = (data['teacherId'] ?? data['ownerUid']) as String?;
    if (owner != null && owner == uid) {
      throw Exception('El profesor debe eliminar la clase en lugar de salir.');
    }
    await _db
        .collection('classes')
        .doc(classId)
        .collection('members')
        .doc(uid)
        .delete();
  }

  Future<void> deleteClass(String classId) async {
    await _db.collection('classes').doc(classId).delete();
  }

  /* ===================== ACTIVIDADES ===================== */

  Stream<List<Assignment>> assignmentsStream(String classId) {
    return _db
        .collection('classes')
        .doc(classId)
        .collection('assignments')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs
        .map((d) => Assignment.fromDoc(
        d as DocumentSnapshot<Map<String, dynamic>>))
        .toList());
  }

  Future<void> createAssignment({
    required String classId,
    required String teacherId,
    required String title,
    String? description,
    DateTime? dueAt,
  }) async {
    final col =
    _db.collection('classes').doc(classId).collection('assignments');

    await col.add({
      'title': title,
      'description': description,
      'teacherId': teacherId,
      'createdAt': FieldValue.serverTimestamp(),
      'dueAt': dueAt != null ? Timestamp.fromDate(dueAt) : null,
    });
  }

  Stream<List<Submission>> submissionsStream({
    required String classId,
    required String assignmentId,
  }) {
    final col = _db
        .collection('classes')
        .doc(classId)
        .collection('assignments')
        .doc(assignmentId)
        .collection('submissions');

    return col.snapshots().map((s) => s.docs
        .map((d) =>
        Submission.fromDoc(d as DocumentSnapshot<Map<String, dynamic>>))
        .toList());
  }

  Stream<Submission?> mySubmissionStream({
    required String classId,
    required String assignmentId,
    required String studentId,
  }) {
    final docRef = _db
        .collection('classes')
        .doc(classId)
        .collection('assignments')
        .doc(assignmentId)
        .collection('submissions')
        .doc(studentId);

    return docRef.snapshots().map((doc) => doc.exists
        ? Submission.fromDoc(
        doc as DocumentSnapshot<Map<String, dynamic>>)
        : null);
  }

  Future<void> submitAssignment({
    required String classId,
    required String assignmentId,
    required String studentId,
    String? note,
    String? fileName,
    Uint8List? fileBytes,
    String? filePath,
  }) async {
    final docRef = _db
        .collection('classes')
        .doc(classId)
        .collection('assignments')
        .doc(assignmentId)
        .collection('submissions')
        .doc(studentId);

    String? storagePath;
    String? finalFileName;

    if (fileBytes != null && fileBytes.isNotEmpty) {
      try {
        finalFileName =
        (fileName == null || fileName.isEmpty) ? 'adjunto' : fileName;
        storagePath =
        'classes/$classId/assignments/$assignmentId/$studentId/$finalFileName';
        final ref = _storage.ref(storagePath);
        await ref.putData(fileBytes);
      } catch (_) {
        storagePath = null;
        finalFileName = null;
      }
    }

    final data = <String, dynamic>{
      'studentId': studentId,
      'note': note,
      'fileName': finalFileName,
      'storagePath': storagePath,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    final existing = await docRef.get();
    if (!existing.exists) {
      data['createdAt'] = FieldValue.serverTimestamp();
    }

    await docRef.set(data, SetOptions(merge: true));
  }

  Future<void> gradeSubmission({
    required String classId,
    required String assignmentId,
    required String studentId,
    required double score,
    required double maxScore,
    String? feedback,
  }) async {
    final docRef = _db
        .collection('classes')
        .doc(classId)
        .collection('assignments')
        .doc(assignmentId)
        .collection('submissions')
        .doc(studentId);

    await docRef.set({
      'gradeScore': score,
      'gradeMax': maxScore,
      'feedback': feedback,
      'gradedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /* ===================== EVALUACIONES ===================== */

  Future<void> addEvaluation({
    required String classId,
    required String studentId,
    required double score,
    required double maxScore,
    String? learningStyle,
  }) async {
    final col =
    _db.collection('classes').doc(classId).collection('evaluations');

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
    final col =
    _db.collection('classes').doc(classId).collection('evaluations');

    return col
        .where('studentId', isEqualTo: studentId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
        .map((d) => ClassEvaluation.fromDoc(
        d as DocumentSnapshot<Map<String, dynamic>>))
        .toList());
  }

  Stream<ClassMetrics> metricsForClass(String classId) {
    final col =
    _db.collection('classes').doc(classId).collection('evaluations');

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
            doc as DocumentSnapshot<Map<String, dynamic>>);
        scores.add(e.percent);

        final style = e.learningStyle ?? 'sin_clasificar';
        styleCounts[style] = (styleCounts[style] ?? 0) + 1;
      }

      scores.sort();
      final n = scores.length;
      final avg = scores.reduce((a, b) => a + b) / n;
      final median =
      n.isOdd ? scores[n ~/ 2] : (scores[n ~/ 2 - 1] + scores[n ~/ 2]) / 2;

      return ClassMetrics(
        averagePercent: avg,
        medianPercent: median,
        totalEvaluations: n,
        learningStyleCounts: styleCounts,
      );
    });
  }

  /* ===================== ACTIVIDAD / PORTAFOLIO ===================== */

  Future<void> logActivity({
    required String classId,
    required String studentId,
    required String type,
    String? formulaId,
    String? topic,
  }) async {
    final col = _db.collection('classes').doc(classId).collection('activity');

    await col.add({
      'studentId': studentId,
      'type': type,
      'formulaId': formulaId,
      'topic': topic,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /* ===================== HELPERS ===================== */

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
