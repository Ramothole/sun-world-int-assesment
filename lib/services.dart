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
}