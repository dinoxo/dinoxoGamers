class ReviewSnapshot {
  final double? criticScore;
  final double? userScore;
  final double? openCriticScore;
  final String? metacriticUrl;
  final String? openCriticUrl;
  final String sourceUrl;
  final DateTime checkedAt;
  const ReviewSnapshot(
      {this.criticScore,
      this.userScore,
      this.openCriticScore,
      this.metacriticUrl,
      this.openCriticUrl,
      required this.sourceUrl,
      required this.checkedAt});
  double? get primaryScore =>
      criticScore ?? openCriticScore ?? (userScore != null ? userScore! * 10 : null);

  String get verdictBadgeLabel {
    final score = primaryScore;
    if (score == null) return 'Sin calificar';
    if (score >= 85) return '¡Compra Imprescindible!';
    if (score >= 75) return '¡Muy Recomendado!';
    if (score >= 65) return 'Vale la pena con oferta';
    if (score >= 50) return 'Solo para fans';
    return 'No recomendado';
  }

  bool get isWorthBuying {
    final score = primaryScore;
    if (score == null) return false;
    return score >= 75;
  }

  String get verdictExplanation {
    final score = primaryScore;
    if (score == null) {
      return 'No hay suficientes calificaciones registradas de Metacritic u OpenCritic para emitir un veredicto de compra.';
    }
    if (score >= 85) {
      return 'Con una puntuación sobresaliente (${score.toStringAsFixed(0)}/100), la crítica especializada y la comunidad consideran que vale totalmente la pena comprarlo. Es un título de máxima calidad.';
    }
    if (score >= 75) {
      return 'Con una valoración positiva (${score.toStringAsFixed(0)}/100), ofrece una experiencia sólida y muy divertida. Vale la pena adquirirlo, especialmente si te atrae su propuesta.';
    }
    if (score >= 65) {
      return 'Con una puntuación promedio (${score.toStringAsFixed(0)}/100), el título tiene elementos rescatables pero también irregularidades. Te recomendamos esperar una buena oferta antes de comprarlo.';
    }
    if (score >= 50) {
      return 'Con una recepción mixta (${score.toStringAsFixed(0)}/100), el juego tiene fallos notables. Solo vale la pena si sos fanático absoluto del género o de la saga.';
    }
    return 'Con una calificación baja (${score.toStringAsFixed(0)}/100), el juego presenta serios problemas técnicos o de diseño. No te recomendamos gastar en este juego.';
  }

  String get summary {
    final parts = <String>[];
    if (criticScore != null) {
      parts.add(
          'Metacritic: ${criticScore!.toStringAsFixed(0)}/100 en crítica.');
    }
    if (userScore != null) {
      parts.add('Usuarios de Metacritic: ${userScore!.toStringAsFixed(1)}/10.');
    }
    if (openCriticScore != null) {
      parts.add('OpenCritic: ${openCriticScore!.toStringAsFixed(0)}/100.');
    }
    if (parts.isEmpty) {
      return 'No hay puntuaciones verificables disponibles para este juego.';
    }
    return parts.join(' ');
  }

  Map<String, dynamic> toMap() => {
        'criticScore': criticScore,
        'userScore': userScore,
        'openCriticScore': openCriticScore,
        'metacriticUrl': metacriticUrl,
        'openCriticUrl': openCriticUrl,
        'sourceUrl': sourceUrl,
        'checkedAt': checkedAt.toIso8601String()
      };
  factory ReviewSnapshot.fromMap(Map<String, dynamic> m) => ReviewSnapshot(
      criticScore: (m['criticScore'] as num?)?.toDouble(),
      userScore: (m['userScore'] as num?)?.toDouble(),
      openCriticScore: (m['openCriticScore'] as num?)?.toDouble(),
      metacriticUrl: m['metacriticUrl'] as String?,
      openCriticUrl: m['openCriticUrl'] as String?,
      sourceUrl: m['sourceUrl'] as String,
      checkedAt: DateTime.parse(m['checkedAt'] as String));
}
