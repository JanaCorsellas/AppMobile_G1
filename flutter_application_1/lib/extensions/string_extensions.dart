import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_application_1/providers/language_provider.dart';

extension TranslationExtension on String {
  String tr(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
    return languageProvider.translate(this);
  }
  
  String trParams(BuildContext context, Map<String, String> params) {
    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
    return languageProvider.translateWithParams(this, params);
  }
}