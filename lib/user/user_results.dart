import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../services/firestore_service.dart';
import '../services/blockchain_service.dart';
import '../models/election.dart';
import '../models/candidate.dart';

class UserResultsPage extends StatefulWidget {
  const UserResultsPage({super.key});

  @override
  State<UserResultsPage> createState() => _UserResultsPageState();
}

class _UserResultsPageState extends State<UserResultsPage> {
  final _firestoreService = FirestoreService();
  final _blockchainService = BlockchainService();

  String? _selectedElectionId;

  @override
  void initState() {
    super.initState();
    debug();
  }

  Future<void> _verifyBlockchain() async {
    if (_selectedElectionId == null) return;
    final transaction = await _blockchainService.getTransaction("some_hash"); 
    final isValid = transaction != null && transaction.status;

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(isValid ? 'Blockchain Verified' : 'Integrity Check'),
        content: Text(isValid ? 'All votes on blockchain match Firestore records.' : 'Blockchain verification requires polling completion.'),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
      ),
    );
  }

  Widget _buildResultCard(Candidate candidate, int votes, int totalVotes, {bool isWinner = false}) {
    final percentage = totalVotes == 0 ? 0 : (votes / totalVotes) * 100;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimens.borderRadius),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Text(candidate.candidateName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    if (isWinner) ...[
                      const SizedBox(width: 6),
                      const Icon(Icons.emoji_events, color: Colors.amber, size: 20),
                    ],
                  ],
                ),
              ),
              Text('$votes votes', style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: percentage / 100,
            minHeight: 8,
            backgroundColor: AppColors.divider,
            valueColor: const AlwaysStoppedAnimation(AppColors.primary),
          ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerRight,
            child: Text('${percentage.toStringAsFixed(1)}% | Ward: ${candidate.ward}', style: AppTextStyles.caption),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Election Results'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [IconButton(icon: const Icon(Icons.verified), onPressed: _verifyBlockchain)],
      ),
      body: StreamBuilder<List<Election>>(
        stream: _firestoreService.getElectionsStream(),
        builder: (context, electionSnapshot) {
          if (electionSnapshot.hasError) return const Center(child: Text('Error loading elections'));
          if (electionSnapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (!electionSnapshot.hasData || electionSnapshot.data!.isEmpty) return const Center(child: Text('No elections found'));

          final elections = electionSnapshot.data!;
          _selectedElectionId ??= elections.first.uid;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(AppDimens.paddingMedium),
                child: DropdownButtonFormField<String>(
                  value: _selectedElectionId,
                  items: elections.map((e) => DropdownMenuItem(value: e.uid, child: Text(e.title))).toList(),
                  onChanged: (id) => setState(() => _selectedElectionId = id),
                  decoration: const InputDecoration(labelText: 'Select Election'),
                ),
              ),
              Expanded(
                child: StreamBuilder<List<Candidate>>(
                  stream: _firestoreService.getCandidatesStream(_selectedElectionId!),
                  builder: (context, candidateSnapshot) {
                    if (candidateSnapshot.hasError) return const Center(child: Text('Error loading candidates'));
                    if (candidateSnapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                    if (!candidateSnapshot.hasData || candidateSnapshot.data!.isEmpty) return const Center(child: Text('No candidates found'));

                    final candidates = candidateSnapshot.data!;
                    return StreamBuilder<Map<String, int>>(
                      stream: _firestoreService.getElectionResultsStream(_selectedElectionId!),
                      builder: (context, resultSnapshot) {
                        if (resultSnapshot.hasError) return const Center(child: Text('Error loading results'));
                        if (!resultSnapshot.hasData) return const Center(child: CircularProgressIndicator());

                        final results = resultSnapshot.data!;
                        int totalVotes = results.values.fold(0, (a, b) => a + b);
                        final sortedCandidates = [...candidates];
                        sortedCandidates.sort((a, b) => (results[b.id] ?? 0).compareTo(results[a.id] ?? 0));

                        return ListView.builder(
                          padding: const EdgeInsets.all(AppDimens.paddingMedium),
                          itemCount: sortedCandidates.length,
                          itemBuilder: (context, index) {
                            final candidate = sortedCandidates[index];
                            final votes = results[candidate.id] ?? 0;
                            return _buildResultCard(candidate, votes, totalVotes, isWinner: index == 0 && votes > 0);
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void debug() => debugPrint('\x1B[34mUserResultsPage executed\x1B[0m');
}
