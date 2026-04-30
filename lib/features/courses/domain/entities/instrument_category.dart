/// Three primary instrument categories (Tonebase-style).
enum InstrumentCategory {
  guitar('guitar', 'Guitar'),
  piano('piano', 'Piano'),
  violin('violin', 'Violin');

  const InstrumentCategory(this.id, this.label);
  final String id;
  final String label;

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

  const CourseLevel(this.id, this.label);
  final String id;
  final String label;

  static CourseLevel fromId(String id) => CourseLevel.values.firstWhere(
        (e) => e.id == id,
        orElse: () => CourseLevel.beginner,
      );
}
