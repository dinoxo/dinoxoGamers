import 'package:flutter/material.dart';

enum NewsPortal {
  tresDJuegos,
  vandal,
  metacritic,
}

class NewsArticle {
  const NewsArticle({
    required this.id,
    required this.title,
    required this.description,
    required this.url,
    this.imageUrl,
    this.publishedAt,
    required this.portal,
  });

  final String id;
  final String title;
  final String description;
  final String url;
  final String? imageUrl;
  final DateTime? publishedAt;
  final NewsPortal portal;

  String get portalDisplayName => switch (portal) {
        NewsPortal.tresDJuegos => '3DJuegos',
        NewsPortal.vandal => 'Vandal',
        NewsPortal.metacritic => 'Metacritic',
      };

  Color get portalColor => switch (portal) {
        NewsPortal.tresDJuegos => const Color(0xFFE53935),
        NewsPortal.vandal => const Color(0xFF1E88E5),
        NewsPortal.metacritic => const Color(0xFFFFB300),
      };
}
