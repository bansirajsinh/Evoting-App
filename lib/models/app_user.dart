import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  final String id;
  final String name;
  final String dateOfBirth;
  final String voterId;
  final String email;
  final String phone;
  final String ward;
  final String status;
  final bool isEligible;
  final bool hasVoted;
  final DateTime? votingTimestamp;
  final DateTime registeredDate;
  final DateTime lastUpdated;
  
  // Regulatory & Verification fields
  final String? aadharNumber; // Encrypted
  final String? pancardNumber; // Encrypted
  final String? voterSlipNumber;
  final String? constituencyType; // General/SC/ST/OBC
  final String? electionCommissionRollNumber;
  final String? verificationStatus; // Verified/Pending/Rejected
  final DateTime? verificationDate;
  final String? verifiedBy;
  final bool aadharVerified;
  final bool mobileVerified;
  final bool emailVerified;
  final bool isResident;
  final String? residencyProof;
  final String? blockedReason;
  final DateTime? blockedDate;
  final String? blockedBy;
  final String role;

  AppUser({
    required this.id,
    required this.name,
    required this.dateOfBirth,
    required this.voterId,
    required this.email,
    required this.phone,
    required this.ward,
    this.status = 'Active',
    this.isEligible = true,
    this.hasVoted = false,
    this.votingTimestamp,
    required this.registeredDate,
    required this.lastUpdated,
    this.aadharNumber,
    this.pancardNumber,
    this.voterSlipNumber,
    this.constituencyType,
    this.electionCommissionRollNumber,
    this.verificationStatus,
    this.verificationDate,
    this.verifiedBy,
    this.aadharVerified = false,
    this.mobileVerified = false,
    this.emailVerified = false,
    this.isResident = true,
    this.residencyProof,
    this.blockedReason,
    this.blockedDate,
    this.blockedBy,
    this.role = 'voter',
  });

  factory AppUser.fromMap(String id, Map<String, dynamic> data) {
    return AppUser(
      id: id,
      name: data['name'] ?? '',
      dateOfBirth: data['dateOfBirth'] ?? '',
      voterId: data['voterId'] ?? '',
      email: data['email'] ?? '',
      phone: data['phone'] ?? '',
      ward: data['ward'] ?? data['constituency'] ?? '',
      status: data['status'] ?? 'Active',
      isEligible: data['isEligible'] ?? true,
      hasVoted: data['hasVoted'] ?? false,
      votingTimestamp: data['votingTimestamp'] != null 
          ? (data['votingTimestamp'] as Timestamp).toDate() 
          : null,
      registeredDate: (data['registeredDate'] as Timestamp?)?.toDate() ?? 
          (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastUpdated: (data['lastUpdated'] as Timestamp?)?.toDate() ?? DateTime.now(),
      aadharNumber: data['aadharNumber'],
      pancardNumber: data['pancardNumber'],
      voterSlipNumber: data['voterSlipNumber'],
      constituencyType: data['constituencyType'],
      electionCommissionRollNumber: data['electionCommissionRollNumber'],
      verificationStatus: data['verificationStatus'],
      verificationDate: (data['verificationDate'] as Timestamp?)?.toDate(),
      verifiedBy: data['verifiedBy'],
      aadharVerified: data['aadharVerified'] ?? false,
      mobileVerified: data['mobileVerified'] ?? false,
      emailVerified: data['emailVerified'] ?? false,
      isResident: data['isResident'] ?? true,
      residencyProof: data['residencyProof'],
      blockedReason: data['blockedReason'],
      blockedDate: (data['blockedDate'] as Timestamp?)?.toDate(),
      blockedBy: data['blockedBy'],
      role: data['role'] ?? 'voter',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'dateOfBirth': dateOfBirth,
      'voterId': voterId,
      'email': email,
      'phone': phone,
      'ward': ward,
      'status': status,
      'isEligible': isEligible,
      'hasVoted': hasVoted,
      'votingTimestamp': votingTimestamp != null ? Timestamp.fromDate(votingTimestamp!) : null,
      'registeredDate': Timestamp.fromDate(registeredDate),
      'lastUpdated': Timestamp.fromDate(lastUpdated),
      'aadharNumber': aadharNumber,
      'pancardNumber': pancardNumber,
      'voterSlipNumber': voterSlipNumber,
      'constituencyType': constituencyType,
      'electionCommissionRollNumber': electionCommissionRollNumber,
      'verificationStatus': verificationStatus,
      'verificationDate': verificationDate != null ? Timestamp.fromDate(verificationDate!) : null,
      'verifiedBy': verifiedBy,
      'aadharVerified': aadharVerified,
      'mobileVerified': mobileVerified,
      'emailVerified': emailVerified,
      'isResident': isResident,
      'residencyProof': residencyProof,
      'blockedReason': blockedReason,
      'blockedDate': blockedDate != null ? Timestamp.fromDate(blockedDate!) : null,
      'blockedBy': blockedBy,
      'role': role,
    };
  }
}
