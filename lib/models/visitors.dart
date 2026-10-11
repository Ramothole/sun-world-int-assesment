class Visit {
  final String id;
  final Map<String, dynamic> payload;
  Visit(this.id, this.payload);
  Map<String, dynamic> toJson() => {'id': id, ...payload};
}
