import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/__entity__.dart';

part '__entity___model.freezed.dart';
part '__entity___model.g.dart';

@freezed
abstract class __Entity__Model with _$__Entity__Model {
  const __Entity__Model._();

  const factory __Entity__Model({
    @JsonKey(includeToJson: false) @Default('') String id,
    required String ownerId,
    @Default('') String title,
    @TimestampConverter() DateTime? createdAt,
  }) = ___Entity__Model;

  factory __Entity__Model.fromJson(Map<String, dynamic> json) =>
      _$__Entity__ModelFromJson(json);

  factory __Entity__Model.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) =>
      __Entity__Model.fromJson({...?doc.data(), 'id': doc.id});

  __Entity__ toEntity() => __Entity__(
        id: id,
        ownerId: ownerId,
        title: title,
        createdAt: createdAt ?? DateTime.fromMillisecondsSinceEpoch(0),
      );
}

/// Firestore Timestamp <-> DateTime. Move to core/utils once shared.
class TimestampConverter implements JsonConverter<DateTime?, Object?> {
  const TimestampConverter();

  @override
  DateTime? fromJson(Object? v) => switch (v) {
        Timestamp t => t.toDate(),
        int ms => DateTime.fromMillisecondsSinceEpoch(ms),
        String s => DateTime.tryParse(s),
        _ => null,
      };

  @override
  Object? toJson(DateTime? d) => d == null ? null : Timestamp.fromDate(d);
}
