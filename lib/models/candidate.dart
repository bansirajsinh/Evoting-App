import 'package:cloud_firestore/cloud_firestore.dart';

class Candidate {
  final String id;
  final String name;
  final String party;
  final String symbol;
  final String electionId;
  final String constituency;
  final String? manifesto;
  final int votes;

  Candidate({
    required this.id,
    required this.name,
    required this.party,
    required this.symbol,
    required this.electionId,
    required this.constituency,
    this.manifesto,
    required this.votes,
  });

  // FIX: Made electionId optional parameter since it's also stored in the document data.
  // This way it works both when called with 1 arg (from streams) and 2 args.
  factory Candidate.fromFirestore(DocumentSnapshot doc, [String? electionId]) {
    final data = doc.data() as Map<String, dynamic>;

    return Candidate(
      id: doc.id,
      name: data['name'] ?? '',
      party: data['party'] ?? '',
      symbol: data['symbol'] ?? '',
      electionId: electionId ?? data['electionId'] ?? '',
      constituency: data['constituency'] ?? 'General',
      manifesto: data['manifesto'],
      // FIX: Firebase uses 'voteCount', not 'votes' — handle both
      votes: (data['voteCount'] ?? data['votes'] ?? 0) as int,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'party': party,
      'symbol': symbol,
      'electionId': electionId,
      'constituency': constituency,
      'manifesto': manifesto,
      'voteCount': votes,
    };
  }
}
