import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../../shared/providers/firebase_providers.dart';
import '../../data/site_content_datasource.dart';
import 'site_content_form_notifier.dart';
import 'site_content_form_state.dart';

final siteContentDataSourceProvider =
    Provider<SiteContentDataSource>((ref) {
  return SiteContentDataSource(firestore: ref.watch(firestoreProvider));
});

final siteContentFormNotifierProvider = StateNotifierProvider<
    SiteContentFormNotifier, SiteContentFormState>(
  (ref) => SiteContentFormNotifier(
    datasource: ref.watch(siteContentDataSourceProvider),
  ),
);
