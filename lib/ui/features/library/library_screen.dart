import 'package:flutter/material.dart';
import '../../core/widgets/gaming_header.dart';
import '../../core/widgets/game_card_frame.dart';
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

  Widget _gameCard(Game game, {required bool owned}) => GameCardFrame(
        platform: game.platform,
        coverUrl: game.coverUrl,
        margin: const EdgeInsets.only(bottom: 10),
        onTap: owned
            ? () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => GameDetailsScreen(
                        game: game, repository: widget.repository)))
            : () => _showEditionComparator(game),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          PlatformBadge(platform: game.platform, compact: true),
          const SizedBox(height: 8),
          Text(game.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style:
                  const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(game.consoles.join(' / '),
              style:
                  const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
          const SizedBox(height: 8),
          if (owned)
            const Text('En tu colección',
                style: TextStyle(color: AppTheme.success, fontSize: 11))
          else
            Text(
                '${game.editions.length} ${game.editions.length == 1 ? 'edición' : 'ediciones disponibles'}',
                style: const TextStyle(
                    color: AppTheme.textSecondary, fontSize: 11)),
          Align(
              alignment: Alignment.centerRight,
              child: owned
                  ? IconButton(
                      icon: const Icon(Icons.delete_outline,
                          color: AppTheme.textMuted),
                      tooltip: 'Quitar de biblioteca',
                      onPressed: () async {
                        await widget.repository.toggleGameOwned(game);
                        _loadData();
                      })
                  : TextButton.icon(
                      onPressed: () => _showEditionComparator(game),
                      icon: const Icon(Icons.compare_arrows_rounded, size: 18),
                      label: const Text('Comparar'))),
        ]),
      );

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: GamingHeader.adaptive(context,
            title: 'Biblioteca y Herramientas',
            subtitle: 'Tu colección y las ediciones de cada juego.',
            bottom: TabBar(
                controller: _tabController,
                indicatorColor: AppTheme.secondary,
                labelColor: AppTheme.textPrimary,
                unselectedLabelColor: AppTheme.textMuted,
                labelStyle:
                    const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                tabs: const [
                  Tab(text: 'Mis Juegos Comprados'),
                  Tab(text: 'Comparador de Ediciones')
                ])),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(controller: _tabController, children: [
                _ownedGames.isEmpty
                    ? const EmptyStateView(
                        icon: Icons.inventory_2_outlined,
                        title: 'Tu biblioteca está vacía',
                        message:
                            'Puedes marcar los juegos que ya compraste tocando el icono de inventario en su ficha para evitar compras duplicadas.')
                    : ListView.builder(
                        itemCount: _ownedGames.length,
                        padding: const EdgeInsets.all(14),
                        itemBuilder: (context, index) =>
                            _gameCard(_ownedGames[index], owned: true)),
                ListView.builder(
                    itemCount: _allGames.length,
                    padding: const EdgeInsets.all(14),
                    itemBuilder: (context, index) =>
                        _gameCard(_allGames[index], owned: false)),
              ]),
      );
}
