import 'package:html/parser.dart' as html;
import '../../core/constants/app_constants.dart';
import '../../domain/models/membership_benefits.dart';
import '../../domain/models/subscription_item.dart';

/// Reads plan-specific features from the official US pages, never from a
/// hardcoded entitlement list. Translations only label features actually found.
class MembershipBenefitsSource {
  static List<SubscriptionItem> parseNintendoMemberGames(
      String body, DateTime now) {
    final doc = html.parse(body);
    final items = <SubscriptionItem>[];
    for (final card in doc.querySelectorAll('[data-testid="card"]')) {
      final link = card.querySelector('a[aria-label][href]');
      final title = link?.attributes['aria-label'] ?? '';
      final href = link?.attributes['href'] ?? '';
      if (title.isEmpty ||
          !href.startsWith('/us/store/products/') ||
          !card.text.contains('Free download') ||
          !card.text.contains(r'$0.00') ||
          !card.text.contains('Games')) {
        continue;
      }
      items.add(SubscriptionItem(
          id: 'nso_member_$href',
          title: title,
          platform: GamePlatform.nintendo,
          tier: SubscriptionTier.nsoStandard,
          status: SubscriptionStatus.included,
          category: SubscriptionCategory.catalog,
          coverUrl: card.querySelector('img')?.attributes['src'] ?? '',
          consoles: const ['Nintendo Switch'],
          officialStoreUrl: 'https://www.nintendo.com$href',
          sourceUrl: nintendoUrl,
          checkedAt: now,
          statusNote:
              'Descarga sin coste adicional para miembros. Requiere Nintendo Switch Online para las funciones incluidas.'));
    }
    return items;
  }

  static const playstationUrl = 'https://www.playstation.com/en-us/ps-plus/';
  static const xboxUrl = 'https://www.xbox.com/en-US/xbox-game-pass';
  static const nintendoUrl =
      'https://www.nintendo.com/us/online/nintendo-switch-online/';
  static const expansionUrl = '${nintendoUrl}expansion-pack/';
  static const _translations = {
    'Monthly games': 'Juegos mensuales para reclamar',
    'Online multiplayer': 'Multijugador en línea',
    'Exclusive discounts': 'Descuentos exclusivos',
    'Exclusive content': 'Contenido exclusivo',
    'Cloud storage': 'Guardado en la nube',
    'Share Play': 'Share Play',
    'Game Catalog': 'Catálogo de juegos',
    'Ubisoft+ Classics': 'Ubisoft+ Classics',
    'Classics Catalog': 'Catálogo de clásicos',
    'Game trials': 'Pruebas de juegos',
    'Game Trials': 'Pruebas de juegos',
    'Cloud streaming': 'Juego en la nube',
    'PS5 cloud streaming': 'Juego de PS5 en la nube',
    'Sony Pictures Catalog': 'Catálogo de Sony Pictures',
    'Online console multiplayer': 'Multijugador en línea en consola',
    'Save Data Cloud': 'Guardado de datos en la nube (juegos compatibles)',
    'Missions and Rewards': 'Misiones y recompensas',
    'Featured special offers': 'Ofertas y productos exclusivos',
    'New games on day one': 'Nuevos juegos desde el día de lanzamiento',
    'New XBOX-published games within 1yr of launch':
        'Nuevos juegos publicados por Xbox dentro de un año desde su lanzamiento',
    'Benefits for games like League of Legends and Call of Duty: Warzone':
        'Beneficios en juegos como League of Legends y Call of Duty: Warzone',
    'Earn Rewards points': 'Obtén puntos Rewards',
  };
  static String _clean(String value) =>
      value.replaceAll(RegExp(r'\s+'), ' ').trim();
  static String _label(String value) {
    final text = _clean(value);
    final cloud =
        RegExp(r'^Cloud playtime \((\d+) hours/month\)$').firstMatch(text);
    if (cloud != null) {
      return 'Tiempo de juego en la nube (${cloud[1]} horas/mes)';
    }
    final games =
        RegExp(r'^(\d+\+?) games playable on console, PC, & more devices$')
            .firstMatch(text);
    if (games != null) {
      return '${games[1]} juegos entre los dispositivos compatibles del plan';
    }
    return _translations[text] ?? text;
  }

  static List<MembershipBenefits> parsePlaystation(String body, DateTime now) {
    final doc = html.parse(body);
    final plans = <MembershipBenefits>[];
    for (final panel in doc.querySelectorAll('.comparison-panel__tier-tab')) {
      final tier = switch (panel.querySelector('h3')?.text.trim()) {
        'Essential' => SubscriptionTier.psEssential,
        'Extra' => SubscriptionTier.psExtra,
        'Premium' => SubscriptionTier.psPremium,
        _ => null,
      };
      if (tier == null) continue;
      final features = panel
          .querySelectorAll('.feature-descriptors > li')
          .where((li) => !li.classes
              .any((c) => c.contains('disabled') || c.contains('unavailable')))
          .map((li) =>
              li.querySelector('.feature-descriptors__text')?.text ?? '')
          .map(_label)
          .where((s) => s.isNotEmpty)
          .toSet()
          .toList();
      if (features.isNotEmpty) {
        plans.add(MembershipBenefits(
            tier: tier,
            features: features,
            sourceUrl: playstationUrl,
            checkedAt: now));
      }
    }
    return plans;
  }

  static List<MembershipBenefits> parseXbox(String body, DateTime now) {
    final doc = html.parse(body);
    final plans = <MembershipBenefits>[];
    for (final entry in {
      'core': SubscriptionTier.xboxCore,
      'standard': SubscriptionTier.xboxStandard,
      'ultimate': SubscriptionTier.xboxUltimate
    }.entries) {
      final panel = doc.querySelector('li#${entry.key}');
      if (panel == null) continue;
      // Footnote numbers must not become part of a cloud-hour limit.
      for (final footnote in panel.querySelectorAll('sup')) {
        footnote.remove();
      }
      final features = panel
          .querySelectorAll('.details .pullBullet,.details .c-list > li')
          .map((e) => _label(e.text))
          .where((s) => s.isNotEmpty)
          .toSet()
          .toList();
      if (features.isNotEmpty) {
        plans.add(MembershipBenefits(
            tier: entry.value,
            features: features,
            sourceUrl: xboxUrl,
            checkedAt: now));
      }
    }
    return plans;
  }

  static List<MembershipBenefits> parseNintendo(
      String body, SubscriptionTier tier, DateTime now) {
    final doc = html.parse(body);
    final main = doc.querySelector('main') ?? doc.body!;
    final features = <String>{};
    for (final heading in main.querySelectorAll('h2')) {
      final text = _clean(heading.text);
      if (text.startsWith('What ') ||
          text.contains('Frequently') ||
          text.startsWith('About ')) {
        continue;
      }
      if (tier == SubscriptionTier.nsoStandard) {
        if (text.contains('friends online')) {
          features.add('Multijugador en línea en juegos compatibles');
        } else if (text.contains('C Button')) {
          features.add('GameChat en Nintendo Switch 2');
        } else if (text.contains('GameShare')) {
          features.add('GameShare en línea con GameChat (Switch 2)');
        } else if (text.contains('Nintendo Classics')) {
          features.add('Nintendo Classics: NES, Super NES y Game Boy');
        } else if (text.contains('Nintendo game music')) {
          features.add('Nintendo Music para dispositivos móviles');
        } else if (_translations.containsKey(text)) {
          features.add(_label(text));
        }
      } else {
        if (text.contains('even more classic games')) {
          features.add(
              'Catálogo ampliado de Nintendo Classics: consulta las consolas en Juegos');
        } else if (text.contains('Virtual Boy')) {
          features.add('Virtual Boy: requiere accesorio compatible');
        } else if (text.contains('Upgrade Pack')) {
          features.add('$text · Requiere el juego base y Nintendo Switch 2');
        } else if (text.contains('SEGA classics')) {
          features.add('Clásicos de SEGA Genesis');
        }
      }
    }
    if (tier == SubscriptionTier.nsoExpansion) {
      for (final link in main.querySelectorAll('a')) {
        final text = _clean(link.text);
        if (RegExp(r'Happy Home Paradise|Booster Course Pass|Octo Expansion')
            .hasMatch(text)) {
          features
              .add('$text · DLC: requiere el juego base y membresía activa');
        }
      }
      if (features.isNotEmpty) {
        features.add('Incluye los beneficios de Nintendo Switch Online');
      }
    }
    return features.isEmpty
        ? []
        : [
            MembershipBenefits(
                tier: tier,
                features: features.toList(),
                sourceUrl: tier == SubscriptionTier.nsoStandard
                    ? nintendoUrl
                    : expansionUrl,
                checkedAt: now)
          ];
  }
}
