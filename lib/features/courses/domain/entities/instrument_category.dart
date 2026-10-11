import '../../../../l10n/l10n.dart';
/// Three primary instrument categories (Tonebase-style).
enum InstrumentCategory {
  guitar('guitar', 'Guitar'),
  piano('piano', 'Piano'),
  violin('violin', 'Violin');

  const InstrumentCategory(this.id, this.englishLabel);
  final String id;
  final String englishLabel;

  /// Localized display label (app language).
  String get label {
    final t = L10n.current;
    return switch (this) {
      InstrumentCategory.guitar => t.instrumentGuitar,
      InstrumentCategory.piano => t.instrumentPiano,
      InstrumentCategory.violin => t.instrumentViolin,
    };
  }

  static InstrumentCategory fromId(String id) =>
      InstrumentCategory.values.firstWhere(
        (e) => e.id == id,
        orElse: () => InstrumentCategory.piano,
      );
}

enum CourseLevel {
  beginner('beginner', 'Beginner'),
  intermediate('intermediate', 'Intermediate'),
  advanced('advanced', 'Advanced');

  const CourseLevel(this.id, this.englishLabel);
  final String id;
  final String englishLabel;

  /// Localized display label (app language).
  String get label {
    final t = L10n.current;
    return switch (this) {
      CourseLevel.beginner => t.levelBeginner,
      CourseLevel.intermediate => t.levelIntermediate,
      CourseLevel.advanced => t.levelAdvanced,
    };
  }

  static CourseLevel fromId(String id) => CourseLevel.values.firstWhere(
        (e) => e.id == id,
        orElse: () => CourseLevel.beginner,
      );
}
