import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/widgets.dart';
import '../models/candidate.dart';
import '../models/vote.dart';
import '../models/voter_profile.dart';
import '../models/election.dart';
import 'blockchain_service.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final  _blockchainService = BlockchainService();



Future<Map<String, dynamic>> getHostCredentials() async {
  final doc = await FirebaseFirestore.instance
      .collection('hostCredentials')
      .doc('host')
      .get();

  if (!doc.exists) {
    throw Exception("Host credentials not found");
  }

  return doc.data()!;
}

Stream<Map<String, dynamic>> getHostCredentialsStream() {
  return _db.collection('hostCredentials')
      .doc('host')
      .snapshots()
      .map((doc) {
    if (!doc.exists) {
      throw Exception("Host credentials not found");
    }
    return doc.data() ?? {};
  });
}


Stream<int> streamTotalElections() {
  return _db.collection('elections')
      .snapshots()
      .map((snap) => snap.size);
}

Stream<int> streamActiveElections() {
  return _db.collection('elections')
      .where('status', isEqualTo: 'active')
      .snapshots()
      .map((snap) => snap.size);
}

Stream<int> streamTotalVoters() {
  return _db.collection('voters')
      .snapshots()
      .map((snap) => snap.size);
}

Stream<int> streamTotalVotes() {
  return _db.collection('votes')
      .snapshots()
      .map((snap) => snap.size);
}


//in use!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
  Future<List<Election>> getElections() async {
   debugPrint('\x1B[32m'
    'lib/services/firestore_service.dart: getElections() executed'
    '\x1B[0m');
    final snap = await _db.collection('elections').get();
    return snap.docs.map((d) => Election.fromFirestore(d)).toList();
  }
//in use
  Stream<List<Election>> getElectionsStream() {
   debugPrint('\x1B[32m'
    'lib/services/firestore_service.dart: getElectionsStream() executed'
    '\x1B[0m');
    return _db.collection('elections').snapshots().map(
            (s) => s.docs.map((d) => Election.fromFirestore(d)).toList());
  }
//in use
  Future<List<Election>> getActiveElections() async {
   debugPrint('\x1B[32m'
    'lib/services/firestore_service.dart: getActiveElections() executed'
    '\x1B[0m');
    
    final snap = await _db
        .collection('elections')
        .where('status', isEqualTo: 'active')
        .get();
    return snap.docs.map((d) => Election.fromFirestore(d)).toList();
  }
//in use
  Future<List<Election>> getUpcomingElections() async {
   debugPrint('\x1B[32m'
    'lib/services/firestore_service.dart: getUpcomingElections() executed'
    '\x1B[0m');
    final snap = await _db
        .collection('elections')
        .where('status', isEqualTo: 'upcoming')
        .get();
    return snap.docs.map((d) => Election.fromFirestore(d)).toList();
  }
//in use
  Future<Election> getElectionById(String id) async {
   debugPrint('\x1B[32m'
    'lib/services/firestore_service.dart: getElectionById() executed'
    '\x1B[0m');
    final doc = await _db.collection('elections').doc(id).get();
    return Election.fromFirestore(doc);
  }
//in use
  Future<void> createElection(Election election) async {
   debugPrint('\x1B[32m'
    'lib/services/firestore_service.dart: createElection() executed'
    '\x1B[0m');

    debugPrint("Creating election in BOTH systems...");

    // 1. Firebase
    final docRef = await _db.collection('elections').add(election.toMap());


    await docRef.update({
      "contractAddress": _blockchainService.contractAddress
    });


  final electionId = docRef.id;

     debugPrint('\x1B[31m'
    'lib/services/firestore_service.dart: createElection(): electionID: ${electionId}'
    '\x1B[0m');


  // 2. Blockchain
  await _blockchainService.createElectionOnBlockchain(electionId);


 debugPrint("✅ Synced Firebase + Blockchain");


}
//in use
  Future<void> updateElection(Election election) async {
   debugPrint('\x1B[32m'
    'lib/services/firestore_service.dart: updateElection() executed'
    '\x1B[0m');
    await _db.collection('elections').doc(election.id).update(election.toMap());
  }
//in use
  Future<void> deleteElection(String id) async {
   debugPrint('\x1B[32m'
    'lib/services/firestore_service.dart: deleteElection() executed'
    '\x1B[0m');
    await _db.collection('elections').doc(id).delete();
  }
//in use
  Future<List<Candidate>> getCandidates(String electionId) async {
   debugPrint('\x1B[32m'
    'lib/services/firestore_service.dart: getCandidates() executed'
    '\x1B[0m');
    final snap = await _db
        .collection('candidates')
        .where('electionId', isEqualTo: electionId)
        .get();
    return snap.docs.map((d) => Candidate.fromFirestore(d, electionId)).toList();
  }
//in use
  Stream<List<Candidate>> getCandidatesStream(String electionId) {
   debugPrint('\x1B[32m'
    'lib/services/firestore_service.dart: getCandidatesStream() executed'
    '\x1B[0m');
    return _db
        .collection('candidates')
        .where('electionId', isEqualTo: electionId)
        .snapshots()
        .map((s) => s.docs.map((d) => Candidate.fromFirestore(d, electionId)).toList());
  }
//in use
  Future<void> updateCandidate(String id, Map<String, dynamic> data) async {
   debugPrint('\x1B[32m'
    'lib/services/firestore_service.dart: updateCandidate() executed'
    '\x1B[0m');
    await _db.collection('candidates').doc(id).update(data);
  }
//in use
  Future<void> addCandidate(String electionId, Map<String, dynamic> data) async {
   debugPrint('\x1B[32m'
    'lib/services/firestore_service.dart: addCandidate() executed'
    '\x1B[0m');
    await _db.collection('candidates').add({
      ...data,
      'electionId': electionId,
    });
  }
//in use
  Future<void> deleteCandidate(String id) async {
   debugPrint('\x1B[32m'
    'lib/services/firestore_service.dart: deleteCandidate() executed'
    '\x1B[0m');
    await _db.collection('candidates').doc(id).delete();
  }
//in use
  Future<bool> hasVoted(String voterId, String electionId) async {

   debugPrint('\x1B[32m'
    'lib/services/firestore_service.dart: hasVoted() executed'
    '\x1B[0m');


    final snap = await _db
        .collection('votes')
        .where('voterUid', isEqualTo: voterId)
        .where('electionId', isEqualTo: electionId)
        .get();

    return snap.docs.isNotEmpty;

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


//in use
  Future<void> recordVote(Vote vote) async {
   debugPrint('\x1B[32m'
    'lib/services/firestore_service.dart: recordVote() executed'
    '\x1B[0m');
    await _db.collection('votes').add(vote.toMap());

    await _db.collection('candidates').doc(vote.candidateId).update({
      'voteCount': FieldValue.increment(1),
    });
  }
//in use
  Future<List<Vote>> getVotingHistory(String userId) async {

   debugPrint('\x1B[32m'
    'lib/services/firestore_service.dart: getVotingHistory() executed'
    '\x1B[0m');

    final snap = await _db
        .collection('votes')
        .where('voterUid', isEqualTo: userId)
        .get();

    // final snap = await _db.collection('votes').get();
    // print("Total docs: ${snap.docs.length}");
        print('\x1b[36m'"lib/services/firestore_service.dart: getVotingHistory(): User ID: ${userId}"'\x1b[0m');


    return snap.docs.map((d) => Vote.fromFirestore(d)).toList();
  }
//in use
  Future<void> updateVoterEligibility(String id, bool isEligible) async {
   debugPrint('\x1B[32m'
    'lib/services/firestore_service.dart: updateVoterEligibility() executed'
    '\x1B[0m');
    await _db.collection('users').doc(id).update({
      'isEligible': isEligible,
    });
  }
//in use
  Stream<List<VoterProfile>> getAllVotersStream() {
   debugPrint('\x1B[32m'
    'lib/services/firestore_service.dart: getAllVotersStream() executed'
    '\x1B[0m');
    return _db.collection('users').snapshots().map(
            (s) => s.docs.map((d) => VoterProfile.fromFirestore(d)).toList());
  }
//in use
  Stream<Map<String, int>> getElectionResultsStream(String electionId) {
   debugPrint('\x1B[32m'
    'lib/services/firestore_service.dart: getElectionResultsStream() executed'
    '\x1B[0m');
    return _db
        .collection('votes')
        .where('electionId', isEqualTo: electionId)
        .snapshots()
        .map((snapshot) {
      final Map<String, int> results = {};
      try{
        for (var doc in snapshot.docs) {
        final data = doc.data();
        final candidateId = data['candidateId'] as String? ?? '';
        if (candidateId.isNotEmpty) {
          results[candidateId] = (results[candidateId] ?? 0) + 1;
        }
      }
      }catch(err){
        print(err);
      }
      return results;
    });
  }
//in use need debug call
  Future<int> getTotalElections() async =>
      (await _db.collection('elections').get()).size;
//in use need debug call
  Future<int> getActiveElectionsCount() async =>
      (await _db
          .collection('elections')
          .where('status', isEqualTo: 'active')
          .get())
          .size;
//in use need debug call
  Future<int> getTotalVoters() async =>
      (await _db.collection('voters').get()).size;
//in use need debug call
  Future<int> getTotalVotes() async =>
      (await _db.collection('votes').get()).size;
}
