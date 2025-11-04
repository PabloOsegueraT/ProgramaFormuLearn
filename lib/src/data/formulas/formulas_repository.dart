import 'package:cloud_firestore/cloud_firestore.dart';
import 'formula_model.dart';

class FormulaRepository {
  CollectionReference<Map<String, dynamic>> get _col =>
      FirebaseFirestore.instance.collection('formulas');

  Stream<List<FormulaModel>> streamAll({String? tema}) {
    Query<Map<String, dynamic>> q = _col.where('estado', isEqualTo: 'activa');
    if (tema != null && tema.isNotEmpty) {
      q = q.where('tema', isEqualTo: tema);
    }
    q = q.orderBy('titulo');
    return q.snapshots().map(
          (s) => s.docs.map((d) => FormulaModel.fromDoc(d)).toList(),
    );
  }

  Future<List<FormulaModel>> getAllOnce({String? tema}) async {
    Query<Map<String, dynamic>> q = _col.where('estado', isEqualTo: 'activa');
    if (tema != null && tema.isNotEmpty) {
      q = q.where('tema', isEqualTo: tema);
    }
    q = q.orderBy('titulo');
    final snap = await q.get();
    return snap.docs.map((d) => FormulaModel.fromDoc(d)).toList();
  }

  Future<FormulaModel?> getById(String id) async {
    final doc = await _col.doc(id).get();
    if (!doc.exists) return null;
    return FormulaModel.fromDoc(doc as DocumentSnapshot<Map<String, dynamic>>);
  }
}