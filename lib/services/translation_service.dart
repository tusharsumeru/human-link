import 'package:google_mlkit_translation/google_mlkit_translation.dart';

class TranslationService {
  TranslationService._();

  static final TranslationService instance = TranslationService._();

  final Map<String, String> _cache = {};

  Future<String> translate({
    required String text,
    required String targetLanguage,
  }) async {
    if (text.trim().isEmpty) return text;

    // English doesn't need translation.
    if (targetLanguage == 'en') return text;

    final cacheKey = '$targetLanguage|$text';

    if (_cache.containsKey(cacheKey)) {
      return _cache[cacheKey]!;
    }

    final target = _getLanguage(targetLanguage);

    final translator = OnDeviceTranslator(
      sourceLanguage: TranslateLanguage.english,
      targetLanguage: target,
    );

    try {
      final result = await translator.translateText(text);

      _cache[cacheKey] = result;

      return result;
    } finally {
      await translator.close();
    }
  }

  TranslateLanguage _getLanguage(String language) {
    switch (language) {
      case 'kn':
        return TranslateLanguage.kannada;

      case 'hi':
        return TranslateLanguage.hindi;

      default:
        return TranslateLanguage.english;
    }
  }

  void clearCache() {
    _cache.clear();
  }
}