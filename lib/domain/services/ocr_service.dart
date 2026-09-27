import 'package:flutter/services.dart';

class OcrService {
  OcrService._();
  static const channel = MethodChannel('com.dinoxo.gamers/ocr');

  /// Reads the image locally using Android ML Kit; never matches file names.
  static Future<List<String>> recognizeText(String imagePath) async {
    final lines = await channel
        .invokeListMethod<String>('recognizeText', {'path': imagePath});
    return (lines ?? [])
        .map((s) => s.trim())
        .where((s) => s.length >= 2)
        .toSet()
        .toList();
  }
}
