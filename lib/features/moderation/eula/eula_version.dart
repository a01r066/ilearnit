/// Current EULA / Community Guidelines version.
///
/// Bump this when the policy changes meaningfully. Users whose
/// `users/{uid}.eulaAcceptedVersion` is lower will be re-prompted on
/// their next app open via [EulaGate].
///
/// Don't reuse numbers — once you've stamped v3 on production users,
/// rolling back to v2 silently makes a re-prompt impossible.
const int kCurrentEulaVersion = 1;

/// Compact human-readable label shown on the re-prompt sheet, e.g.
/// "Updated Sep 2026". Update alongside [kCurrentEulaVersion].
const String kCurrentEulaPublishedLabel = 'June 2026';
