import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_markdown/flutter_markdown.dart';

import '../../../../core/utils/extensions.dart';
import '../../../../l10n/generated/app_localizations.dart';

/// Identifies which bundled legal document to render.
///
/// Adding a new document is a 3-step process:
///   1. Drop the markdown file under `assets/legal/`.
///   2. Add a new enum case here with [assetPath] + [titleFor].
///   3. Wire a route + nav entry that pushes
///      `LegalDocumentPage(document: ...)`.
enum LegalDocument {
  privacyPolicy,
  termsOfService;

  String get assetPath {
    switch (this) {
      case LegalDocument.privacyPolicy:
        return 'assets/legal/privacy_policy.md';
      case LegalDocument.termsOfService:
        return 'assets/legal/terms_of_service.md';
    }
  }

  /// Localized AppBar title.
  String titleFor(AppLocalizations t) {
    switch (this) {
      case LegalDocument.privacyPolicy:
        return t.legalPrivacyPolicyTitle;
      case LegalDocument.termsOfService:
        return t.legalTermsOfServiceTitle;
    }
  }

  /// Slug used in deep-link paths — `/legal/{slug}`.
  String get slug {
    switch (this) {
      case LegalDocument.privacyPolicy:
        return 'privacy';
      case LegalDocument.termsOfService:
        return 'terms';
    }
  }

  static LegalDocument? fromSlug(String slug) {
    for (final d in LegalDocument.values) {
      if (d.slug == slug) return d;
    }
    return null;
  }
}

/// Renders one of the bundled legal documents (privacy policy, ToS) from
/// `assets/legal/*.md`.
///
/// Loaded lazily via [rootBundle.loadString] and cached for the lifetime of
/// the page. The file is checked into the repo so the screen works offline.
class LegalDocumentPage extends StatefulWidget {
  const LegalDocumentPage({super.key, required this.document});

  final LegalDocument document;

  @override
  State<LegalDocumentPage> createState() => _LegalDocumentPageState();
}

class _LegalDocumentPageState extends State<LegalDocumentPage> {
  late final Future<String> _content;

  @override
  void initState() {
    super.initState();
    _content = rootBundle.loadString(widget.document.assetPath);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(widget.document.titleFor(t))),
      body: FutureBuilder<String>(
        future: _content,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError || !snap.hasData) {
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                t.legalLoadFailed,
                style: TextStyle(color: context.colors.error),
              ),
            );
          }
          return Markdown(
            data: snap.data!,
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            selectable: true,
            styleSheet: _styleSheetFor(context),
          );
        },
      ),
    );
  }

  MarkdownStyleSheet _styleSheetFor(BuildContext context) {
    final base = MarkdownStyleSheet.fromTheme(Theme.of(context));
    return base.copyWith(
      h1: context.textTheme.headlineMedium?.copyWith(
        fontWeight: FontWeight.w800,
      ),
      h2: context.textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w700,
      ),
      h3: context.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w700,
      ),
      p: context.textTheme.bodyLarge?.copyWith(height: 1.5),
      listBullet: context.textTheme.bodyLarge?.copyWith(height: 1.5),
      blockSpacing: 12,
    );
  }
}
