import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/datasources/news_source.dart';
import '../../../domain/models/news_article.dart';

class NewsScreen extends StatefulWidget {
  const NewsScreen({
    super.key,
    this.source,
  });

  final NewsSource? source;

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  late final NewsSource _source = widget.source ?? NewsSource();
  final _searchController = TextEditingController();
  Timer? _debounce;

  bool _loading = true;
  String? _error;
  List<NewsArticle> _articles = [];
  NewsPortal? _selectedPortal; // null means Todas
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadNews();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    if (widget.source == null) _source.close();
    super.dispose();
  }

  Future<void> _loadNews() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final list = _selectedPortal == null
          ? await _source.fetchAllNews()
          : await _source.fetchByPortal(_selectedPortal!);

      if (!mounted) return;
      setState(() {
        _articles = list;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'No se pudieron cargar las noticias. Comprueba tu conexión.';
        _loading = false;
      });
    }
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() => _searchQuery = value.trim().toLowerCase());
      }
    });
  }

  Future<void> _openArticle(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 60 && diff.inMinutes >= 0) {
      final mins = diff.inMinutes;
      return mins <= 1 ? 'Hace un momento' : 'Hace $mins min';
    }
    if (diff.inHours < 24 && diff.inHours >= 0) {
      final hrs = diff.inHours;
      return hrs == 1 ? 'Hace 1 hora' : 'Hace $hrs horas';
    }
    if (diff.inDays < 7 && diff.inDays >= 0) {
      final days = diff.inDays;
      return days == 1 ? 'Ayer' : 'Hace $days días';
    }
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  Widget _articleCard(NewsArticle article) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: article.portalColor.withAlpha(80)),
      ),
      child: InkWell(
        onTap: () => _openArticle(article.url),
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: article.portalColor.withAlpha(40),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                          color: article.portalColor.withAlpha(120), width: 1),
                    ),
                    child: Text(
                      article.portalDisplayName,
                      style: TextStyle(
                        color: article.portalColor,
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (article.publishedAt != null)
                    Text(
                      _formatDate(article.publishedAt),
                      style: const TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              if (article.imageUrl != null && article.imageUrl!.isNotEmpty) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Image.network(
                      article.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
              ],
              Text(
                article.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  height: 1.25,
                ),
              ),
              if (article.description.isNotEmpty) ...[
                const SizedBox(height: 5),
                Text(
                  article.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                    height: 1.3,
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () => _openArticle(article.url),
                    icon: const Icon(Icons.open_in_new, size: 16),
                    label: const Text('Leer en web'),
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      foregroundColor: AppTheme.primaryLight,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _articles.where((article) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery;
      return article.title.toLowerCase().contains(q) ||
          article.description.toLowerCase().contains(q);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Noticias'),
        actions: [
          IconButton(
            tooltip: 'Actualizar noticias',
            onPressed: _loading ? null : _loadNews,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                hintText: 'Buscar en noticias...',
              ),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: const Text('Todas'),
                    selected: _selectedPortal == null,
                    onSelected: (_) {
                      setState(() => _selectedPortal = null);
                      _loadNews();
                    },
                  ),
                ),
                for (final portal in NewsPortal.values)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(switch (portal) {
                        NewsPortal.tresDJuegos => '3DJuegos',
                        NewsPortal.vandal => 'Vandal',
                        NewsPortal.metacritic => 'Metacritic',
                      }),
                      selected: _selectedPortal == portal,
                      onSelected: (_) {
                        setState(() => _selectedPortal = portal);
                        _loadNews();
                      },
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadNews,
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.wifi_off,
                                    size: 48, color: AppTheme.warning),
                                const SizedBox(height: 12),
                                Text(
                                  _error!,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                      color: AppTheme.textSecondary),
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: _loadNews,
                                  child: const Text('Reintentar'),
                                ),
                              ],
                            ),
                          ),
                        )
                      : filtered.isEmpty
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(24),
                                child: Text(
                                  _searchQuery.isNotEmpty
                                      ? 'No se encontraron noticias que coincidan con "$_searchQuery".'
                                      : 'No hay noticias disponibles en este momento.',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                      color: AppTheme.textSecondary),
                                ),
                              ),
                            )
                          : ListView.builder(
                              physics: const AlwaysScrollableScrollPhysics(),
                              itemCount: filtered.length,
                              itemBuilder: (ctx, index) =>
                                  _articleCard(filtered[index]),
                            ),
            ),
          ),
        ],
      ),
    );
  }
}
