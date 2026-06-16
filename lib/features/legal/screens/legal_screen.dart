import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../legal_content.dart';

/// Schermata generica che mostra un testo legale (Privacy Policy o Termini).
/// Usata sia dal router (/privacy, /terms) sia via Navigator dall'auth screen
/// (che è fuori dal GoRouter).
class LegalScreen extends StatelessWidget {
  final String title;
  final String body;

  const LegalScreen({super.key, required this.title, required this.body});

  /// Costruttori comodi per i due documenti.
  factory LegalScreen.privacy() =>
      const LegalScreen(title: 'Privacy Policy', body: kPrivacyPolicy);
  factory LegalScreen.terms() =>
      const LegalScreen(title: 'Termini di Servizio', body: kTermsOfService);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(title.toUpperCase()),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: SelectableText(
            body.trim(),
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              height: 1.55,
            ),
          ),
        ),
      ),
    );
  }
}
