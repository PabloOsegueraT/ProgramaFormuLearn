import 'package:flutter/material.dart';

class IAScreen extends StatelessWidget {
  const IAScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Resolver con IA')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Imagen de preview (simulación)
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: cs.surfaceVariant.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: cs.outline.withOpacity(0.3)),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.image_search, size: 80, color: cs.primary),
                    const SizedBox(height: 12),
                    const Text(
                      'Sube una foto o toma una foto\npara analizar con IA',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Botones grandes
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: cs.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      vertical: 16, horizontal: 20,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Tomar foto'),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Demo: abrir cámara 📷')),
                    );
                  },
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: cs.secondary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      vertical: 16, horizontal: 20,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.photo_library),
                  label: const Text('Subir foto'),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Demo: abrir galería 🖼️')),
                    );
                  },
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Resultado simulado
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Resultado (demo visual)',
                      style: TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'La IA identificó que se trata de un problema de MRU.\n'
                          'Fórmula sugerida: v = d / t\n'
                          'Explicación: la velocidad es constante y se calcula dividiendo la distancia recorrida entre el tiempo empleado.',
                      style: TextStyle(height: 1.4),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
