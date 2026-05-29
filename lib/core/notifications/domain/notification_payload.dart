/// Parsed shape of the `data` map that comes attached to every push
/// notification we send.
///
/// Wire format produced by `functions/src/index.ts`:
///
/// ```json
/// {
///   "notification": { "title": "...", "body": "..." },
///   "data": {
///     "type": "application_approved" | "application_rejected"
///           | "enrollment_created" | "broadcast",
///     "route": "/my-courses" | "/pending" | "/courses/<id>" | "/",
///     "courseId": "<id>",
///     "broadcastId": "<id>"
///   }
/// }
/// ```
///
/// Keep the `type` literals in sync with the `NotificationType` enum below
/// and with the strings used in Cloud Functions.
class NotificationPayload {
  const NotificationPayload({
    required this.type,
    this.route,
    this.params = const {},
  });

  final NotificationType type;
  final String? route;
  final Map<String, String> params;

  String? get courseId => params['courseId'];
  String? get broadcastId => params['broadcastId'];

  factory NotificationPayload.fromData(Map<String, dynamic> data) {
    final raw = <String, String>{
      for (final e in data.entries)
        if (e.value != null) e.key: e.value.toString(),
    };
    return NotificationPayload(
      type: NotificationType.fromId(raw['type']),
      route: raw['route'],
      params: raw,
    );
  }

  Map<String, dynamic> toJson() => {
        'type': type.id,
        if (route != null) 'route': route,
        ...params,
      };
}

/// Discriminator for the in-app routing logic. Every push we send carries
/// one of these in `data.type` so the tap handler knows where to take the
/// user.
enum NotificationType {
  applicationApproved('application_approved'),
  applicationRejected('application_rejected'),
  enrollmentCreated('enrollment_created'),
  broadcast('broadcast'),
  unknown('unknown');

  const NotificationType(this.id);
  final String id;

  static NotificationType fromId(String? raw) {
    if (raw == null) return NotificationType.unknown;
    for (final t in NotificationType.values) {
      if (t.id == raw) return t;
    }
    return NotificationType.unknown;
  }
}
