import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/party.dart';

class PartyService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Get all parties
  Future<List<Party>> getParties() async {
    final snap = await _db.collection('parties').get();
    return snap.docs.map((d) => Party.fromFirestore(d)).toList();
  }

  // Get parties stream
  Stream<List<Party>> getPartiesStream() {
    return _db.collection('parties').snapshots().map(
            (s) => s.docs.map((d) => Party.fromFirestore(d)).toList());
  }

  // Get active parties
  Future<List<Party>> getActiveParties() async {
    final snap = await _db.collection('parties')
        .where('status', isEqualTo: 'Active')
        .get();
    return snap.docs.map((d) => Party.fromFirestore(d)).toList();
  }

  // Get party by ID
  Future<Party?> getPartyById(String partyId) async {
    final doc = await _db.collection('parties').doc(partyId).get();
    if (doc.exists) {
      return Party.fromFirestore(doc);
    }
    return null;
  }

  // Create party
  Future<void> createParty(Party party) async {
    await _db.collection('parties').doc(party.partyId).set(party.toMap());
  }

  // Update party
  Future<void> updateParty(String partyId, Map<String, dynamic> data) async {
    await _db.collection('parties').doc(partyId).update({
      ...data,
      'updatedDate': Timestamp.fromDate(DateTime.now()),
    });
  }

  // Delete party
  Future<void> deleteParty(String partyId) async {
    await _db.collection('parties').doc(partyId).delete();
  }

  // Activate/Deactivate party
  Future<void> togglePartyStatus(String partyId, bool isActive) async {
    await _db.collection('parties').doc(partyId).update({
      'status': isActive ? 'Active' : 'Inactive',
      'updatedDate': Timestamp.fromDate(DateTime.now()),
    });
  }

  // Get national parties
  Future<List<Party>> getNationalParties() async {
    final snap = await _db.collection('parties')
        .where('isNationalParty', isEqualTo: true)
        .get();
    return snap.docs.map((d) => Party.fromFirestore(d)).toList();
  }

  // Get state parties
  Future<List<Party>> getStateParties() async {
    final snap = await _db.collection('parties')
        .where('isStateParty', isEqualTo: true)
        .get();
    return snap.docs.map((d) => Party.fromFirestore(d)).toList();
  }

  // Update party vote counts
  Future<void> updatePartyVotes(String partyId, int votes, double percentage) async {
    await _db.collection('parties').doc(partyId).update({
      'totalVotes': votes,
      'votePercentage': percentage,
    });
  }

  // Update party candidate count
  Future<void> updatePartyCandidateCount(String partyId, int count) async {
    await _db.collection('parties').doc(partyId).update({
      'totalCandidates': count,
    });
  }

  // Search parties by name
  Future<List<Party>> searchParties(String query) async {
    final snap = await _db.collection('parties')
        .where('partyName', isGreaterThanOrEqualTo: query)
        .where('partyName', isLessThanOrEqualTo: query + '\uf8ff')
        .get();
    return snap.docs.map((d) => Party.fromFirestore(d)).toList();
  }
}