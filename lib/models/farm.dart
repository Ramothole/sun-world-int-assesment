class Farm {
  final String id;
  final int revision;
  final bool hasUnsyncedChanges;
  final DateTime updatedAt;
  final Map<String, dynamic> payload;
  Farm(this.id, this.revision, this.hasUnsyncedChanges, this.payload)
      : updatedAt = DateTime.now().toUtc();
  Map<String, dynamic> toJson() => {'id': id, 'revision': revision, 'updatedAt': updatedAt, ...payload};
}
