// sync_service.dart
// Field sync service — v1, contractor delivery.
// "Tested on office wifi, works great." — contractor

import 'package:sun_world_int_assesment/services.dart';


class SyncService {
  final ApiClient api;
  final LocalDb db;
  bool syncing = false;

  SyncService(this.api, this.db);

  /// Called whenever connectivity changes to "online",
  /// and also every 30 seconds by a timer in main.dart.
  
  Future<void> sync() async {
    if (syncing) return;
    syncing = true;

    try {
      for (final visit in await db.pendingVisits()) {
        try {
          await api.post('/visits', {'idempotencyKey': visit.id, ...visit.toJson()});
          await db.removePendingVisit(visit.id);
        } catch (_) {
        }
      }

      for (final observation in await db.pendingObservations()) {
        try {
          await api.post('/observations', {
            'idempotencyKey': observation.id,
            ...observation.toJson(),
          });
          await db.removePendingObservation(observation.id);
        } catch (_) {
       
        }
      }

    } finally {
      syncing = false;
    }
  }
}