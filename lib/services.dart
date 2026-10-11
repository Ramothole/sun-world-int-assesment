import 'package:sun_world_int_assesment/models/farm.dart';
import 'package:sun_world_int_assesment/models/pending_photos.dart';
import 'package:sun_world_int_assesment/models/visitors.dart';
import 'package:sun_world_int_assesment/outbox.dart';

abstract class ApiClient {
  Future<dynamic> get(String path);
  Future<dynamic> post(String path, Map<String, dynamic> body);
}

abstract class LocalDb {
  Future<List<PendingPhoto>> pendingPhotos();
  Future<void> removePendingPhoto(String id);
  Future<List<Visit>> pendingVisits();
  Future<void> removePendingVisit(String id);
  Future<List<Observation>> pendingObservations();
  Future<void> removePendingObservation(String id);
  Future<Farm?> getFarm(String id);
  Future<void> saveFarm(dynamic farm);
  Future<void> saveConflict(Farm local, dynamic server);
  Future<int> nextPhotoChunk(String id);
  Future<void> saveNextPhotoChunk(String id, int nextChunk);
  Future<List<int>> readPhotoChunk(PendingPhoto photo, int index);
  Future<void> savePhotoSyncStatus(String id, PhotoSyncStatus status,
      {String? error});

}

class UploadFailure implements Exception {
  final String reason;
  const UploadFailure(this.reason);

  @override
  String toString() => 'UploadFailure($reason)';
}