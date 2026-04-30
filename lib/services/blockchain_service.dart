import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:uuid/uuid.dart';
import 'package:web3dart/web3dart.dart';
import 'package:http/http.dart';
import 'package:flutter/services.dart';
import 'firestore_service.dart';

class BlockchainTransaction {
  final String transactionHash;
  final String blockHash;
  final int blockNumber;
  final String from;
  final String to;
  final String data;
  final DateTime timestamp;
  final bool status;

  BlockchainTransaction({
    required this.transactionHash,
    required this.blockHash,
    required this.blockNumber,
    required this.from,
    required this.to,
    required this.data,
    required this.timestamp,
    required this.status,
  });

  Map<String, dynamic> toMap() {
    return {
      'transactionHash': transactionHash,
      'blockHash': blockHash,
      'blockNumber': blockNumber,
      'from': from,
      'to': to,
      'data': data,
      'timestamp': timestamp.toIso8601String(),
      'status': status,
    };
  }
}

class BlockchainService {
  static final BlockchainService _instance =
      BlockchainService._internal();

  factory BlockchainService() => _instance;
  late Web3Client client;
  late EthPrivateKey credentials;
  DeployedContract? contract;

  final String _defaultRpcUrl = "http://10.137.177.71:7545";
  final String _defaultPrivateKey =
      "0x032063a0fa88f352441840f26a74397f3906de147b0008fc322375c12656e5dc";
  final String _defaultContractAddress =
      "0x4cC35bE54c358146E7b71E58f965532193848FDd";

  late String _rpcUrl;
  late String _privateKey;
  late String _contractAddress;

  FirestoreService? _firestoreService;
  FirestoreService get firestoreService => _firestoreService ??= FirestoreService();

  String get rpcUrl => _rpcUrl;
  String get privateKey => _privateKey;
  String get contractAddress => _contractAddress;

  BlockchainService._internal() {
    _rpcUrl = _defaultRpcUrl;
    _privateKey = _defaultPrivateKey;
    _contractAddress = _defaultContractAddress;
    client = Web3Client(_rpcUrl, Client());
    credentials = EthPrivateKey.fromHex(_privateKey);
  }

  final Uuid _uuid = const Uuid();
  final Random _random = Random();
  bool _isConnected = false;
  String? _walletAddress;
  int _currentBlockNumber = 1000;
  final List<BlockchainTransaction> _transactions = [];

  bool get isConnected => _isConnected;
  String? get walletAddress => _walletAddress;

  Future<void> loadContract() async {
    String abiString = await rootBundle.loadString("assets/abi.json");
    contract = DeployedContract(
      ContractAbi.fromJson(abiString, "EVoting"),
      EthereumAddress.fromHex(_contractAddress),
    );
  }

  String generateVoterHash(String voterId) => _generateHash('voter:$voterId');
  String generateCandidateHash(String candidateId) => _generateHash('candidate:$candidateId');
  
  String generateVoteHash({ 
    required String voterId, 
    required String candidateId, 
    required String electionId, 
    required DateTime timestamp, 
  }) { 
    final data = '$voterId:$candidateId:$electionId:${timestamp.millisecondsSinceEpoch}'; 
    return _generateHash(data); 
  }

  String _generateHash(String input) {
    final bytes = utf8.encode(input);
    return sha256.convert(bytes).toString();
  }

  Future<bool> connect() async {
    await Future.delayed(const Duration(milliseconds: 500));
    _walletAddress = '0x${_generateHash(_uuid.v4()).substring(0, 40)}';
    _isConnected = true;
    return true;
  }

  Future<String?> getWalletAddress() async {
    try {
    _walletAddress = _generateAddress();      
    return _walletAddress;
    } catch (e) {
      print('Error getting wallet address: $e');
      return null;
    }
  }

    String _generateAddress() =>
      '0x${_generateHash(_uuid.v4()).substring(0, 40)}';


  Future<Map<String, dynamic>> connectWallet() async {
    try {
      // This is a mock implementation since we can't interact with browser wallets directly in this environment
      // In a real app, you would use a package like 'flutter_web3' or 'wallet_connect' to interact with user wallets

      // For demo purposes, generate a random wallet address
      final address = '0x' + List.generate(40, (index) => '0123456789abcdef'[_random.nextInt(16)]).join();

      // SharedPreferences prefs = await SharedPreferences.getInstance();
      // await prefs.setString('wallet_address', address);
      

      return {
        'success': true,
        'address': address,
        'message': 'Wallet connected successfully'
      };
    } catch (e) {
      print('Error connecting wallet: $e');
      return {
        'success': false,
        'address': null,
        'message': 'Failed to connect wallet: ${e.toString()}'
      };
    }
  }


  Future<void> disconnectWallet() async {
    await Future.delayed(const Duration(milliseconds: 200));
    _walletAddress = null;
    _isConnected = false;
  }

  Future<BlockchainTransaction?> castVote({
    required String voterHash,
    required String candidateHash,
    required String electionId,
  }) async {
    if (!_isConnected) throw Exception('Not connected');
    if (contract == null) await loadContract();

    final voterBytes = Uint8List.fromList(sha256.convert(utf8.encode(voterHash)).bytes);
    final candidateBytes = Uint8List.fromList(sha256.convert(utf8.encode(candidateHash)).bytes);

    final function = contract!.function("castVote");
    final txHash = await client.sendTransaction(
      credentials,
      Transaction.callContract(
        contract: contract!,
        function: function,
        parameters: [voterBytes, candidateBytes, electionId],
      ),
      chainId: 1337,
    );

    final receipt = await client.getTransactionReceipt(txHash);
    if (receipt == null) throw Exception("Transaction failed");

    final transaction = BlockchainTransaction(
      transactionHash: txHash,
      blockHash: receipt.blockHash.toString(),
      blockNumber: receipt.blockNumber.blockNum,
      from: credentials.address.hex,
      to: _contractAddress,
      data: 'castVote($electionId)',
      timestamp: DateTime.now(),
      status: receipt.status ?? false,
    );

    _transactions.add(transaction);
    return transaction;
  }

  Future<void> createElectionOnBlockchain(String electionId) async {
    if (contract == null) await loadContract();
    final function = contract!.function("createElection");
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final end = now + (30 * 24 * 3600); // 30 days default

    await client.sendTransaction(
      credentials,
      Transaction.callContract(
        contract: contract!,
        function: function,
        parameters: [electionId, BigInt.from(now), BigInt.from(end)],
      ),
      chainId: 1337,
    );
  }

  Future<BlockchainTransaction?> getTransaction(String transactionHash) async { 
    try { 
      return _transactions.firstWhere((t) => t.transactionHash == transactionHash); 
    } catch (e) { 
      return null; 
    } 
  }

  Future<bool> verifyTransaction(String transactionHash) async {
    try {
      final receipt = await client.getTransactionReceipt(transactionHash);
      return receipt != null && (receipt.status ?? false);
    } catch (e) {
      print('Blockchain verification error: $e');
      
      return false;
    }
  }
}
