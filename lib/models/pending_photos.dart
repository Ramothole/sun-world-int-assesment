class PendingPhoto {
  final String id, visitId, path;
  final int totalChunks;
  final DateTime capturedAt;
  PendingPhoto(
      this.id, this.visitId, this.path, this.totalChunks, this.capturedAt);
}
