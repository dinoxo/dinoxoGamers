import 'package:flutter_test/flutter_test.dart';
import 'package:dinoxo_gamers/core/constants/app_constants.dart';
import 'package:dinoxo_gamers/domain/services/whatsapp_service.dart';

void main() {
  group('WhatsAppService Tests', () {
    test('cleanPhoneNumber strips non-numeric characters', () {
      expect(WhatsAppService.cleanPhoneNumber('+584268158785'), '584268158785');
      expect(WhatsAppService.cleanPhoneNumber('0426 815 8785'), '04268158785');
      expect(WhatsAppService.cleanPhoneNumber('(0426)-815-8785'), '04268158785');
    });

    test('Store WhatsApp constants match official Dinoxo guidelines', () {
      expect(AppConstants.storeWhatsAppPhone, '+584268158785');
      expect(AppConstants.storeWhatsAppVisiblePhone, '0426 815 8785');
      expect(AppConstants.storeWebsite, 'https://dinoxostore.com/');
      expect(AppConstants.psDealsUrl, 'https://psdeals.net/us-store');
      expect(AppConstants.ntDealsUrl, 'https://ntdeals.net/us-store');
      expect(AppConstants.xbDealsUrl, 'https://xbdeals.net/us-store');
    });

    test('officialStoreUrlForGame correctly generates USA store search URLs', () {
      final nintendoUrl = AppConstants.officialStoreUrlForGame(
        GamePlatform.nintendo,
        'Super Mario Galaxy',
      );
      expect(nintendoUrl, contains('nintendo.com/us/search/#q=Super%20Mario%20Galaxy'));

      final psUrl = AppConstants.officialStoreUrlForGame(
        GamePlatform.playstation,
        'Marvel\'s Spider-Man 2',
      );
      expect(psUrl, contains('store.playstation.com/en-us/search/'));

      final xboxUrl = AppConstants.officialStoreUrlForGame(
        GamePlatform.xbox,
        'Halo Infinite',
      );
      expect(xboxUrl, contains('xbox.com/en-us/search?q=Halo%20Infinite'));
    });

    test('dealsTrackerUrlForGame correctly generates USA tracker search URLs', () {
      final nintendoTracker = AppConstants.dealsTrackerUrlForGame(
        GamePlatform.nintendo,
        'Super Mario Galaxy',
      );
      expect(nintendoTracker, 'https://ntdeals.net/us-store/search?search_query=Super%20Mario%20Galaxy');

      final psTracker = AppConstants.dealsTrackerUrlForGame(
        GamePlatform.playstation,
        'Spider-Man',
      );
      expect(psTracker, 'https://psdeals.net/us-store/search?search_query=Spider-Man');

      final xboxTracker = AppConstants.dealsTrackerUrlForGame(
        GamePlatform.xbox,
        'Forza',
      );
      expect(xboxTracker, 'https://xbdeals.net/us-store/search?search_query=Forza');
    });
  });
}
