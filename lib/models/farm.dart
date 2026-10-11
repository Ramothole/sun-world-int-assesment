class Farm {
  final String id;
  final int revision;
  final bool hasUnsyncedChanges;
  final Map<String, dynamic> payload;
  Farm(this.id, this.revision, this.hasUnsyncedChanges, this.payload);
  Map<String, dynamic> toJson() => {'id': id, 'revision': revision, ...payload};
}
