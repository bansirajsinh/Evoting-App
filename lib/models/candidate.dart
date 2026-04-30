import 'package:cloud_firestore/cloud_firestore.dart';

class Candidate {
  final String id;
  final String candidateName;
  final String partyId;
  final String partySymbol;
  final String electionId;
  final String ward;
  final String? photo;
  final int voteCount;
  final String status;
  final DateTime? createdDate;
  
  // New fields for district-level elections
  final DateTime? dateOfBirth;
  final String? gender;
  final String? qualification;
  final String? phone;
  final String? email;
  final String? address;
  
  // Regulatory compliance fields
  final String? aadharNumber;
  final String? panNumber;
  final bool? criminalRecord;
  final String? criminalDetails;
  final String? assetValue;
  final String? educationCertificate;
  final String? nominationFormDocument;
  final String? nomineeStatus;
  final String? nominationNumber;
  final String? nomineeAffidavit;
  final String? photoFIR;
  final DateTime? withdrawalDate;
  final String? disqualificationReason;
  final String? ballotSymbol;
  final int? ballotPosition;
  final String? nominationFormStatus;

  Candidate({
    required this.id,
    required this.candidateName,
    required this.partyId,
    required this.partySymbol,
    required this.electionId,
    required this.ward,
    this.photo,
    required this.voteCount,
    required this.status,
    this.createdDate,
    this.dateOfBirth,
    this.gender,
    this.qualification,
    this.phone,
    this.email,
    this.address,
    this.aadharNumber,
    this.panNumber,
    this.criminalRecord,
    this.criminalDetails,
    this.assetValue,
    this.educationCertificate,
    this.nominationFormDocument,
    this.nomineeStatus,
    this.nominationNumber,
    this.nomineeAffidavit,
    this.photoFIR,
    this.withdrawalDate,
    this.disqualificationReason,
    this.ballotSymbol,
    this.ballotPosition,
    this.nominationFormStatus,
  });

  // FIX: Made electionId optional parameter since it's also stored in the document data.
  // This way it works both when called with 1 arg (from streams) and 2 args.
  factory Candidate.fromFirestore(DocumentSnapshot doc, [String? electionId]) {
    final data = doc.data() as Map<String, dynamic>;

    return Candidate(
      id: doc.id,
      candidateName: data['candidateName'] ?? data['name'] ?? '',
      partyId: data['partyId'] ?? data['party'] ?? '',
      partySymbol: data['partySymbol'] ?? data['symbol'] ?? '',
      electionId: electionId ?? data['electionId'] ?? '',
      ward: data['ward'] ?? data['constituency'] ?? 'Ward 1',
      photo: data['photo'],
      voteCount: (data['voteCount'] ?? data['votes'] ?? 0) as int,
      status: data['status'] ?? 'Active',
      createdDate: data['createdDate'] != null 
          ? (data['createdDate'] as Timestamp).toDate() 
          : null,
      dateOfBirth: data['dateOfBirth'] != null 
          ? (data['dateOfBirth'] as Timestamp).toDate() 
          : null,
      gender: data['gender'],
      qualification: data['qualification'],
      phone: data['phone'],
      email: data['email'],
      address: data['address'],
      aadharNumber: data['aadharNumber'],
      panNumber: data['panNumber'],
      criminalRecord: data['criminalRecord'],
      criminalDetails: data['criminalDetails'],
      assetValue: data['assetValue'],
      educationCertificate: data['educationCertificate'],
      nominationFormDocument: data['nominationFormDocument'],
      nomineeStatus: data['nomineeStatus'],
      nominationNumber: data['nominationNumber'],
      nomineeAffidavit: data['nomineeAffidavit'],
      photoFIR: data['photoFIR'],
      withdrawalDate: data['withdrawalDate'] != null 
          ? (data['withdrawalDate'] as Timestamp).toDate() 
          : null,
      disqualificationReason: data['disqualificationReason'],
      ballotSymbol: data['ballotSymbol'],
      ballotPosition: data['ballotPosition'],
      nominationFormStatus: data['nominationFormStatus'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'candidateName': candidateName,
      'partyId': partyId,
      'partySymbol': partySymbol,
      'electionId': electionId,
      'ward': ward,
      'photo': photo,
      'voteCount': voteCount,
      'status': status,
      'createdDate': createdDate != null ? Timestamp.fromDate(createdDate!) : null,
      'dateOfBirth': dateOfBirth != null ? Timestamp.fromDate(dateOfBirth!) : null,
      'gender': gender,
      'qualification': qualification,
      'phone': phone,
      'email': email,
      'address': address,
      'aadharNumber': aadharNumber,
      'panNumber': panNumber,
      'criminalRecord': criminalRecord,
      'criminalDetails': criminalDetails,
      'assetValue': assetValue,
      'educationCertificate': educationCertificate,
      'nominationFormDocument': nominationFormDocument,
      'nomineeStatus': nomineeStatus,
      'nominationNumber': nominationNumber,
      'nomineeAffidavit': nomineeAffidavit,
      'photoFIR': photoFIR,
      'withdrawalDate': withdrawalDate != null ? Timestamp.fromDate(withdrawalDate!) : null,
      'disqualificationReason': disqualificationReason,
      'ballotSymbol': ballotSymbol,
      'ballotPosition': ballotPosition,
      'nominationFormStatus': nominationFormStatus,
    };
  }
}
