import 'package:cloud_firestore/cloud_firestore.dart';

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
      code: (data['code'] ?? '') as String,
      subject: (data['subject'] ?? '') as String,
      grade: (data['grade'] ?? '') as String,
      group: (data['group'] ?? '') as String,
      teacherId: (data['teacherId'] ?? '') as String,
      createdAt: (data['createdAt'] is Timestamp)
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'code': code,
      'subject': subject,
      'grade': grade,
      'group': group,
      'teacherId': teacherId,
      'createdAt': createdAt,
    };
  }

  String get displayName => '$grade$group · $subject';
}

class ClassMember {
  final String uid;
  final String role;
  final DateTime joinedAt;

  ClassMember({
    required this.uid,
    required this.role,
    required this.joinedAt,
  });

  factory ClassMember.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return ClassMember(
      uid: doc.id,
      role: (data['role'] ?? 'student') as String,
      joinedAt: (data['joinedAt'] is Timestamp)
          ? (data['joinedAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }
}

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
    this.learningStyle,
    required this.createdAt,
  });

  double get percent => maxScore > 0 ? (score / maxScore) * 100.0 : 0.0;

  factory ClassEvaluation.fromDoc(
      DocumentSnapshot<Map<String, dynamic>> doc,
      String classId,
      ) {
    final data = doc.data() ?? {};
    return ClassEvaluation(
      id: doc.id,
      classId: classId,
      studentId: (data['studentId'] ?? '') as String,
      score: (data['score'] as num?)?.toDouble() ?? 0,
      maxScore: (data['maxScore'] as num?)?.toDouble() ?? 100,
      learningStyle: data['learningStyle'] as String?,
      createdAt: (data['createdAt'] is Timestamp)
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }
}

class ClassActivity {
  final String id;
  final String classId;
  final String studentId;
  final String type; // 'formula_view', 'evaluation', etc.
  final String? formulaId;
  final String? topic;
  final DateTime createdAt;

  ClassActivity({
    required this.id,
    required this.classId,
    required this.studentId,
    required this.type,
    this.formulaId,
    this.topic,
    required this.createdAt,
  });

  factory ClassActivity.fromDoc(
      DocumentSnapshot<Map<String, dynamic>> doc,
      String classId,
      ) {
    final data = doc.data() ?? {};
    return ClassActivity(
      id: doc.id,
      classId: classId,
      studentId: (data['studentId'] ?? '') as String,
      type: (data['type'] ?? '') as String,
      formulaId: data['formulaId'] as String?,
      topic: data['topic'] as String?,
      createdAt: (data['createdAt'] is Timestamp)
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }
}

class ClassMetrics {
  final double averagePercent;
  final double medianPercent;
  final int totalEvaluations;
  final Map<String, int> learningStyleCounts;

  ClassMetrics({
    required this.averagePercent,
    required this.medianPercent,
    required this.totalEvaluations,
    required this.learningStyleCounts,
  });
}
