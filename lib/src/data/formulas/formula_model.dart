import 'package:cloud_firestore/cloud_firestore.dart';

class FormulaModel {
  final String id;
  final String titulo;
  final String latex;
  final String explicacion;
  final String tema;            // 'Física' | 'Matemáticas' | 'Química' | ''
  final String condicionesUso;  // string con viñetas o líneas
  final String estado;          // 'activa' | 'borrador' | 'archivada'

  FormulaModel({
    required this.id,
    required this.titulo,
    required this.latex,
    required this.explicacion,
    required this.tema,
    required this.condicionesUso,
    required this.estado,
  });

  factory FormulaModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? const {};
    return FormulaModel(
      id: doc.id,
      titulo: (d['titulo'] ?? '') as String,
      latex: (d['latex_expresion'] ?? d['latex'] ?? d['expression'] ?? '') as String,
      explicacion: (d['explicacion'] ?? d['summary'] ?? '') as String,
      tema: (d['tema'] ?? d['topic'] ?? '') as String,
      condicionesUso: (d['condiciones_uso'] ?? '') as String,
      estado: (d['estado'] ?? 'activa') as String,
    );
  }

  Map<String, dynamic> toJson() => {
    'titulo': titulo,
    'latex_expresion': latex,
    'explicacion': explicacion,
    'tema': tema,
    'condiciones_uso': condicionesUso,
    'estado': estado,
  };
}