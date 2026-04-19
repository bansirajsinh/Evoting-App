import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../services/firestore_service.dart';
import '../services/blockchain_service.dart';
import '../models/election.dart';
import '../models/candidate.dart';


class ResultsPage extends StatefulWidget {
  const ResultsPage({super.key});

  @override
  State<ResultsPage> createState() => _ResultsPageState();
}

class _ResultsPageState extends State<ResultsPage> {
  final _firestoreService = FirestoreService();
  final _blockchainService = BlockchainService();

  String? _selectedElectionId;

  @override
  void initState() {
    super.initState();
    debug();
  }

  Future<void> _verifyBlockchain() async {
    debugPrint('\x1B[32m'
    'lib/admin/result.dart: _verifyBlockchain() executed'
    '\x1B[0m');
    if (_selectedElectionId  == null) return;

    final isValid = await _blockchainService.validateBlockchainIntegrity(_selectedElectionId!);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(isValid
            ? 'Verification Passed'
            : 'Verification Warning'),
        content: Text(isValid
            ? 'All votes verified successfully.'
            : 'Some votes could not be verified.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildResultCard(
      Candidate candidate,
      int votes,
      int totalVotes,{
        bool isWinner = false,
    }) {
    final percentage =
    totalVotes == 0 ? 0 : (votes / totalVotes) * 100;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(AppDimens.borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Text(
                      candidate.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),

                    // 🏆 WINNER ICON HERE
                    if (isWinner) ...[
                      const SizedBox(width: 6),
                      const Icon(
                        Icons.emoji_events,
                        color: Colors.amber,
                        size: 20,
                      ),
                    ],
                  ],
                ),
              ),
              Text(
                '$votes votes',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: percentage / 100,
            minHeight: 8,
            backgroundColor: AppColors.divider,
            valueColor:
            const AlwaysStoppedAnimation(AppColors.primary),
          ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '${percentage.toStringAsFixed(1)}%',
              style: AppTextStyles.caption,
            ),
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
        backgroundColor: AppColors.primaryDark,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.verified_user),
            onPressed: _verifyBlockchain,
          ),
        ],
      ),

      body: StreamBuilder<List<Election>>(

        stream: _firestoreService.getElectionsStream(),
        builder: (context, electionSnapshot) {

          if (electionSnapshot.hasError) {

            print('\x1B[31m''Error loading elections; getElectionsStream failed: ${electionSnapshot.error}''\x1B[0m');

            return const Center(
              child: Text('Error loading elections'),
            );
          }

          if (electionSnapshot.connectionState == ConnectionState.waiting) {

            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (!electionSnapshot.hasData || electionSnapshot.data!.isEmpty) {

            print('\x1B[31m''No elections found; hasData''\x1B[0m');

            return const Center(
              child: Text('No elections found'),
            );
          }

          final elections = electionSnapshot.data!;

          if (elections.isEmpty) {

            print('\x1B[31m''No elections found; elections list is empty; elections.isEmpty''\x1B[0m');

            return const Center(
                child: Text('No elections found'));
          }

            if (_selectedElectionId == null && elections.isNotEmpty) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                setState(() {
                  _selectedElectionId = elections.first.id;
                });
              });
            }

            if (_selectedElectionId == null) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(
                    AppDimens.paddingMedium),
                child: DropdownButtonFormField<String>(
                  hint: const Text("Select Election"),
                  value: elections.any((e) => e.id == _selectedElectionId)
                      ? _selectedElectionId
                      : null,
                  items: elections
                      .map((e) => DropdownMenuItem<String>(
                            value: e.id,
                            child: Text(e.title),
                          ))
                      .toList(),
                  onChanged: (id) {
                    setState(() {
                      _selectedElectionId = id;
                    });
                  },
                )
              ),

              Expanded(
                child: StreamBuilder<List<Candidate>>(
                  stream: _firestoreService.getCandidatesStream(_selectedElectionId!),
                  builder:
                      (context, candidateSnapshot) {
                    if (candidateSnapshot.hasError) {
                      return const Center(
                        child: Text('Error loading candidates'),
                      );
                    }

                    if (candidateSnapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }

                    if (!candidateSnapshot.hasData || candidateSnapshot.data!.isEmpty) {
                      return const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.people_outline, size: 60),
                            SizedBox(height: 10),
                            Text('No candidates found'),
                          ],
                        ),
                      );
                    }

                    final candidates =
                    candidateSnapshot.data!;

                    return StreamBuilder<
                        Map<String, int>>(
                      stream: _firestoreService.getElectionResultsStream(_selectedElectionId!),
                      builder:
                          (context, resultSnapshot) {
                        if (resultSnapshot.hasError) {
                          return const Center(
                            child: Text('Error loading results'),
                          );
                        }

                        if (resultSnapshot.connectionState == ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        if (!resultSnapshot.hasData) {
                          return const Center(
                            child: Text('No results available'),
                          );
                        }

                        final results =
                        resultSnapshot.data!;
                        int totalVotes = results
                            .values
                            .fold(0, (a, b) => a + b);

                        final sortedCandidates =
                        [...candidates];

                        sortedCandidates.sort(
                                (a, b) =>
                                (results[b.id] ?? 0)
                                    .compareTo(
                                    results[a.id] ??
                                        0));

                        if (sortedCandidates
                            .isEmpty) {
                          return const Center(
                              child: Text(
                                  'No candidates found'));
                        }

                        return ListView.builder(
                          
                          padding:
                          const EdgeInsets.all(
                              AppDimens
                                  .paddingMedium),
                          itemCount:
                          sortedCandidates.length,
                          itemBuilder:
                              (context, index) {
                                final isWinner = index == 0;
                            final candidate =
                            sortedCandidates[
                            index];
                            final votes =
                                results[candidate
                                    .id] ??
                                    0;

                            return _buildResultCard(
                                candidate,
                                votes,
                                totalVotes,
                                isWinner: isWinner
                              );
                                
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

  void debug() {
    debugPrint('\x1B[34m'
        'lib/admin/result.dart: executed'
        '\x1B[0m');
  }
}
