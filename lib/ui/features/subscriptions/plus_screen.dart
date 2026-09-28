import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/models/subscription_item.dart';
import '../../../domain/services/subscription_service.dart';
import '../../../domain/services/whatsapp_service.dart';
import '../../core/widgets/empty_state_view.dart';
import '../../core/widgets/platform_badge.dart';

class PlusScreen extends StatefulWidget {
  const PlusScreen({super.key});

  @override
  State<PlusScreen> createState() => _PlusScreenState();
}

class _PlusScreenState extends State<PlusScreen> {
  GamePlatform? _selectedPlatform;
  SubscriptionCategory _selectedCategory = SubscriptionCategory.all;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Color _getPlatformColor(GamePlatform? platform) {
    if (platform == null) return AppTheme.primary;
    return AppTheme.platformColor(platform);
  }

  @override
  Widget build(BuildContext context) {
    final items = SubscriptionService.instance.getItems(
      platform: _selectedPlatform,
      category: _selectedCategory,
      query: _searchQuery,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.card_membership_rounded, color: AppTheme.primaryLight),
            SizedBox(width: 8),
            Text('Plus & Suscripciones'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Info banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: AppTheme.surfaceSubtle,
            child: Row(
              children: [
                const Icon(Icons.lightbulb_outline,
                    color: AppTheme.warning, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Juegos incluidos en PlayStation Plus, Xbox Game Pass y Nintendo Switch Online. ¡No compres juegos que ya tenés incluidos!',
                    style: TextStyle(
                      color: AppTheme.textSecondary.withAlpha(220),
                      fontSize: 11,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: InputDecoration(
                hintText: 'Buscar en catálogos de suscripción...',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                isDense: true,
              ),
            ),
          ),

          // Platform Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            child: Row(
              children: [
                _buildPlatformFilterChip(
                  label: 'Todos',
                  platform: null,
                  icon: Icons.all_inclusive_rounded,
                ),
                const SizedBox(width: 8),
                _buildPlatformFilterChip(
                  label: 'PlayStation Plus',
                  platform: GamePlatform.playstation,
                  icon: Icons.sports_esports,
                ),
                const SizedBox(width: 8),
                _buildPlatformFilterChip(
                  label: 'Xbox Game Pass',
                  platform: GamePlatform.xbox,
                  icon: Icons.sports_esports,
                ),
                const SizedBox(width: 8),
                _buildPlatformFilterChip(
                  label: 'Nintendo Switch Online',
                  platform: GamePlatform.nintendo,
                  icon: Icons.sports_esports,
                ),
              ],
            ),
          ),

          // Category Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            child: Row(
              children: SubscriptionCategory.values.map((cat) {
                final isSelected = _selectedCategory == cat;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: FilterChip(
                    label: Text(
                      cat.label,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected
                            ? Colors.white
                            : AppTheme.textSecondary,
                      ),
                    ),
                    selected: isSelected,
                    selectedColor: _getPlatformColor(_selectedPlatform),
                    backgroundColor: AppTheme.surfaceElevated,
                    onSelected: (selected) {
                      setState(() {
                        _selectedCategory = cat;
                      });
                    },
                    padding: const EdgeInsets.symmetric(
                        horizontal: 4, vertical: 2),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                );
              }).toList(),
            ),
          ),
          const Divider(height: 1, color: AppTheme.divider),

          // List of Subscription Games
          Expanded(
            child: items.isEmpty
                ? const EmptyStateView(
                    icon: Icons.search_off_rounded,
                    title: 'No se encontraron juegos',
                    message:
                        'Prueba ajustando los filtros de plataforma o términos de búsqueda.',
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return _buildSubscriptionCard(context, item);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlatformFilterChip({
    required String label,
    required GamePlatform? platform,
    required IconData icon,
  }) {
    final isSelected = _selectedPlatform == platform;
    final color = _getPlatformColor(platform);

    return ChoiceChip(
      avatar: Icon(icon,
          size: 16, color: isSelected ? Colors.white : color),
      label: Text(label),
      selected: isSelected,
      selectedColor: color,
      onSelected: (selected) {
        setState(() {
          _selectedPlatform = platform;
        });
      },
    );
  }

  Widget _buildSubscriptionCard(BuildContext context, SubscriptionItem item) {
    Color statusColor;
    IconData statusIcon;

    switch (item.status) {
      case SubscriptionStatus.included:
        statusColor = AppTheme.success;
        statusIcon = Icons.check_circle_rounded;
        break;
      case SubscriptionStatus.leavingSoon:
        statusColor = AppTheme.warning;
        statusIcon = Icons.hourglass_bottom_rounded;
        break;
      case SubscriptionStatus.comingSoon:
        statusColor = const Color(0xFF00C3FF);
        statusIcon = Icons.upcoming_rounded;
        break;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover Image
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 80,
                height: 105,
                color: AppTheme.surfaceElevated,
                child: Image.network(
                  item.coverUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Center(
                    child: Icon(Icons.sports_esports,
                        color: AppTheme.textMuted, size: 30),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      PlatformBadge(platform: item.platform, compact: true),
                      const SizedBox(width: 6),
                      // Tier pill
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.platformColor(item.platform)
                              .withAlpha(40),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: AppTheme.platformColor(item.platform)
                                .withAlpha(120),
                          ),
                        ),
                        child: Text(
                          item.tier.displayName,
                          style: TextStyle(
                            color: AppTheme.platformColor(item.platform),
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Title
                  Text(
                    item.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Consoles
                  Text(
                    item.consoles.join(' · '),
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Status note badge
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withAlpha(25),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: statusColor.withAlpha(100)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statusIcon, color: statusColor, size: 12),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            item.statusNote ?? item.status.label,
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Official Store Link button if present
                  if (item.officialStoreUrl != null) ...[
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        icon: const Icon(Icons.storefront_outlined, size: 13),
                        label: const Text('Tienda USA',
                            style: TextStyle(fontSize: 11)),
                        onPressed: () {
                          WhatsAppService.launchExternalUrl(
                              item.officialStoreUrl!);
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
