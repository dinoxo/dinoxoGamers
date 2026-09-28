import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dinoxo_gamers/domain/services/ocr_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('recognizes a title split over three lines on a cover', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            OcrService.channel,
            (_) async => [
                  'PS5',
                  'Ghost of',
                  'Tsushima',
                  "DIRECTOR’S CUT",
                  'MATURE 17+'
                ]);
    final titles = await OcrService.recognizeText('/gallery/cover.jpg');
    expect(titles, contains("Ghost of Tsushima DIRECTOR’S CUT"));
    expect(titles, isNot(contains('PS5')));
  });
  tearDown(() => TestDefaultBinaryMessengerBinding
      .instance.defaultBinaryMessenger
      .setMockMethodCallHandler(OcrService.channel, null));
  test(
      'passes image path to native OCR and uses recognized lines, never the file name',
      () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(OcrService.channel, (call) async {
      expect(call.method, 'recognizeText');
      expect(call.arguments, {'path': '/camera/pokemon.jpg'});
      return [' Halo ', 'Halo', '', 'A'];
    });
    expect(await OcrService.recognizeText('/camera/pokemon.jpg'), ['Halo']);
  });
  test('recognition failure propagates without inventing candidates', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(OcrService.channel,
            (_) async => throw PlatformException(code: 'OCR_FAILED'));
    expect(() => OcrService.recognizeText('/camera/pokemon.jpg'),
        throwsA(isA<PlatformException>()));
  });
  test('joins a split cover title and excludes console and rating text',
      () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(OcrService.channel,
            (_) async => ['Nintendo Switch', 'Pokémon', 'Scarlet', 'ESRB E']);
    final titles = await OcrService.recognizeText('/gallery/cover.jpg');
    expect(titles, contains('Pokémon Scarlet'));
    expect(titles, isNot(contains('Nintendo Switch')));
    expect(titles, isNot(contains('ESRB E')));
  });
}
