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
        .where((s) => s.length >= 2 && !_isPackagingText(s))
        .toSet()
        .toList()
        .letCandidates();
  }

  static bool _isPackagingText(String text) => RegExp(
          r'^(?:playstation\s*[45]?|ps[45]|xbox(?:\s+(?:one|series\s*[xs|/ ]+))?|nintendo\s+switch\s*2?|esrb\b.*|pegi\b.*|rated\b.*|everyone\b.*|teen|mature\b.*)$',
          caseSensitive: false)
      .hasMatch(text.trim());

  static String errorMessage(Object error) {
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

extension on List<String> {
  List<String> letCandidates() {
    final combined = <String>[];
    for (var i = 0; i + 1 < length; i++) {
      if (this[i].length < 35 && this[i + 1].length < 35) {
        combined.add('${this[i]} ${this[i + 1]}');
      }
    }
    return {...combined, ...this}.take(20).toList();
  }
}
