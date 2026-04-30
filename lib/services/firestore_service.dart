import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/widgets.dart';
import '../models/candidate.dart';
import '../models/vote.dart';
import '../models/app_user.dart';
import '../models/election.dart';
import '../models/party.dart';
import 'blockchain_service.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final _blockchainService = BlockchainService();

  Future<Map<String, dynamic>> getHostCredentials() async {
    final doc = await _db.collection('hostCredentials').doc('host').get();
    if (!doc.exists) throw Exception("Host credentials not found");
    return doc.data()!;
  }

    Future<bool> isAlreadyRegisteredVoterId(String voterId) async{

    debugPrint('\x1B[32m'
    'lib/services/firestore_service.dart: alreadyRegisteredVoterId() executed'
    '\x1B[0m');
    
    final snap = await _db
        .collection('users')
        .where('voterId', isEqualTo: voterId)
        .get();

    debugPrint('\x1B[36m'
    'lib/services/firestore_service.dart: alreadyRegisteredVoterId(): snap: ${snap.docs.isNotEmpty}'
    '\x1B[0m');

    return snap.docs.isNotEmpty;

  }

  Future<bool> isAlreadyRegisteredAadhaar(String aadhaar) async{

    debugPrint('\x1B[32m'
    'lib/services/firestore_service.dart: isAlreadyRegisteredAadhaar() executed'
    '\x1B[0m');
    
    final snap = await _db
        .collection('users')
        .where('aadhaar', isEqualTo: aadhaar)
        .get();

    debugPrint('\x1B[36m'
    'lib/services/firestore_service.dart: isAlreadyRegisteredAadhaar(): snap: ${snap.docs.isNotEmpty}'
    '\x1B[0m');

    return snap.docs.isNotEmpty;

  }

  Future<bool> isAlreadyRegisteredEmail(String email) async{

    debugPrint('\x1B[32m'
    'lib/services/firestore_service.dart: isAlreadyRegisteredEmail() executed'
    '\x1B[0m');
    
    final snap = await _db
        .collection('users')
        .where('email', isEqualTo: email)
        .get();

    debugPrint('\x1B[36m'
    'lib/services/firestore_service.dart: isAlreadyRegisteredEmail(): snap: ${snap.docs.isNotEmpty}'
    '\x1B[0m');

    return snap.docs.isNotEmpty;

  }


  Stream<Map<String, dynamic>> getHostCredentialsStream() {
    return _db.collection('hostCredentials').doc('host').snapshots().map((doc) => doc.data() ?? {});
  }

  Stream<int> streamTotalElections() => _db.collection('elections').snapshots().map((snap) => snap.size);
  Stream<int> streamActiveElections() => _db.collection('elections').where('status', isEqualTo: 'active').snapshots().map((snap) => snap.size);
  Stream<int> streamTotalVoters() => _db.collection('users').snapshots().map((snap) => snap.size);
  Stream<int> streamTotalVotes() => _db.collection('votes').snapshots().map((snap) => snap.size);

  Future<List<Election>> getElections() async {
    final snap = await _db.collection('elections').get();
    return snap.docs.map((d) => Election.fromFirestore(d)).toList();
  }

  Stream<List<Election>> getElectionsStream() {
    return _db.collection('elections').snapshots().map(
        (s) => s.docs.map((d) => Election.fromFirestore(d)).toList());
  }

  Future<Election?> getElectionById(String id) async {
    final doc = await _db.collection('elections').doc(id).get();
    if (!doc.exists) return null;
    return Election.fromFirestore(doc);
  }

  Future<void> createElection(Election election) async {
    try {
      await _db.collection('elections').doc(election.electionId).set(election.toMap());
      await _blockchainService.createElectionOnBlockchain(election.electionId);
    } catch (err) {
      debugPrint('Error creating election: $err');
      rethrow;
    }
  }

  Future<void> updateElection(Election election) async {
    await _db.collection('elections').doc(election.electionId).update(election.toMap());
  }

  Future<void> deleteElection(String id) async {
    await _db.collection('elections').doc(id).delete();
  }

  // Candidates
  Stream<List<Candidate>> getCandidatesStream(String electionId) {
    return _db.collection('candidates')
        .where('electionId', isEqualTo: electionId)
        .snapshots()
        .map((s) => s.docs.map((d) => Candidate.fromFirestore(d, electionId)).toList());
  }

  Future<List<Candidate>> getCandidates(String electionId) async {
    final snap = await _db.collection('candidates')
        .where('electionId', isEqualTo: electionId)
        .get();
    return snap.docs.map((d) => Candidate.fromFirestore(d, electionId)).toList();
  }

  Future<void> addCandidate(String electionId, Map<String, dynamic> data) async {
    await _db.collection('candidates').add({
      ...data,
      'electionId': electionId,
      'createdDate': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateCandidate(String id, Map<String, dynamic> data) async {
    await _db.collection('candidates').doc(id).update(data);
  }

  Future<void> deleteCandidate(String id) async {
    await _db.collection('candidates').doc(id).delete();
  }

  Future<List<Candidate>> getCandidatesByWard(String electionId, String ward) async {
    final snap = await _db.collection('candidates')
        .where('electionId', isEqualTo: electionId)
        .where('ward', isEqualTo: ward)
        .where('nomineeStatus', isEqualTo: 'Eligible')
        .get();
    return snap.docs.map((d) => Candidate.fromFirestore(d, electionId)).toList();
  }

  Stream<Map<String, int>> getElectionResultsStream(String electionId) {
    return _db.collection('candidates')
        .where('electionId', isEqualTo: electionId)
        .snapshots()
        .map((snapshot) {
          final results = <String, int>{};
          for (var doc in snapshot.docs) {
            results[doc.id] = (doc.data()['voteCount'] ?? 0) as int;
          }
          return results;
        });
  }

  // Voter Verification
  Stream<List<AppUser>> getAllVotersStream() {
    return _db.collection('users')
        .where('role', isEqualTo: 'voter')
        .snapshots()
        .map((s) => s.docs.map((d) => AppUser.fromMap(d.id, d.data())).toList());
  }

  Future<void> updateVoterVerification(String uid, String status, String adminId) async {
    await _db.collection('users').doc(uid).update({
      'verificationStatus': status,
      'verificationDate': FieldValue.serverTimestamp(),
      'verifiedBy': adminId,
      'isEligible': status == 'Verified',
    });
  }

  // Parties
  Stream<List<Party>> getPartiesStream() {
    return _db.collection('parties').snapshots().map(
        (s) => s.docs.map((d) => Party.fromFirestore(d)).toList());
  }

  Future<List<Party>> getParties() async {
    final snap = await _db.collection('parties').get();
    return snap.docs.map((d) => Party.fromFirestore(d)).toList();
  }

  Future<void> createParty(Party party) async {
    await _db.collection('parties').doc(party.partyId).set(party.toMap());
  }

  Future<void> updateParty(String id, Map<String, dynamic> data) async {
    await _db.collection('parties').doc(id).update(data);
  }

  Future<void> deleteParty(String id) async {
    await _db.collection('parties').doc(id).delete();
  }

  // Voting
  Future<bool> hasVoted(String voterId, String electionId) async {
    final snap = await _db.collection('votes')
        .where('voterUid', isEqualTo: voterId) 
        .where('electionId', isEqualTo: electionId)
        .get();
    return snap.docs.isNotEmpty;
  }

  Future<void> recordVote(Vote vote) async {
    await _db.collection('votes').add(vote.toMap());
    await _db.collection('candidates').doc(vote.candidateId).update({
      'voteCount': FieldValue.increment(1),
    });
  }

  Future<List<Vote>> getVotingHistory(String voterId) async {
    final snap = await _db.collection('votes')
        .where('voterUid', isEqualTo: voterId)
        .get();
    return snap.docs.map((d) => Vote.fromFirestore(d)).toList();
  }

  Future<void> markCandidateEligible(String id, bool eligible, {String? reason}) async {
    await _db.collection('candidates').doc(id).update({
      'nomineeStatus': eligible ? 'Eligible' : 'Ineligible',
      'nominationFormStatus': eligible ? 'Accepted' : 'Rejected',
      if (reason != null) 'disqualificationReason': reason,
      'status': eligible ? 'Active' : 'Inactive',
    });
  }
}
