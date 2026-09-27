import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_constants.dart';

class WhatsAppService {
  WhatsAppService._();

  static String cleanPhoneNumber(String phone) {
    return phone.replaceAll(RegExp(r'[^0-9]'), '');
  }

  /// Launch WhatsApp with user review. Never sends automatically.
  static Future<bool> launchWhatsApp({
    String phone = AppConstants.storeWhatsAppPhone,
    required String message,
  }) async {
    final cleanPhone = cleanPhoneNumber(phone);
    final encodedMsg = Uri.encodeComponent(message);
    final url = Uri.parse('https://wa.me/$cleanPhone?text=$encodedMsg');

    if (await canLaunchUrl(url)) {
      return await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      // Fallback protocol
      final fallbackUrl = Uri.parse('whatsapp://send?phone=$cleanPhone&text=$encodedMsg');
      if (await canLaunchUrl(fallbackUrl)) {
        return await launchUrl(fallbackUrl, mode: LaunchMode.externalApplication);
      }
      return false;
    }
  }

  /// Open WhatsApp direct chat without pre-filled text
  static Future<bool> openDirectChat([String phone = AppConstants.storeWhatsAppPhone]) async {
    final cleanPhone = cleanPhoneNumber(phone);
    final url = Uri.parse('https://wa.me/$cleanPhone');
    if (await canLaunchUrl(url)) {
      return await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      final fallbackUrl = Uri.parse('whatsapp://send?phone=$cleanPhone');
      if (await canLaunchUrl(fallbackUrl)) {
        return await launchUrl(fallbackUrl, mode: LaunchMode.externalApplication);
      }
      return false;
    }
  }

  /// Message template for general consultation from Dinoxo Store social bar
  static Future<bool> sendGeneralStoreInquiry() async {
    const message =
        'Hola Dinoxo Store, vengo de la app Dinoxo Gamers. Quisiera consultar acerca de un juego o giftcard.';
    return await launchWhatsApp(message: message);
  }

  /// Message template for general giftcard balance inquiry
  static Future<bool> sendGiftCardInquiry({
    required GamePlatform platform,
    required int amountUsd,
  }) async {
    final platformName = AppConstants.platformDisplayName(platform);
    final message =
        'Hola Dinoxo Store! Vengo de Dinoxo Gamers. Deseo comprar una gift card $platformName USA de \$$amountUsd USD.';
    return await launchWhatsApp(message: message);
  }

  /// Message template for game-specific balance consultation
  static Future<bool> sendGameBalanceInquiry({
    required String gameTitle,
    required GamePlatform platform,
    required double referencePrice,
  }) async {
    final platformName = AppConstants.platformDisplayName(platform);
    final priceStr = referencePrice.toStringAsFixed(2);
    final message =
        'Hola, vengo de Dinoxo Gamers. Me interesa comprar saldo para el juego $gameTitle ($platformName) con precio de referencia de \$$priceStr USD. ¿Qué giftcard me recomiendan?';
    return await launchWhatsApp(message: message);
  }

  /// Generic external URL launcher
  static Future<bool> launchExternalUrl(String urlString) async {
    if (urlString.isEmpty) return false;
    final uri = Uri.parse(urlString);
    if (await canLaunchUrl(uri)) {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
    return false;
  }
}
