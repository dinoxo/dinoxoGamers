import 'dart:async';
import 'package:flutter/services.dart';
import '../../core/constants/app_constants.dart';
import 'subscription_title.dart';

class PhotoRecognition {
  const PhotoRecognition(this.candidates, {this.platform});
  final List<String> candidates;
  final GamePlatform? platform;
}

class OcrService {
  OcrService._();
  static const channel = MethodChannel('com.dinoxo.gamers/ocr');

  /// Reads the image locally using Android ML Kit; never matches file names.
  static Future<List<String>> recognizeText(String imagePath) async {
    return (await recognizePhoto(imagePath)).candidates;
  }

  static Future<PhotoRecognition> recognizePhoto(String imagePath) async {
    final lines = await channel.invokeListMethod<String>('recognizeText',
        {'path': imagePath}).timeout(const Duration(seconds: 20));
    return fromLines(lines ?? []);
  }

  static PhotoRecognition fromLines(List<String> raw) {
    final text = raw.join(' ');
    final hints = <GamePlatform>{
      if (RegExp(r'\b(?:playstation|ps[45])\b', caseSensitive: false)
          .hasMatch(text))
        GamePlatform.playstation,
      if (RegExp(r'\bxbox\b', caseSensitive: false).hasMatch(text))
        GamePlatform.xbox,
      if (RegExp(r'\bnintendo\s+switch\b', caseSensitive: false).hasMatch(text))
        GamePlatform.nintendo,
    };
    final lines = raw
        .map((s) => s
            .replaceAll(RegExp(r'[™®©]'), '')
            .replaceAll(RegExp(r'\s+'), ' ')
            .trim())
        .where((s) =>
            (s.length >= 2 || RegExp(r'^\d$').hasMatch(s)) &&
            !_isPackagingText(s) &&
            !RegExp(r'^\d{5,}$').hasMatch(s))
        .toSet()
        .toList();
    final candidates = <String, String>{};
    void add(String value) {
      if (value.length >= 2 &&
          RegExp(r'[a-zà-ÿ]', caseSensitive: false).hasMatch(value)) {
        candidates.putIfAbsent(subscriptionTitleKey(value), () => value);
      }
    }

    for (var i = 0; i < lines.length; i++) {
      // ML Kit returns a joined block first on Android. Keep that intact.
      if (lines[i].length >= 20) add(lines[i]);
      for (var count = 4; count >= 2; count--) {
        if (i + count > lines.length) continue;
        final group = lines.sublist(i, i + count);
        if (group.any((s) => s.length >= 35)) continue;
        if (group.any((a) => group.any((b) =>
            a != b &&
            ' ${subscriptionTitleKey(a)} '
                .contains(' ${subscriptionTitleKey(b)} ')))) {
          continue;
        }
        add(group.join(' '));
      }
      add(lines[i]);
    }
    return PhotoRecognition(candidates.values.take(20).toList(),
        platform: hints.length == 1 ? hints.single : null);
  }

  static bool _isPackagingText(String text) => RegExp(
          r'^(?:playstation\s*[45]?|ps[45]|xbox(?:\s+(?:one|series\s*[xs|/ ]+))?|nintendo\s+switch\s*2?|esrb\b.*|pegi\b.*|rated\b.*|everyone\b.*|teen|mature\b.*|playstation studios|sony interactive entertainment|ubisoft|ea sports|bandai namco|e10\+|[emt]\s*\d*\+?)$',
          caseSensitive: false)
      .hasMatch(text.trim());

  static String errorMessage(Object error) {
    if (error is TimeoutException) {
      return 'La lectura tardó demasiado. Prueba una foto más clara o escribe el título para buscarlo.';
    }
    if (error is MissingPluginException) {
      return 'Esta instalación no incluye el lector de fotos. Introduce el título para buscarlo.';
    }
    if (error is PlatformException) {
      switch (error.code) {
        case 'camera_access_denied':
        case 'camera_access_denied_without_prompt':
        case 'camera_access_restricted':
          return 'El permiso de cámara está desactivado. Actívalo en Ajustes del teléfono o usa una imagen de la galería.';
        case 'photo_access_denied':
        case 'photo_access_restricted':
          return 'No se permitió seleccionar la imagen. Autoriza el acceso a la foto y vuelve a intentarlo.';
        case 'IMAGE_MISSING':
          return 'No se pudo abrir esta imagen. Selecciónala de nuevo desde la galería.';
        case 'IMAGE_INVALID':
          return 'El formato de la imagen no pudo leerse. Prueba con una captura JPG o PNG.';
        case 'OCR_FAILED':
          return 'No se pudo reconocer el texto. Puedes introducir o corregir el título y buscarlo.';
      }
    }
    return 'No se pudo procesar la foto. Introduce el título para buscarlo.';
  }
}
