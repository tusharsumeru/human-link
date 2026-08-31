import 'package:flutter/material.dart';
import '../services/translation_service.dart';

class TranslatedText extends StatefulWidget {
  const TranslatedText({
    super.key,
    required this.text,
    this.style,
    this.textAlign,
    this.maxLines,
  });

  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;

  @override
  State<TranslatedText> createState() => _TranslatedTextState();
}

class _TranslatedTextState extends State<TranslatedText> {
  String? _translated;

  @override
  void initState() {
    super.initState();
    _translate();
  }

  @override
  void didUpdateWidget(covariant TranslatedText oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.text != widget.text) {
      _translate();
    }
  }

  Future<void> _translate() async {
    final languageCode =
        Localizations.localeOf(context).languageCode;

    if (languageCode == 'en' || widget.text.trim().isEmpty) {
      if (mounted) {
        setState(() {
          _translated = widget.text;
        });
      }
      return;
    }

    final result = await TranslationService.instance.translate(
      text: widget.text,
      targetLanguage: languageCode,
    );

    if (!mounted) return;

    setState(() {
      _translated = result;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      _translated ?? widget.text,
      style: widget.style,
      textAlign: widget.textAlign,
      maxLines: widget.maxLines,
    );
  }
}