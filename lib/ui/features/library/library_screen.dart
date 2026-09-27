import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/repositories/game_repository.dart';
import '../../../domain/models/game.dart';
import '../../core/widgets/empty_state_view.dart';
import '../../core/widgets/platform_badge.dart';
import '../game_details/game_details_screen.dart';

class LibraryScreen extends StatefulWidget {
  final GameRepository repository;

  const LibraryScreen({
    super.key,
    required this.repository,
  });

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Game> _ownedGames = [];
  List<Game> _allGames = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final owned = await widget.repository.getOwnedGames();
    final all = await widget.repository.getGames();
    if (mounted) {
      setState(() {
        _ownedGames = owned;
        _allGames = all;
        _isLoading = false;
      });
    }
  }

  void _showEditionComparator(Game game) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Comparador de Ediciones: ${game.title}',
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppTheme.textMuted),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...game.editions.map((edition) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              edition.name,
                              style: const TextStyle(
                                color: AppTheme.primaryLight,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              '\$${edition.currentPrice.toStringAsFixed(2)} USD',
                              style: const TextStyle(
                                color: AppTheme.success,
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Tipo: ${AppConstants.productTypeDisplayName(edition.productType)}',
                          style: const TextStyle(
                              color: AppTheme.textMuted, fontSize: 11),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Contenido incluido:',
                          style: TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 11,
                              fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 4),
                        if (edition.includedContent.isEmpty)
                          const Text(
                              'Contenido no confirmado: consulta la edición en la tienda.',
                              style: TextStyle(
                                  color: AppTheme.textPrimary, fontSize: 11))
                        else
                          ...edition.includedContent.map(
                            (c) => Padding(
                              padding: const EdgeInsets.only(bottom: 2),
                              child: Text('• $c',
                                  style: const TextStyle(
                                      color: AppTheme.textPrimary,
                                      fontSize: 11)),
                            ),
                          ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Biblioteca y Herramientas'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primaryLight,
          labelColor: AppTheme.textPrimary,
          unselectedLabelColor: AppTheme.textMuted,
          tabs: const [
            Tab(text: 'Mis Juegos Comprados'),
            Tab(text: 'Comparador de Ediciones'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                // Tab 1: Owned Games
                _ownedGames.isEmpty
                    ? const EmptyStateView(
                        icon: Icons.inventory_2_outlined,
                        title: 'Tu biblioteca está vacía',
                        message:
                            'Puedes marcar los juegos que ya compraste tocando el icono de inventario en su ficha para evitar compras duplicadas.',
                      )
                    : ListView.builder(
                        itemCount: _ownedGames.length,
                        padding: const EdgeInsets.all(12),
                        itemBuilder: (context, index) {
                          final game = _ownedGames[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            child: ListTile(
                              leading: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  game.coverUrl,
                                  width: 45,
                                  height: 60,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      const Icon(Icons.sports_esports),
                                ),
                              ),
                              title: Text(
                                game.title,
                                style: const TextStyle(
                                    color: AppTheme.textPrimary,
                                    fontWeight: FontWeight.w700),
                              ),
                              subtitle: Row(
                                children: [
                                  PlatformBadge(
                                      platform: game.platform, compact: true),
                                  const SizedBox(width: 6),
                                  const Text('En tu colección',
                                      style: TextStyle(
                                          color: AppTheme.success,
                                          fontSize: 11)),
                                ],
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete_outline,
                                    color: AppTheme.textMuted),
                                tooltip: 'Quitar de biblioteca',
                                onPressed: () async {
                                  await widget.repository.toggleGameOwned(game);
                                  _loadData();
                                },
                              ),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => GameDetailsScreen(
                                      game: game,
                                      repository: widget.repository,
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),

                // Tab 2: Edition Comparator
                ListView.builder(
                  itemCount: _allGames.length,
                  padding: const EdgeInsets.all(12),
                  itemBuilder: (context, index) {
                    final game = _allGames[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            game.coverUrl,
                            width: 45,
                            height: 60,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                const Icon(Icons.sports_esports),
                          ),
                        ),
                        title: Text(
                          game.title,
                          style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontWeight: FontWeight.w700),
                        ),
                        subtitle: Text(
                          '${game.editions.length} ${game.editions.length == 1 ? 'edición' : 'ediciones disponibles'}',
                          style: const TextStyle(
                              color: AppTheme.textSecondary, fontSize: 12),
                        ),
                        trailing: OutlinedButton(
                          onPressed: () => _showEditionComparator(game),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(80, 34),
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                          ),
                          child: const Text('Comparar',
                              style: TextStyle(fontSize: 12)),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
    );
  }
}
