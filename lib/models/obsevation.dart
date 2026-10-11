class Observation {
  final String id;
  final Map<String, dynamic> payload;
  Observation(this.id, this.payload);
  Map<String, dynamic> toJson() => {'id': id, ...payload};
}
