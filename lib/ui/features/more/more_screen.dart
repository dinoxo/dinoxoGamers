import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/repositories/game_repository.dart';
import '../../core/widgets/gaming_header.dart';
import '../library/library_screen.dart';
import '../news/news_screen.dart';
import '../store/dinoxo_store_screen.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key, required this.repository});
  final GameRepository repository;

  void _open(BuildContext context, Widget screen) =>
      Navigator.push(context, MaterialPageRoute<void>(builder: (_) => screen));

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: GamingHeader.adaptive(context,
            title: 'Más para jugar',
            subtitle: 'Tu comunidad, tu colección y Dinoxo Store.'),
        body: ListView(padding: const EdgeInsets.all(16), children: [
          const Text('EXPLORA DINOXO',
              style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.6)),
          const SizedBox(height: 14),
          _ModuleTile(
              title: 'Dinoxo Store',
              subtitle: 'Gift cards USA, WhatsApp y nuestras redes',
              icon: Icons.storefront_outlined,
              color: AppTheme.secondary,
              onTap: () => _open(context, const DinoxoStoreScreen())),
          _ModuleTile(
              title: 'Noticias',
              subtitle: 'Actualidad de videojuegos y anuncios',
              icon: Icons.newspaper_outlined,
              color: AppTheme.primaryLight,
              onTap: () => _open(context, const NewsScreen())),
          _ModuleTile(
              title: 'Mi Biblioteca',
              subtitle: 'Tus juegos y comparador de ediciones',
              icon: Icons.inventory_2_outlined,
              color: AppTheme.success,
              onTap: () =>
                  _open(context, LibraryScreen(repository: repository))),
          _ModuleTile(
              title: 'Acerca de Dinoxo Gamers',
              subtitle: 'Información de la app y región comercial',
              icon: Icons.info_outline_rounded,
              color: AppTheme.textSecondary,
              onTap: () => showDialog<void>(
                  context: context,
                  builder: (context) => AlertDialog(
                        title: const Text('Dinoxo Gamers'),
                        content: const Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                  'Versión ${AppConstants.appVersion} · Edición gratuita'),
                              SizedBox(height: 12),
                              Text(
                                  'Ofertas, búsquedas, suscripciones y próximos lanzamientos de PlayStation, Nintendo y Xbox, exclusivamente en Estados Unidos y USD.'),
                              SizedBox(height: 12),
                              Text(
                                  'Dinoxo Store: gift cards y contacto directo. La app es gratuita y no requiere licencias.'),
                            ]),
                        actions: [
                          TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Cerrar'))
                        ],
                      ))),
          const SizedBox(height: 18),
          const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.public, size: 14, color: AppTheme.secondary),
            SizedBox(width: 6),
            Text('Estados Unidos · USD',
                style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
          ]),
        ]),
      );
}

class _ModuleTile extends StatelessWidget {
  const _ModuleTile(
      {required this.title,
      required this.subtitle,
      required this.icon,
      required this.color,
      required this.onTap});
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        child: Material(
            color: AppTheme.surface,
            clipBehavior: Clip.antiAlias,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: color.withAlpha(85))),
            child: ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                      color: color.withAlpha(25),
                      borderRadius: BorderRadius.circular(12)),
                  child: Icon(icon, color: color)),
              title: Text(title,
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w800)),
              subtitle: Text(subtitle,
                  style: const TextStyle(
                      fontSize: 12, color: AppTheme.textSecondary)),
              trailing: const Icon(Icons.chevron_right_rounded,
                  color: AppTheme.textMuted),
              onTap: onTap,
            )),
      );
}
