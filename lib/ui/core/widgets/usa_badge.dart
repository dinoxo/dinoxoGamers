import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class UsaBadge extends StatelessWidget {
  final bool compact;

  const UsaBadge({
    super.key,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 8,
        vertical: compact ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppTheme.border, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.public, size: 12, color: AppTheme.secondary),
          const SizedBox(width: 4),
          Text(
            'USA · USD',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: compact ? 10 : 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
