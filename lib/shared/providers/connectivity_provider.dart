import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/network_info.dart';

final connectivityProvider = Provider<Connectivity>((_) => Connectivity());

final networkInfoProvider = Provider<NetworkInfo>(
  (ref) => NetworkInfoImpl(ref.watch(connectivityProvider)),
);

/// Streams `true` when online, `false` when offline.
final connectivityStatusProvider = StreamProvider<bool>(
  (ref) => ref.watch(networkInfoProvider).onStatusChange,
);
