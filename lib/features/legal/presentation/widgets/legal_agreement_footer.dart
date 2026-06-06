import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/route_names.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../pages/legal_document_page.dart';

/// "By continuing you agree to our **Terms of Service** and **Privacy
/// Policy**." — embedded on sign-up, sign-in, and the subscription checkout
/// disclaimer.
///
/// Uses [RichText] with [TapGestureRecognizer]s so each link routes through
/// the top-level `/legal/:slug` route. The recognizers are owned by the
/// widget and disposed in [dispose].
class LegalAgreementFooter extends StatefulWidget {
  const LegalAgreementFooter({
    super.key,
    this.textAlign = TextAlign.center,
  });

  final TextAlign textAlign;

  @override
  State<LegalAgreementFooter> createState() => _LegalAgreementFooterState();
}

class _LegalAgreementFooterState extends State<LegalAgreementFooter> {
  late final TapGestureRecognizer _termsRecognizer;
  late final TapGestureRecognizer _privacyRecognizer;

  @override
  void initState() {
    super.initState();
    _termsRecognizer = TapGestureRecognizer()
      ..onTap = () => _open(LegalDocument.termsOfService);
    _privacyRecognizer = TapGestureRecognizer()
      ..onTap = () => _open(LegalDocument.privacyPolicy);
  }

  @override
  void dispose() {
    _termsRecognizer.dispose();
    _privacyRecognizer.dispose();
    super.dispose();
  }

  void _open(LegalDocument doc) {
    context.pushNamed(
      RouteNames.legal,
      pathParameters: {'slug': doc.slug},
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final base = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final linkStyle = base?.copyWith(
      color: theme.colorScheme.primary,
      decoration: TextDecoration.underline,
      fontWeight: FontWeight.w600,
    );

    return RichText(
      textAlign: widget.textAlign,
      text: TextSpan(
        style: base,
        children: [
          TextSpan(text: t.legalAgreementPrefix),
          TextSpan(
            text: t.legalTermsOfServiceTitle,
            style: linkStyle,
            recognizer: _termsRecognizer,
          ),
          TextSpan(text: t.legalAgreementAnd),
          TextSpan(
            text: t.legalPrivacyPolicyTitle,
            style: linkStyle,
            recognizer: _privacyRecognizer,
          ),
          TextSpan(text: t.legalAgreementPeriod),
        ],
      ),
    );
  }
}
