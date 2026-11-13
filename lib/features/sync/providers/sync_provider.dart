import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/connectivity_service.dart';
import '../services/sync_engine.dart';

final connectivityServiceProvider = Provider<ConnectivityService>((ref) {
  final service = ConnectivityService();
  ref.onDispose(() => service.dispose());
  return service;
});

final isOnlineProvider = StreamProvider<bool>((ref) {
  final service = ref.watch(connectivityServiceProvider);
  return service.onConnectivityChanged;
});

final syncEngineProvider = Provider<SyncEngine>((ref) {
  final connectivity = ref.watch(connectivityServiceProvider);
  final engine = SyncEngine(connectivityService: connectivity);
  ref.onDispose(() => engine.dispose());
  return engine;
});

final syncStatusProvider = StreamProvider<SyncStatusState>((ref) {
  final engine = ref.watch(syncEngineProvider);
  return engine.statusStream;
});
