import 'package:flutter/material.dart';
import '../../../../l10n/l10n.dart';

/// What kind of media a lecture exposes — drives the icon, the player surface,
/// and whether it streams or downloads.
enum LectureType {
  video('video', 'Video'),
  audio('audio', 'Audio'),
  pdf('pdf', 'PDF'),
  doc('doc', 'Document');

  const LectureType(this.id, this.englishLabel);

  final String id;
  final String englishLabel;

  /// Localized display label (app language).
  String get label {
    final t = L10n.current;
    return switch (this) {
      LectureType.video => t.lectureTypeVideo,
      LectureType.audio => t.lectureTypeAudio,
      LectureType.pdf => t.lectureTypePdf,
      LectureType.doc => t.lectureTypeDoc,
    };
  }

  static LectureType fromId(String id) => LectureType.values.firstWhere(
        (e) => e.id == id,
        orElse: () => LectureType.video,
      );

  bool get isPlayable => this == LectureType.video || this == LectureType.audio;
  bool get isDocument => this == LectureType.pdf || this == LectureType.doc;

  IconData get icon {
    switch (this) {
      case LectureType.video:
        return Icons.play_circle_outline_rounded;
      case LectureType.audio:
        return Icons.headphones_rounded;
      case LectureType.pdf:
        return Icons.picture_as_pdf_outlined;
      case LectureType.doc:
        return Icons.description_outlined;
    }
  }
}
