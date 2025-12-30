class Member {
  final int? id;
  final String name;
  final int displayOrder;

  Member({
    this.id,
    required this.name,
    this.displayOrder = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'display_order': displayOrder,
    };
  }

  factory Member.fromMap(Map<String, dynamic> map) {
    return Member(
      id: map['id'] as int?,
      name: map['name'] as String,
      displayOrder: map['display_order'] as int? ?? 0,
    );
  }

  Member copyWith({
    int? id,
    String? name,
    int? displayOrder,
  }) {
    return Member(
      id: id ?? this.id,
      name: name ?? this.name,
      displayOrder: displayOrder ?? this.displayOrder,
    );
  }
}
