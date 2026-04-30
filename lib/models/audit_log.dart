import 'package:cloud_firestore/cloud_firestore.dart';

class AuditLog {
  final String id;
  final DateTime timestamp;
  final String adminName;
  final String adminId;
  final String actionType; // Created/Edited/Deleted/Verified/Blocked
  final String resourceType; // Election/Candidate/Voter/Party
  final String resourceId;
  final String resourceName;
  final dynamic oldValue;
  final dynamic newValue;
  final String? ipAddress;
  final String status; // Success/Failed
  final String? reason;

  AuditLog({
    required this.id,
    required this.timestamp,
    required this.adminName,
    required this.adminId,
    required this.actionType,
    required this.resourceType,
    required this.resourceId,
    required this.resourceName,
    this.oldValue,
    this.newValue,
    this.ipAddress,
    required this.status,
    this.reason,
  });

  factory AuditLog.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AuditLog(
      id: doc.id,
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      adminName: data['adminName'] ?? '',
      adminId: data['adminId'] ?? '',
      actionType: data['actionType'] ?? '',
      resourceType: data['resourceType'] ?? '',
      resourceId: data['resourceId'] ?? '',
      resourceName: data['resourceName'] ?? '',
      oldValue: data['oldValue'],
      newValue: data['newValue'],
      ipAddress: data['ipAddress'],
      status: data['status'] ?? 'Success',
      reason: data['reason'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'timestamp': Timestamp.fromDate(timestamp),
      'adminName': adminName,
      'adminId': adminId,
      'actionType': actionType,
      'resourceType': resourceType,
      'resourceId': resourceId,
      'resourceName': resourceName,
      'oldValue': oldValue,
      'newValue': newValue,
      'ipAddress': ipAddress,
      'status': status,
      'reason': reason,
    };
  }
}
