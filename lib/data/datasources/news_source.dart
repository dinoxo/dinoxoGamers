import 'dart:convert';
import 'package:html/parser.dart' as html;
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import '../../domain/models/news_article.dart';

class NewsSource {
  NewsSource({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  void close() => _client.close();

  static const _headers = {
    'Accept-Language': 'es-ES,es;q=0.9,en-US;q=0.8,en;q=0.7',
    'User-Agent':
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36 DinoxoGamers/1.0',
  };

  Future<List<NewsArticle>> fetchAllNews() async {
    final results = await Future.wait([
      fetch3DJuegos().catchError((_) => <NewsArticle>[]),
      fetchVandal().catchError((_) => <NewsArticle>[]),
      fetchMetacritic().catchError((_) => <NewsArticle>[]),
    ]);
    final all = results.expand((list) => list).toList();
    all.sort((a, b) {
      final dateA = a.publishedAt;
      final dateB = b.publishedAt;
      if (dateA != null && dateB != null) return dateB.compareTo(dateA);
      if (dateA != null) return -1;
      if (dateB != null) return 1;
      return 0;
    });
    return all;
  }

  Future<List<NewsArticle>> fetchByPortal(NewsPortal portal) async {
    final list = switch (portal) {
      NewsPortal.tresDJuegos => await fetch3DJuegos(),
      NewsPortal.vandal => await fetchVandal(),
      NewsPortal.metacritic => await fetchMetacritic(),
    };
    list.sort((a, b) {
      final dateA = a.publishedAt;
      final dateB = b.publishedAt;
      if (dateA != null && dateB != null) return dateB.compareTo(dateA);
      if (dateA != null) return -1;
      if (dateB != null) return 1;
      return 0;
    });
    return list;
  }

  Future<List<NewsArticle>> fetch3DJuegos() async {
    final uri = Uri.parse('https://www.3djuegos.com/index.xml');
    final response = await _client
        .get(uri, headers: _headers)
        .timeout(const Duration(seconds: 15));
    if (response.statusCode != 200) return [];
    final body = utf8.decode(response.bodyBytes, allowMalformed: true);
    return parseRss(body, NewsPortal.tresDJuegos, defaultHost: 'https://www.3djuegos.com');
  }

  Future<List<NewsArticle>> fetchVandal() async {
    final uri = Uri.parse('https://vandal.elespanol.com/xml.cgi');
    final response = await _client
        .get(uri, headers: _headers)
        .timeout(const Duration(seconds: 15));
    if (response.statusCode != 200) return [];
    // Vandal often sends iso-8859-1 or utf-8
    String body;
    try {
      body = utf8.decode(response.bodyBytes);
    } catch (_) {
      body = latin1.decode(response.bodyBytes);
    }
    return parseRss(body, NewsPortal.vandal, defaultHost: 'https://vandal.elespanol.com');
  }

  Future<List<NewsArticle>> fetchMetacritic() async {
    final uri = Uri.parse(
        'https://backend.metacritic.com/components/metacritic/listing/filtered/latest-news/web?componentName=latest-news&componentDisplayName=Latest+News&componentType=ContentList&limit=30');
    final response = await _client
        .get(uri, headers: _headers)
        .timeout(const Duration(seconds: 15));
    if (response.statusCode != 200) return [];
    final json = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    final data = json['data'] as Map<String, dynamic>?;
    final items = (data?['items'] as List<dynamic>?) ?? [];
    final articles = <NewsArticle>[];

    for (final item in items) {
      if (item is! Map<String, dynamic>) continue;
      final id = item['id']?.toString() ?? '';
      final title = item['title']?.toString() ?? '';
      final desc = item['description']?.toString() ?? '';
      final slug = item['slug']?.toString() ?? '';
      final url = item['url']?.toString() ??
          (slug.isNotEmpty ? 'https://www.metacritic.com/news/$slug' : '');
      final imgMap = item['image'] as Map<String, dynamic>?;
      final imgPath = imgMap?['path']?.toString();

      DateTime? pubDate;
      final dateObj = item['datePublished'];
      if (dateObj is Map<String, dynamic> && dateObj['date'] != null) {
        pubDate = DateTime.tryParse(dateObj['date'].toString().replaceAll(' ', 'T'));
      }

      if (title.isNotEmpty && url.isNotEmpty) {
        articles.add(NewsArticle(
          id: id.isNotEmpty ? id : url,
          title: title.trim(),
          description: desc.trim(),
          url: url,
          imageUrl: (imgPath != null && imgPath.startsWith('http')) ? imgPath : null,
          publishedAt: pubDate,
          portal: NewsPortal.metacritic,
        ));
      }
    }
    return articles;
  }

  static List<NewsArticle> parseRss(String xmlBody, NewsPortal portal, {required String defaultHost}) {
    final articles = <NewsArticle>[];
    final items = RegExp(r'<item>([\s\S]*?)</item>', caseSensitive: false).allMatches(xmlBody);

    for (final match in items) {
      final itemContent = match.group(1) ?? '';
      final titleMatch = RegExp(r'<title>(?:<!\[CDATA\[)?([\s\S]*?)(?:\]\]>)?</title>', caseSensitive: false)
          .firstMatch(itemContent);
      final linkMatch = RegExp(r'<link>(?:<!\[CDATA\[)?([\s\S]*?)(?:\]\]>)?</link>', caseSensitive: false)
          .firstMatch(itemContent);
      final descMatch = RegExp(r'<description>(?:<!\[CDATA\[)?([\s\S]*?)(?:\]\]>)?</description>', caseSensitive: false)
          .firstMatch(itemContent);
      final dateMatch = RegExp(r'<pubDate>(?:<!\[CDATA\[)?([\s\S]*?)(?:\]\]>)?</pubDate>', caseSensitive: false)
          .firstMatch(itemContent);
      final enclosureMatch = RegExp(r'<enclosure[^>]+url=["\x27]([^"\x27]+)["\x27]', caseSensitive: false)
          .firstMatch(itemContent);
      final mediaMatch = RegExp(r'<media:content[^>]+url=["\x27]([^"\x27]+)["\x27]', caseSensitive: false)
          .firstMatch(itemContent);

      final rawTitle = titleMatch?.group(1)?.trim() ?? '';
      final rawLink = linkMatch?.group(1)?.trim() ?? '';
      final rawDesc = descMatch?.group(1)?.trim() ?? '';
      final rawDate = dateMatch?.group(1)?.trim() ?? '';

      if (rawTitle.isEmpty || rawLink.isEmpty) continue;

      // Extract image URL from enclosure, media:content or <img> in description
      String? imageUrl = enclosureMatch?.group(1) ?? mediaMatch?.group(1);
      if (imageUrl == null && rawDesc.isNotEmpty) {
        final imgInDesc = RegExp(r'<img[^>]+src=["\x27]([^"\x27]+)["\x27]', caseSensitive: false).firstMatch(rawDesc);
        imageUrl = imgInDesc?.group(1);
      }

      // Strip HTML tags from description
      final cleanDesc = rawDesc
          .replaceAll(RegExp(r'<[^>]*>'), '')
          .replaceAll(RegExp(r'&nbsp;'), ' ')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();

      DateTime? pubDate = _parseRssDate(rawDate);

      articles.add(NewsArticle(
        id: rawLink,
        title: _cleanText(rawTitle),
        description: cleanDesc,
        url: rawLink.startsWith('http') ? rawLink : '$defaultHost$rawLink',
        imageUrl: (imageUrl != null && imageUrl.startsWith('http')) ? imageUrl : null,
        publishedAt: pubDate,
        portal: portal,
      ));
    }

    return articles;
  }

  static String _cleanText(String text) {
    return text
        .replaceAll(RegExp(r'&amp;'), '&')
        .replaceAll(RegExp(r'&quot;'), '"')
        .replaceAll(RegExp(r'&#039;'), "'")
        .replaceAll(RegExp(r'&lt;'), '<')
        .replaceAll(RegExp(r'&gt;'), '>')
        .trim();
  }

  static final _months = {
    'jan': 1, 'feb': 2, 'mar': 3, 'apr': 4, 'may': 5, 'jun': 6,
    'jul': 7, 'aug': 8, 'sep': 9, 'oct': 10, 'nov': 11, 'dec': 12,
  };

  static DateTime? _parseRssDate(String dateStr) {
    if (dateStr.isEmpty) return null;
    final clean = dateStr.trim();
    final iso = DateTime.tryParse(clean);
    if (iso != null) return iso;

    final match = RegExp(
      r'(\d{1,2})\s+([A-Za-z]{3})\w*\s+(\d{4})\s+(\d{1,2}):(\d{2})(?::(\d{2}))?',
    ).firstMatch(clean);
    if (match != null) {
      final day = int.tryParse(match.group(1)!);
      final monthStr = match.group(2)!.toLowerCase();
      final month = _months[monthStr];
      final year = int.tryParse(match.group(3)!);
      final hour = int.tryParse(match.group(4)!);
      final minute = int.tryParse(match.group(5)!);
      final second = int.tryParse(match.group(6) ?? '0');

      if (day != null && month != null && year != null && hour != null && minute != null) {
        return DateTime.utc(year, month, day, hour, minute, second ?? 0);
      }
    }
    return null;
  }
}
