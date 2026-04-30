
import 'package:cloud_firestore/cloud_firestore.dart';

class Election {
  final String uid;
  final String electionId; // New: GUJ_AHM_MC_2026 format
  final String title;
  final String description;
  final String electionType; // Fixed: "Municipal Corporation"
  final int totalWards;
  final DateTime? notificationDate;
  final DateTime? nominationStartDate;
  final DateTime? nominationEndDate;
  final DateTime? scrutinyDate;
  final DateTime? withdrawalDate;
  final DateTime? campaignStartDate;
  final DateTime? campaignEndDate;
  final DateTime pollingDate;
  final DateTime? resultDate;
  final String status;
  final String? contractAddress;
  final DateTime createdAt;
  final String createdBy;
  
  // New fields for district-level elections
  final String? electionCommissionNotification;
  final Map<String, int>? reservedSeats;
  final int? womenReservation;
  final int? totalElectors;
  final int? estimatedTurnout;
  final String? conductingAuthority;
  final String? municipalityType;
  final String district; // Fixed per deployment

  Election({
    required this.uid,
    required this.electionId,
    required this.title,
    required this.description,
    required this.electionType,
    required this.totalWards,
    this.notificationDate,
    this.nominationStartDate,
    this.nominationEndDate,
    this.scrutinyDate,
    this.withdrawalDate,
    this.campaignStartDate,
    this.campaignEndDate,
    required this.pollingDate,
    this.resultDate,
    required this.status,
    this.contractAddress,
    required this.createdAt,
    required this.createdBy,
    this.electionCommissionNotification,
    this.reservedSeats,
    this.womenReservation,
    this.totalElectors,
    this.estimatedTurnout,
    this.conductingAuthority,
    this.municipalityType,
    required this.district,
  });

  factory Election.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Election(
      uid: doc.id,
      electionId: data['electionId'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      electionType: data['electionType'] ?? 'Municipal Corporation',
      totalWards: data['totalWards'] ?? 0,
      notificationDate: data['notificationDate'] != null 
          ? (data['notificationDate'] as Timestamp).toDate() 
          : null,
      nominationStartDate: data['nominationStartDate'] != null 
          ? (data['nominationStartDate'] as Timestamp).toDate() 
          : null,
      nominationEndDate: data['nominationEndDate'] != null 
          ? (data['nominationEndDate'] as Timestamp).toDate() 
          : null,
      scrutinyDate: data['scrutinyDate'] != null 
          ? (data['scrutinyDate'] as Timestamp).toDate() 
          : null,
      withdrawalDate: data['withdrawalDate'] != null 
          ? (data['withdrawalDate'] as Timestamp).toDate() 
          : null,
      campaignStartDate: data['campaignStartDate'] != null 
          ? (data['campaignStartDate'] as Timestamp).toDate() 
          : null,
      campaignEndDate: data['campaignEndDate'] != null 
          ? (data['campaignEndDate'] as Timestamp).toDate() 
          : null,
      pollingDate: data['pollingDate'] != null 
          ? (data['pollingDate'] as Timestamp).toDate() 
          : DateTime.now(),
      resultDate: data['resultDate'] != null 
          ? (data['resultDate'] as Timestamp).toDate() 
          : null,
      status: data['status'] ?? 'Notified',
      contractAddress: data['contractAddress'],
      createdAt: data['createdAt'] != null 
          ? (data['createdAt'] as Timestamp).toDate() 
          : DateTime.now(),
      createdBy: data['createdBy'] ?? '',
      electionCommissionNotification: data['electionCommissionNotification'],
      reservedSeats: data['reservedSeats'] != null 
          ? Map<String, int>.from(data['reservedSeats']) 
          : null,
      womenReservation: data['womenReservation'],
      totalElectors: data['totalElectors'],
      estimatedTurnout: data['estimatedTurnout'],
      conductingAuthority: data['conductingAuthority'],
      municipalityType: data['municipalityType'],
      district: data['district'] ?? 'AHM', // Default to Ahmedabad
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'electionId': electionId,
      'title': title,
      'description': description,
      'electionType': electionType,
      'totalWards': totalWards,
      'notificationDate': notificationDate != null 
          ? Timestamp.fromDate(notificationDate!) 
          : null,
      'nominationStartDate': nominationStartDate != null 
          ? Timestamp.fromDate(nominationStartDate!) 
          : null,
      'nominationEndDate': nominationEndDate != null 
          ? Timestamp.fromDate(nominationEndDate!) 
          : null,
      'scrutinyDate': scrutinyDate != null 
          ? Timestamp.fromDate(scrutinyDate!) 
          : null,
      'withdrawalDate': withdrawalDate != null 
          ? Timestamp.fromDate(withdrawalDate!) 
          : null,
      'campaignStartDate': campaignStartDate != null 
          ? Timestamp.fromDate(campaignStartDate!) 
          : null,
      'campaignEndDate': campaignEndDate != null 
          ? Timestamp.fromDate(campaignEndDate!) 
          : null,
      'pollingDate': Timestamp.fromDate(pollingDate),
      'resultDate': resultDate != null 
          ? Timestamp.fromDate(resultDate!) 
          : null,
      'status': status,
      'contractAddress': contractAddress,
      'createdAt': Timestamp.fromDate(createdAt),
      'createdBy': createdBy,
      'electionCommissionNotification': electionCommissionNotification,
      'reservedSeats': reservedSeats,
      'womenReservation': womenReservation,
      'totalElectors': totalElectors,
      'estimatedTurnout': estimatedTurnout,
      'conductingAuthority': conductingAuthority,
      'municipalityType': municipalityType,
      'district': district,
    };
  }

  // Helper method to generate election ID
  static String generateElectionCode(String district, String type, int year) {
    return 'GUJ_${district.toUpperCase()}_${type.toUpperCase()}_$year';
  }

  // Helper method to validate election code
  static bool isValidElectionCode(String code) {
    final pattern = RegExp(r'^GUJ_[A-Z]{3,4}_[A-Z]{2,3}_\d{4}$');
    return pattern.hasMatch(code);
  }
}
