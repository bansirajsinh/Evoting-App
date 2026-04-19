import 'package:cloud_firestore/cloud_firestore.dart';

class VoterProfile {
  final String id;
  final String name;
  final String voterId;
  final String aadhaar;
  final String email;
  final String phone;
  final String constituency;
  final bool isEligible;
  final DateTime registeredAt;

  VoterProfile({
    required this.id,
    required this.name,
    required this.voterId,
    required this.aadhaar,
    required this.email,
    required this.phone,
    required this.constituency,
    required this.isEligible,
    required this.registeredAt,
  });

  factory VoterProfile.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return VoterProfile(
      id: doc.id,
      name: data['name'] ?? '',
      voterId: data['voterId'] ?? '',
      aadhaar: data['aadhaar'],
      email: data['email'] ?? '',
      phone: data['phone'] ?? data['phoneNumber'] ?? '',
      constituency: data['constituency'],
      isEligible: data['isEligible'] ?? data['profileComplete'] ?? true,
      registeredAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'voterId': voterId,
      'aadhaar': aadhaar,
      'email': email,
      'phone': phone,
      'constituency': constituency,
      'isEligible': isEligible,
      'createdAt': Timestamp.fromDate(registeredAt),
    };
  }
}
