import 'package:cloud_firestore/cloud_firestore.dart';

class Agent {
  const Agent({
    required this.id,
    required this.name,
    required this.phone,
    required this.area,
    required this.isActive,
    required this.deliveriesCompleted,
  });

  final String id;
  final String name;
  final String phone;
  final String area;
  final bool isActive;
  final int deliveriesCompleted;

  String get initials {
    final parts = name.split(' ').where((part) => part.isNotEmpty).toList();
    if (parts.isEmpty) {
      return 'SC';
    }
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  Agent copyWith({
    String? id,
    String? name,
    String? phone,
    String? area,
    bool? isActive,
    int? deliveriesCompleted,
  }) {
    return Agent(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      area: area ?? this.area,
      isActive: isActive ?? this.isActive,
      deliveriesCompleted: deliveriesCompleted ?? this.deliveriesCompleted,
    );
  }

  factory Agent.fromMap(Map<String, dynamic> map, {String? id}) {
    return Agent(
      id: id ?? map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      area: map['area'] as String? ?? '',
      isActive: map['isActive'] as bool? ?? true,
      deliveriesCompleted: map['deliveriesCompleted'] as int? ?? 0,
    );
  }

  factory Agent.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    return Agent.fromMap(doc.data() ?? const {}, id: doc.id);
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'area': area,
      'isActive': isActive,
      'deliveriesCompleted': deliveriesCompleted,
      'updatedAt': DateTime.now(),
    };
  }
}
