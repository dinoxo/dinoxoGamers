class PriceObservation {
  final String id;
  final String editionId;
  final double price;
  final DateTime recordedAt;
  final bool isDiscounted;
  final String source;

  const PriceObservation({
    required this.id,
    required this.editionId,
    required this.price,
    required this.recordedAt,
    this.isDiscounted = false,
    this.source = 'Dinoxo Tracker',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'editionId': editionId,
      'price': price,
      'recordedAt': recordedAt.toIso8601String(),
      'isDiscounted': isDiscounted ? 1 : 0,
      'source': source,
    };
  }

  factory PriceObservation.fromMap(Map<String, dynamic> map) {
    return PriceObservation(
      id: map['id'] as String,
      editionId: map['editionId'] as String,
      price: (map['price'] as num).toDouble(),
      recordedAt: DateTime.parse(map['recordedAt'] as String),
      isDiscounted: (map['isDiscounted'] == 1 || map['isDiscounted'] == true),
      source: map['source'] as String? ?? 'Dinoxo Tracker',
    );
  }
}
