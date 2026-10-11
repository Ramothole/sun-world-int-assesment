enum PhotoSyncStatus { pending, uploading, failed }

class PendingPhoto {
  final String id, visitId, path;
  final int totalChunks;
  final DateTime capturedAt;
  final PhotoSyncStatus status;
  final String? lastError;
  PendingPhoto(
      this.id, this.visitId, this.path, this.totalChunks, this.capturedAt,
      {this.status = PhotoSyncStatus.pending, this.lastError});
}
