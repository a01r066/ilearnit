import 'package:flutter/material.dart';

/// What kind of media a lecture exposes — drives the icon, the player surface,
/// and whether it streams or downloads.
enum LectureType {
  video('video', 'Video'),
  audio('audio', 'Audio'),
  pdf('pdf', 'PDF'),
  doc('doc', 'Document');

  const LectureType(this.id, this.label);

  final String id;
  final String label;

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
