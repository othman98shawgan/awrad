import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/awrad_backup.dart';
import 'awrad_provider.dart';
import 'backup_service.dart';
import 'prayer_provider.dart';

final Provider<BackupService> backupServiceProvider =
    Provider<BackupService>((ref) {
  final awradRepo = ref.watch(awradRepositoryProvider);
  final prayerRepo = ref.watch(prayerRepositoryProvider);
  final service = BackupService(
    awradRepo: awradRepo,
    prayerRepo: prayerRepo,
    onAutoBackupSaved: () => ref.invalidate(autoBackupInfoProvider),
  );
  ref.onDispose(service.dispose);
  return service;
});

final FutureProvider<AutoBackupInfo?> autoBackupInfoProvider =
    FutureProvider<AutoBackupInfo?>((ref) async {
  return ref.watch(backupServiceProvider).getAutoBackupInfo();
});

/// Reloads all Awrad, prayer, and progress providers after a backup restore or import.
Future<void> refreshAllDataProviders(WidgetRef ref) async {
  await ref.read(awradTasksProvider.notifier).reload();
  ref.invalidate(dailyAwradLogProvider);
  ref.invalidate(prayerListProvider);
  ref.read(awradDataVersionProvider.notifier).state++;
  ref.read(prayerDataVersionProvider.notifier).state++;
  ref.invalidate(autoBackupInfoProvider);
}
