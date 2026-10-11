import 'package:sun_world_int_assesment/models/farm.dart';
import 'package:sun_world_int_assesment/outbox.dart' show Observation;
import 'package:sun_world_int_assesment/models/pending_photos.dart';
import 'package:sun_world_int_assesment/models/visitors.dart';
import 'package:sun_world_int_assesment/services.dart';
import 'package:sun_world_int_assesment/sync_service.dart';
import 'package:test/test.dart';

class FakeDb implements LocalDb {
  final Map<String, PendingPhoto> photos = <String, PendingPhoto>{};
  final Map<String, int> nextChunks = <String, int>{};
  final List<String> statusLog = <String>[];
  final Map<String, String?> lastErrors = <String, String?>{};
  bool failStatusSave = false;

  PhotoSyncStatus? statusOf(String id) {
    for (final entry in statusLog.reversed) {
      final parts = entry.split(':');
      if (parts[0] == id) return PhotoSyncStatus.values.byName(parts[1]);
    }
    return null;
  }

  @override
  Future<List<PendingPhoto>> pendingPhotos() async => photos.values.toList();

  @override
  Future<void> removePendingPhoto(String id) async => photos.remove(id);

  @override
  Future<int> nextPhotoChunk(String id) async => nextChunks[id] ?? 0;

  @override
  Future<void> saveNextPhotoChunk(String id, int nextChunk) async =>
      nextChunks[id] = nextChunk;

  @override
  Future<List<int>> readPhotoChunk(PendingPhoto photo, int index) async =>
      [index];

  @override
  Future<void> savePhotoSyncStatus(String id, PhotoSyncStatus status,
      {String? error}) async {
    if (failStatusSave && status == PhotoSyncStatus.failed) {
      throw Exception('disk full');
    }
    statusLog.add('$id:${status.name}');
    lastErrors[id] = error;
  }

  @override
  Future<List<Visit>> pendingVisits() async => [];

  @override
  Future<void> removePendingVisit(String id) async {}

  @override
  Future<List<Observation>> pendingObservations() async => [];

  @override
  Future<void> removePendingObservation(String id) async {}

  @override
  Future<Farm?> getFarm(String id) async => null;

  @override
  Future<void> saveFarm(dynamic farm) async {}

  @override
  Future<void> saveConflict(Farm local, dynamic server) async {}
}

class FakeApi implements ApiClient {
  final List<String> chunkPosts = <String>[];

  /// Throws a network error the first time this chunk index is posted.
  int? dropConnectionAtChunk;
  bool _dropped = false;

  /// Overrides the server's `nextChunk` acknowledgement.
  int Function(int chunkIndex)? nextChunkResponse;

  @override
  Future<dynamic> get(String path) async => <dynamic>[];

  @override
  Future<dynamic> post(String path, Map<String, dynamic> body) async {
    if (!path.startsWith('/photos/')) return null;
    final index = body['chunkIndex'] as int;
    chunkPosts.add(body['idempotencyKey'] as String);
    if (dropConnectionAtChunk == index && !_dropped) {
      _dropped = true;
      throw Exception('Connection dropped');
    }
    return {'nextChunk': nextChunkResponse?.call(index) ?? index + 1};
  }
}

PendingPhoto photo(String id, {int totalChunks = 3}) =>
    PendingPhoto(id, 'visit-1', '/tmp/$id.jpg', totalChunks,
        DateTime.utc(2026, 10, 11));

void main() {
  late FakeDb db;
  late FakeApi api;
  late SyncService service;

  setUp(() {
    db = FakeDb();
    api = FakeApi();
    service = SyncService(api, db);
  });

  group('photo sync status', () {
    test('new photos default to pending with no error', () {
      final p = photo('photo-1');
      expect(p.status, PhotoSyncStatus.pending);
      expect(p.lastError, isNull);
    });

    test('successful upload marks uploading then removes the photo', () async {
      db.photos['photo-1'] = photo('photo-1');

      await service.sync();

      expect(db.statusLog, ['photo-1:uploading']);
      expect(api.chunkPosts, ['photo-1:0', 'photo-1:1', 'photo-1:2']);
      expect(db.photos, isEmpty);
    });

    test('network failure marks photo failed and keeps progress', () async {
      api.dropConnectionAtChunk = 1;
      db.photos['photo-1'] = photo('photo-1');

      await service.sync();

      expect(db.statusOf('photo-1'), PhotoSyncStatus.failed);
      expect(db.lastErrors['photo-1'], contains('Connection dropped'));
      expect(db.photos, contains('photo-1'));
      expect(db.nextChunks['photo-1'], 1);
    });

    test('invalid nextChunk response records UploadFailure reason', () async {
      api.nextChunkResponse = (index) => index; // Server never advances.
      db.photos['photo-1'] = photo('photo-1');

      await service.sync();

      expect(db.statusOf('photo-1'), PhotoSyncStatus.failed);
      expect(db.lastErrors['photo-1'], 'Invalid nextChunk 0 after chunk 0');
      expect(db.photos, contains('photo-1'));
    });

    test('nextChunk beyond totalChunks is rejected', () async {
      api.nextChunkResponse = (_) => 99;
      db.photos['photo-1'] = photo('photo-1');

      await service.sync();

      expect(db.statusOf('photo-1'), PhotoSyncStatus.failed);
      expect(db.nextChunks, isNot(contains('photo-1')));
    });

    test('failed photo retries from last acknowledged chunk', () async {
      api.dropConnectionAtChunk = 2;
      db.photos['photo-1'] = photo('photo-1');

      await service.sync();
      expect(db.statusOf('photo-1'), PhotoSyncStatus.failed);

      await service.sync();

      expect(db.statusLog,
          ['photo-1:uploading', 'photo-1:failed', 'photo-1:uploading']);
      expect(api.chunkPosts,
          ['photo-1:0', 'photo-1:1', 'photo-1:2', 'photo-1:2']);
      expect(db.photos, isEmpty);
    });

    test('one failed photo does not block the next', () async {
      api.dropConnectionAtChunk = 0;
      db.photos['photo-1'] = photo('photo-1', totalChunks: 1);
      db.photos['photo-2'] = photo('photo-2', totalChunks: 1);

      await service.sync();

      expect(db.statusOf('photo-1'), PhotoSyncStatus.failed);
      expect(db.photos.keys, ['photo-1']);
    });

    test('error saving failed status does not abort the sync', () async {
      api.dropConnectionAtChunk = 0;
      db.failStatusSave = true;
      db.photos['photo-1'] = photo('photo-1', totalChunks: 1);
      db.photos['photo-2'] = photo('photo-2', totalChunks: 1);

      await expectLater(service.sync(), completes);

      expect(db.photos.keys, ['photo-1']);
      expect(service.syncing, isFalse);
    });
  });
}
