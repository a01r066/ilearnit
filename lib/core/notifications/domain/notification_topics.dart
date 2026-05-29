/// FCM topic catalogue.
///
/// Topics are how we fan a single send out to many devices. Each user can
/// be subscribed to multiple topics simultaneously.
///
/// Keep these in lockstep with `functions/src/index.ts` — the strings on
/// the wire must match exactly.
class NotificationTopics {
  const NotificationTopics._();

  /// Everyone with notifications enabled. Used by admin broadcasts.
  static const String allUsers = 'all_users';

  /// Per-instrument topic. Users are auto-subscribed based on their
  /// `users/{uid}.primaryInstrument` (if set).
  static const String instrumentGuitar = 'instrument_guitar';
  static const String instrumentPiano = 'instrument_piano';
  static const String instrumentViolin = 'instrument_violin';

  /// Admins-only topic for platform-level alerts.
  static const String admins = 'admins';

  /// Resolve an instrument id ('guitar' | 'piano' | 'violin') to its topic.
  static String? forInstrument(String? primaryInstrument) {
    switch (primaryInstrument) {
      case 'guitar':
        return instrumentGuitar;
      case 'piano':
        return instrumentPiano;
      case 'violin':
        return instrumentViolin;
      default:
        return null;
    }
  }

  /// Every topic exposed to the admin "send notification" UI. The UI
  /// renders these as dropdown options.
  static const List<String> broadcastTargets = [
    allUsers,
    instrumentGuitar,
    instrumentPiano,
    instrumentViolin,
  ];
}
