// sync_service.dart
// Field sync service — v1, contractor delivery.
// "Tested on office wifi, works great." — contractor

import 'dart:convert';

import 'package:sun_world_int_assesment/models/pending_photos.dart';
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
          await api
              .post('/visits', {'idempotencyKey': visit.id, ...visit.toJson()});
          await db.removePendingVisit(visit.id);
        } catch (_) {}
      }

      for (final observation in await db.pendingObservations()) {
        try {
          await api.post('/observations', {
            'idempotencyKey': observation.id,
            ...observation.toJson(),
          });
          await db.removePendingObservation(observation.id);
        } catch (_) {}
      }
      
      for (final photo in await db.pendingPhotos()) {
        try {
          await db.savePhotoSyncStatus(photo.id, PhotoSyncStatus.uploading);
          var nextChunk = await db.nextPhotoChunk(photo.id);
          while (nextChunk < photo.totalChunks) {
            final chunk = await db.readPhotoChunk(photo, nextChunk);
            final result = await api.post('/photos/${photo.id}/chunks', {
              'idempotencyKey': '${photo.id}:$nextChunk',
              'visitId': photo.visitId,
              'capturedAt': photo.capturedAt.toUtc().toIso8601String(),
              'chunkIndex': nextChunk,
              'totalChunks': photo.totalChunks,
              'data': base64Encode(chunk),
            });
            final acknowledgedNext = (result as Map)['nextChunk'] as int;
            if (acknowledgedNext <= nextChunk || acknowledgedNext > photo.totalChunks) {
              throw UploadFailure(
                  'Invalid nextChunk $acknowledgedNext after chunk $nextChunk');
            }
            nextChunk = acknowledgedNext;
            await db.saveNextPhotoChunk(photo.id, nextChunk);
          }
          await db.removePendingPhoto(photo.id);
        } catch (e) {
          // Do not remove photo; keep its last acknowledged chunk for later resume.
          final reason = e is UploadFailure ? e.reason : e.toString();
          try {
            await db.savePhotoSyncStatus(photo.id, PhotoSyncStatus.failed,
                error: reason);
          } catch (_) {}
        }
      }
      // Pull server-side changes and reconcile.
      final serverFarms = await api.get('/farms/updates');
      for (final serverFarm in serverFarms) {
        final localFarm = await db.getFarm(serverFarm['id']);
        if (localFarm == null) {
          await db.saveFarm(serverFarm);
          continue;
        }
        // Conflict resolution: newest edit wins.
        final serverTime = DateTime.parse(serverFarm['updatedAt']);
        if (localFarm.updatedAt.isAfter(serverTime)) {
          // Our local edit is newer — push it up.
          await api.post('/farms/${localFarm.id}', localFarm.toJson());
        }
        if (localFarm.hasUnsyncedChanges) {
          await db.saveConflict(localFarm, serverFarm);
        } else {
          // Server is newer — take it, discard local changes.
          await db.saveFarm(serverFarm);
        }
      }
    } finally {
      syncing = false;
    }
  }
}
