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
    return '${parts.join(' ')} Estas puntuaciones orientan la compra; no describen por sí solas el rendimiento en tu consola.';
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
