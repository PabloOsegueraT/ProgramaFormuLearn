enum Subject { fisica, matematicas, quimica }

Subject guessSubject(String text) {
  final s = text.toLowerCase();

  // palabras clave simples
  final phys = ['fuerza','velocidad','aceleración','energia','trabajo','newton','mru','gravedad','masa','m/s','n','julio','péndulo'];
  final math = ['derivada','integral','ecuación','polinomio','matriz','logaritmo','limite','función','álgebra','geometría'];
  final chem = ['ph','mol','molaridad','reacción','ácido','base','equilibrio','electrones','compuesto','disolución','estequiometría'];

  int hit(List<String> ws) => ws.where((w) => s.contains(w)).length;

  final scFis = hit(phys);
  final scMat = hit(math);
  final scQuim = hit(chem);

  if (scFis >= scMat && scFis >= scQuim) return Subject.fisica;
  if (scMat >= scFis && scMat >= scQuim) return Subject.matematicas;
  return Subject.quimica;
}