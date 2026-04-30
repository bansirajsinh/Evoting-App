import 'package:cloud_firestore/cloud_firestore.dart';

class Vote {
  final String id;
  final String voterId;
  final String electionId;
  final String candidateId;
  final String? voterHash;
  final String? voteHash;
  final String? transactionHash;
  final DateTime timestamp;

  // 🔗 Blockchain fields
  final String? blockHash;
  final String? previousBlockHash;
  final int? blockNumber;
  final String? accountAddress;

  Vote({
    required this.id,
    required this.voterId,
    required this.electionId,
    required this.candidateId,
    required this.voterHash,
    required this.voteHash,
    required this.transactionHash,
    required this.timestamp,
    required this.blockHash,
    required this.previousBlockHash,
    required this.blockNumber,
    required this.accountAddress,
  });

  factory Vote.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return Vote(
      id: doc.id,
      voterId: data['voterUid'] ?? data['voterId'] ?? '',
      electionId: data['electionId'] ?? '',
      candidateId: data['candidateId'] ?? '',
      voterHash: data['voterHash'],
      voteHash: data['voteHash'],
      transactionHash: data['transactionHash'],
      timestamp: data['timestamp'] != null ? (data['timestamp'] as Timestamp).toDate() : DateTime.now(),
      blockHash: data['blockHash'],
      previousBlockHash: data['previousBlockHash'],
      blockNumber: data['blockNumber'],
      accountAddress: data['accountAddress'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      
      'voterUid': voterId,
      'electionId': electionId,
      'candidateId': candidateId,
      'voterHash': voterHash,
      'voteHash': voteHash,
      'transactionHash': transactionHash,
      'timestamp': Timestamp.fromDate(timestamp),
      'blockHash': blockHash,
      'previousBlockHash': previousBlockHash,
      'blockNumber': blockNumber,
      'accountAddress': accountAddress,
    };
  }
}
