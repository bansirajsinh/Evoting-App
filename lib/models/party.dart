import 'package:cloud_firestore/cloud_firestore.dart';

class Party {
  final String partyId;
  final String partyName;
  final String partyShortCode;
  final String partyColor;
  final String partySymbol;
  final String? partyLogo;
  final String? partyDescription;
  final String? registrationNumber;
  final bool isNationalParty;
  final bool isStateParty;
  final bool isRecognizedParty;
  final int totalCandidates;
  final int totalVotes;
  final double votePercentage;
  final DateTime createdDate;
  final DateTime updatedDate;
  final String status;
  
  // Optional advanced fields
  final String? partyPresident;
  final String? partyWebsite;
  final String? partyContact;
  final String? partyHeadquarters;
  final int? foundedYear;
  final String? partyIdeology;

  Party({
    required this.partyId,
    required this.partyName,
    required this.partyShortCode,
    required this.partyColor,
    required this.partySymbol,
    this.partyLogo,
    this.partyDescription,
    this.registrationNumber,
    this.isNationalParty = false,
    this.isStateParty = false,
    this.isRecognizedParty = false,
    this.totalCandidates = 0,
    this.totalVotes = 0,
    this.votePercentage = 0.0,
    required this.createdDate,
    required this.updatedDate,
    required this.status,
    this.partyPresident,
    this.partyWebsite,
    this.partyContact,
    this.partyHeadquarters,
    this.foundedYear,
    this.partyIdeology,
  });

  factory Party.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Party(
      partyId: doc.id,
      partyName: data['partyName'] ?? '',
      partyShortCode: data['partyShortCode'] ?? '',
      partyColor: data['partyColor'] ?? '#000000',
      partySymbol: data['partySymbol'] ?? '',
      partyLogo: data['partyLogo'],
      partyDescription: data['partyDescription'],
      registrationNumber: data['registrationNumber'],
      isNationalParty: data['isNationalParty'] ?? false,
      isStateParty: data['isStateParty'] ?? false,
      isRecognizedParty: data['isRecognizedParty'] ?? false,
      totalCandidates: data['totalCandidates'] ?? 0,
      totalVotes: data['totalVotes'] ?? 0,
      votePercentage: (data['votePercentage'] ?? 0.0).toDouble(),
      createdDate: data['createdDate'] != null 
          ? (data['createdDate'] as Timestamp).toDate() 
          : DateTime.now(),
      updatedDate: data['updatedDate'] != null 
          ? (data['updatedDate'] as Timestamp).toDate() 
          : DateTime.now(),
      status: data['status'] ?? 'Active',
      partyPresident: data['partyPresident'],
      partyWebsite: data['partyWebsite'],
      partyContact: data['partyContact'],
      partyHeadquarters: data['partyHeadquarters'],
      foundedYear: data['foundedYear'],
      partyIdeology: data['partyIdeology'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'partyName': partyName,
      'partyShortCode': partyShortCode,
      'partyColor': partyColor,
      'partySymbol': partySymbol,
      'partyLogo': partyLogo,
      'partyDescription': partyDescription,
      'registrationNumber': registrationNumber,
      'isNationalParty': isNationalParty,
      'isStateParty': isStateParty,
      'isRecognizedParty': isRecognizedParty,
      'totalCandidates': totalCandidates,
      'totalVotes': totalVotes,
      'votePercentage': votePercentage,
      'createdDate': Timestamp.fromDate(createdDate),
      'updatedDate': Timestamp.fromDate(updatedDate),
      'status': status,
      'partyPresident': partyPresident,
      'partyWebsite': partyWebsite,
      'partyContact': partyContact,
      'partyHeadquarters': partyHeadquarters,
      'foundedYear': foundedYear,
      'partyIdeology': partyIdeology,
    };
  }

  // Helper to generate party ID
  static String generatePartyId(String shortCode) {
    return 'PTY_${shortCode.toUpperCase()}';
  }
}