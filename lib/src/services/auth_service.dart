// lib/src/services/auth_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  AuthService._();
  static final instance = AuthService._();

  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;

  /// Crea el usuario en Auth y su documento base en Firestore (ID = uid).
  Future<String> signUp({
    required String name,
    required String email,
    required String password,
    required int age,
    required String level,      // 'Bachillerato' | 'Universidad' | 'Otro'
    required String role,       // 'alumno' | 'profesor' | 'admin' (solo visual)
    String? prefLearning,       // etiqueta amigable
    String? dailyMinutes,       // '10-15' | '20-30' | '40+'
    List<String>? mainSubjects, // ['Matemáticas', ...]
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final uid = cred.user!.uid;

    final emailLower = email.trim().toLowerCase();

    // ⚠️ Claves en ESPAÑOL para cumplir tus reglas
    await _db.collection('users').doc(uid).set({
      'uid'        : uid,
      'nombre'     : name.trim(),
      'correo'     : emailLower,
      'rol'        : role,            // 'alumno' | 'profesor' | 'admin'
      'edad'       : age,
      'nivel'      : level,
      'preferencias': {
        if (prefLearning != null)          'aprendizaje'  : prefLearning,
        if (dailyMinutes != null)          'minutosDiarios': dailyMinutes,
        if (mainSubjects != null && mainSubjects.isNotEmpty)
          'materias'     : mainSubjects,
      },
      'creadoEn'    : FieldValue.serverTimestamp(), // <- lo que validan tus reglas
      'actualizadoEn': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    return uid;
  }

  /// Guarda/actualiza campos del perfil del usuario (merge).
  Future<void> saveUserProfile({
    required String uid,
    required Map<String, dynamic> data,
  }) async {
    await _db.collection('users').doc(uid).set({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Guarda el perfil VARK unificado:
  /// - Snapshot actual en users/{uid}.learningProfile
  /// - Historial en users/{uid}/learningTests/{autoId}
  Future<void> saveLearningProfile({
    required String uid,
    required Map<String, int> counts,  // {'V':x,'A':y,'R':z,'K':w}
    required String predominant,       // 'V' | 'A' | 'R' | 'K'
    String instrument = 'VARK',
    String version = '1.0',
    String? classId,
  }) async {
    final total = counts.values.fold<int>(0, (a, b) => a + b);
    double pct(String k) => total == 0 ? 0.0 : (counts[k] ?? 0) / total;

    final distribution = <String, double>{
      'V': pct('V'),
      'A': pct('A'),
      'R': pct('R'),
      'K': pct('K'),
    };

    final payload = {
      'instrument': instrument,
      'version': version,
      'predominant': predominant,
      'counts': counts,
      'total': total,
      'distribution': distribution, // valores 0..1
      'computedAt': FieldValue.serverTimestamp(),
      if (classId != null) 'classId': classId,
    };

    final userRef = _db.collection('users').doc(uid);

    // Snapshot actual
    await userRef.set({'learningProfile': payload}, SetOptions(merge: true));

    // Historial
    await userRef.collection('learningTests').add(payload);
  }

  /// Iniciar sesión → devuelve uid.
  Future<String> signIn({
    required String email,
    required String password,
  }) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    return cred.user!.uid;
  }

  Future<void> signOut() async => _auth.signOut();

  /// Lee rol desde Firestore (solo para UI). En reglas no cuenta como admin.
  Future<String> fetchRole(String uid) async {
    final snap = await _db.collection('users').doc(uid).get();
    final data = snap.data();

    // Lee 'role' o, si no existe, 'rol'
    final raw = (data?['role'] ?? data?['rol']) as String?;
    final v = raw?.trim().toLowerCase();

    // Normaliza y valida
    const allowed = {'alumno', 'profesor', 'admin'};
    return (v != null && allowed.contains(v)) ? v : 'alumno';
  }
}