// lib/src/data/classes/class_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

/// ===================== CLASSROOM =====================
class ClassRoom {
  final String id;
  final String code;
  final String subject;
  final String grade;
  final String group;
  final String teacherId;
  final DateTime createdAt;

  ClassRoom({
    required this.id,
    required this.code,
    required this.subject,
    required this.grade,
    required this.group,
    required this.teacherId,
    required this.createdAt,
  });

  factory ClassRoom.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return ClassRoom(
      id: doc.id,
      code: (data['code'] ?? '').toString(),
      subject: (data['subject'] ?? '').toString(),
      grade: (data['grade'] ?? '').toString(),
      group: (data['group'] ?? '').toString(),
      teacherId: (data['teacherId'] ?? data['ownerUid'] ?? '').toString(),
      createdAt:
      (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
    'code': code,
    'subject': subject,
    'grade': grade,
    'group': group,
    'teacherId': teacherId,
    'createdAt': createdAt,
  };

  String get displayName => '$grade$group · $subject';
}

/// ===================== CLASS MEMBER =====================
class ClassMember {
  final String uid;            // doc.id en subcolección members
  final String role;           // 'teacher' | 'student'
  final String? displayName;   // opcional si guardas nombre
  final DateTime joinedAt;

  ClassMember({
    required this.uid,
    required this.role,
    required this.joinedAt,
    this.displayName,
  });

  factory ClassMember.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return ClassMember(
      uid: doc.id,
      role: (data['role'] ?? 'student').toString(),
      displayName: data['displayName'] as String?,
      joinedAt:
      (data['joinedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

/// ===================== ASSIGNMENT =====================
class Assignment {
  final String id;
  final String classId;
  final String title;
  final String? description;
  final String teacherId;
  final DateTime createdAt;
  final DateTime? dueAt;

  Assignment({
    required this.id,
    required this.classId,
    required this.title,
    required this.description,
    required this.teacherId,
    required this.createdAt,
    required this.dueAt,
  });

  /// Soporta 1 o 2 argumentos. Si no pasas classId, lo deduce del path.
  factory Assignment.fromDoc(
      DocumentSnapshot<Map<String, dynamic>> doc, [
        String? classId,
      ]) {
    final data = doc.data() ?? {};
    final deducedClassId = classId ?? doc.reference.parent.parent?.id ?? '';
    return Assignment(
      id: doc.id,
      classId: deducedClassId,
      title: (data['title'] ?? '').toString(),
      description: data['description'] as String?,
      teacherId: (data['teacherId'] ?? '').toString(),
      createdAt:
      (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      dueAt: (data['dueAt'] as Timestamp?)?.toDate(),
    );
  }
}

/// ===================== SUBMISSION =====================
class Submission {
  final String id;           // studentUid (si usas studentUid como docId)
  final String classId;
  final String assignmentId;
  final String studentId;
  final String? note;
  final String? fileName;
  final String? fileUrl;
  final double? gradeScore;
  final double? gradeMax;
  final String? feedback;
  final DateTime? submittedAt;
  final DateTime? gradedAt;

  double? get percent =>
      (gradeScore != null && gradeMax != null && gradeMax! > 0)
          ? (gradeScore! / gradeMax!) * 100
          : null;

  Submission({
    required this.id,
    required this.classId,
    required this.assignmentId,
    required this.studentId,
    required this.note,
    required this.fileName,
    required this.fileUrl,
    required this.gradeScore,
    required this.gradeMax,
    required this.feedback,
    required this.submittedAt,
    required this.gradedAt,
  });

  /// Soporta 1, 2 o 3 argumentos (doc [, classId [, assignmentId]]).
  /// Si no pasas IDs, los deduce del path:
  /// classes/{classId}/assignments/{assignmentId}/submissions/{studentUid}
  factory Submission.fromDoc(
      DocumentSnapshot<Map<String, dynamic>> doc, [
        String? classId,
        String? assignmentId,
      ]) {
    final data = doc.data() ?? {};
    final deducedAssignmentId = assignmentId ?? doc.reference.parent.parent?.id ?? '';
    final deducedClassId =
        classId ?? doc.reference.parent.parent?.parent?.parent?.id ?? '';

    return Submission(
      id: doc.id,
      classId: deducedClassId,
      assignmentId: deducedAssignmentId,
      studentId: (data['studentId'] ?? doc.id).toString(),
      note: data['note'] as String?,
      fileName: data['fileName'] as String?,
      fileUrl: data['fileUrl'] as String?,
      gradeScore: (data['gradeScore'] as num?)?.toDouble(),
      gradeMax: (data['gradeMax'] as num?)?.toDouble(),
      feedback: data['feedback'] as String?,
      submittedAt: (data['submittedAt'] as Timestamp?)?.toDate(),
      gradedAt: (data['gradedAt'] as Timestamp?)?.toDate(),
    );
  }
}

/// ===================== CLASS EVALUATION =====================
class ClassEvaluation {
  final String id;
  final String classId;
  final String studentId;
  final double score;
  final double maxScore;
  final String? learningStyle;
  final DateTime createdAt;

  ClassEvaluation({
    required this.id,
    required this.classId,
    required this.studentId,
    required this.score,
    required this.maxScore,
    required this.learningStyle,
    required this.createdAt,
  });

  double get percent => maxScore == 0 ? 0 : (score / maxScore) * 100;

  /// Soporta 1 o 2 argumentos. Si no pasas classId, lo deduce del path:
  /// classes/{classId}/evaluations/{evalId}
  factory ClassEvaluation.fromDoc(
      DocumentSnapshot<Map<String, dynamic>> doc, [
        String? classId,
      ]) {
    final data = doc.data() ?? {};
    final deducedClassId = classId ?? doc.reference.parent.parent?.id ?? '';
    return ClassEvaluation(
      id: doc.id,
      classId: deducedClassId,
      studentId: (data['studentId'] ?? '').toString(),
      score: (data['score'] as num?)?.toDouble() ?? 0,
      maxScore: (data['maxScore'] as num?)?.toDouble() ?? 100,
      learningStyle: data['learningStyle'] as String?,
      createdAt:
      (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

/// ===================== CLASS METRICS (DTO) =====================
class ClassMetrics {
  final double averagePercent;
  final double medianPercent;
  final int totalEvaluations;
  final Map<String, int> learningStyleCounts;

  const ClassMetrics({
    required this.averagePercent,
    required this.medianPercent,
    required this.totalEvaluations,
    required this.learningStyleCounts,
  });
}
//5TYZV4