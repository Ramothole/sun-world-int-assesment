abstract class OutboxItem {
  String get id;
  DateTime get createdAt;
}

class VisitRecord implements OutboxItem {
  final String id;
  final String farmId;
  final String agentId;
  final String purpose;
  final DateTime visitedAt;
  final DateTime createdAt;
  final Map<String, Object?> fields;

  VisitRecord(
      {required this.id,
      required this.farmId,
      required this.agentId,
      required this.purpose,
      required this.visitedAt,
      required this.createdAt,
      this.fields = const {}});

  Map<String, Object?> toJson() => {
        'id': id,
        'farmId': farmId,
        'agentId': agentId,
        'purpose': purpose,
        'visitedAt': visitedAt.toUtc().toIso8601String(),
        'createdAt': createdAt.toUtc().toIso8601String(),
        'fields': fields,
      };
}

class Observation implements OutboxItem {
  final String id;
  final String visitId;
  final String type;
  final String value;
  final String agentId;
  final DateTime createdAt;
  Observation(
      {required this.id,
      required this.visitId,
      required this.type,
      required this.value,
      required this.agentId,
      required this.createdAt});
  Map<String, Object?> toJson() => {
        'id': id,
        'visitId': visitId,
        'type': type,
        'value': value,
        'agentId': agentId,
        'createdAt': createdAt.toUtc().toIso8601String()
      };
}

class PhotoUpload implements OutboxItem {
  final String id;
  final String visitId;
  final String localPath;
  final int totalChunks;
  final DateTime capturedAt;
  final DateTime createdAt;
  PhotoUpload(
      {required this.id,
      required this.visitId,
      required this.localPath,
      required this.totalChunks,
      required this.capturedAt,
      required this.createdAt})
      : assert(totalChunks > 0);
}
