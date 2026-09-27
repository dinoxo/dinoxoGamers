import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dinoxo_gamers/domain/services/ocr_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
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
}
