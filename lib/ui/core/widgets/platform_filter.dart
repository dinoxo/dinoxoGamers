import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';

class PlatformFilter extends StatelessWidget {
  const PlatformFilter(
      {super.key,
      required this.selected,
      required this.onChanged,
      this.memberships = false});
  final GamePlatform? selected;
  final ValueChanged<GamePlatform?> onChanged;
  final bool memberships;
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        child: Row(children: [
          for (final platform in <GamePlatform?>[null, ...GamePlatform.values])
            Padding(
                padding: const EdgeInsets.only(right: 6),
                child: ChoiceChip(
                  avatar: Icon(
                      platform == null
                          ? Icons.grid_view_rounded
                          : switch (platform) {
                              GamePlatform.playstation => Icons.sports_esports,
                              GamePlatform.nintendo => Icons.gamepad_outlined,
                              GamePlatform.xbox =>
                                Icons.videogame_asset_outlined,
                            },
                      size: 15,
                      color: selected == platform
                          ? Colors.white
                          : AppTheme.textSecondary),
                  showCheckmark: false,
                  label: Text(platform == null
                      ? 'Todas'
                      : memberships
                          ? switch (platform) {
                              GamePlatform.playstation => 'PlayStation Plus',
                              GamePlatform.nintendo => 'Nintendo Switch Online',
                              GamePlatform.xbox => 'Xbox Game Pass',
                            }
                          : AppConstants.platformDisplayName(platform)),
                  selected: platform == selected,
                  selectedColor: platform == null
                      ? AppTheme.primary
                      : AppTheme.platformColor(platform),
                  side: BorderSide(
                      color: platform == selected
                          ? platform == null
                              ? AppTheme.primaryLight
                              : AppTheme.platformColor(platform)
                          : AppTheme.border),
                  labelStyle: TextStyle(
                      fontFamily:
                          Theme.of(context).textTheme.bodyMedium?.fontFamily,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary),
                  onSelected: (_) => onChanged(platform),
                )),
        ]),
      );
}
