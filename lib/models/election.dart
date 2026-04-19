
import 'package:cloud_firestore/cloud_firestore.dart';

class Election {
  final String id;
  final String title;
  final String description;
  final String type;
  final DateTime startDate;
  final DateTime endDate;
  final String state;
  final String district;
  final List<String> constituencies;
  final String status;
  final DateTime createdAt;
  final String? contractAddress;

  Election({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.startDate,
    required this.endDate,
    required this.state,
    required this.district,
    required this.constituencies,
    required this.status,
    required this.createdAt,
    this.contractAddress,
  });

  factory Election.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Election(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      type: data['type'] ?? 'General',
      startDate: (data['startDate'] as Timestamp).toDate(),
      endDate: (data['endDate'] as Timestamp).toDate(),
      state: data['state'] ?? '',
      district: data['district'] ?? '',
      constituencies: List<String>.from(data['constituencies'] ?? []),
      status: data['status'] ?? 'Upcoming',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      contractAddress: data['contractAddress'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'type': type,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'state': state,
      'district': district,
      'constituencies': constituencies, // ⚠️ you forgot this also
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt), // ✅ add this
      'contractAddress': contractAddress,
    };
  }
}
