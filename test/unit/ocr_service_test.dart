import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dinoxo_gamers/domain/services/ocr_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('timeout asks native OCR to release the timed out request',
      (tester) async {
    final pending = Completer<List<String>>();
    final calls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(OcrService.channel, (call) async {
      calls.add(call);
      if (call.method == 'recognizeText') return pending.future;
      return null;
    });
    final read = OcrService.recognizePhoto('/gallery/large.jpg');
    final failure = expectLater(read, throwsA(isA<TimeoutException>()));
    await tester.pump(const Duration(seconds: 21));
    await failure;
    expect(calls.map((call) => call.method),
        ['recognizeText', 'cancelRecognition']);
    pending.complete(['Too late']);
    await tester.pump();
  });
  test('oversized recognized lines cannot create giant title candidates', () {
    final result = OcrService.fromLines([
      'Halo',
      List.filled(5000, 'Lorem').join(' '),
    ]);
    expect(result.candidates.every((title) => title.length <= 200), isTrue);
    expect(result.candidates, contains('Halo'));
  });
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
