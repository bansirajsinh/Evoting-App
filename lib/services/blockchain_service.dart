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

class VoteRecord {
  final String voterHash;
  final String candidateHash;
  final String electionId;
  final String transactionHash;
  final int blockNumber;
  final DateTime timestamp;

  VoteRecord({
    required this.voterHash,
    required this.candidateHash,
    required this.electionId,
    required this.transactionHash,
    required this.blockNumber,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'voterHash': voterHash,
      'candidateHash': candidateHash,
      'electionId': electionId,
      'transactionHash': transactionHash,
      'blockNumber': blockNumber,
      'timestamp': timestamp.toIso8601String(),
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

  // Default fallback values
  final String _defaultRpcUrl = "http://10.137.177.71:7545";
  final String _defaultPrivateKey =
      "0x032063a0fa88f352441840f26a74397f3906de147b0008fc322375c12656e5dc";
  final String _defaultContractAddress =
      "0x4cC35bE54c358146E7b71E58f965532193848FDd";

  // Current values
  late String _rpcUrl;
  late String _privateKey;
  late String _contractAddress;

FirestoreService? _firestoreService;

FirestoreService get firestoreService =>
    _firestoreService ??= FirestoreService();

  // Getters for current values
  String get rpcUrl => _rpcUrl;
  String get privateKey => _privateKey;
  String get contractAddress => _contractAddress;

  // Stream getters for reactive updates
  Stream<String> getRpcUrlStream() {
    return firestoreService.getHostCredentialsStream().map((data) {
      final url = "http://${data['hostIp'] ?? '10.137.177.71'}:7545";
      _updateRpcUrl(url);
      return url;
    }).handleError((_) => _defaultRpcUrl);
  }

  Stream<String> getPrivateKeyStream() {
    return firestoreService.getHostCredentialsStream().map((data) {
      final key = data['privateKey'] as String? ?? _defaultPrivateKey;
      _updatePrivateKey(key);
      return key;
    }).handleError((_) => _defaultPrivateKey);
  }

  Stream<String> getContractAddressStream() {
    return firestoreService.getHostCredentialsStream().map((data) {
      final address = data['contractAddress'] as String? ?? _defaultContractAddress;
      _updateContractAddress(address);
      return address;
    }).handleError((_) => _defaultContractAddress);
  }

  // Combined stream for all config updates
  Stream<Map<String, String>> getConfigStream() {
    return firestoreService.getHostCredentialsStream().map((data) {
      final url = "http://${data['hostIp'] ?? '10.137.177.71'}:7545";
      final key = data['privateKey'] as String? ?? _defaultPrivateKey;
      final address = data['contractAddress'] as String? ?? _defaultContractAddress;

      _updateRpcUrl(url);
      _updatePrivateKey(key);
      _updateContractAddress(address);

      return {
        'rpcUrl': url,
        'privateKey': key,
        'contractAddress': address,
      };
    }).handleError((_) => {
      'rpcUrl': _defaultRpcUrl,
      'privateKey': _defaultPrivateKey,
      'contractAddress': _defaultContractAddress,
    });
  }

  void _updateRpcUrl(String newUrl) {
    if (_rpcUrl != newUrl) {
      _rpcUrl = newUrl;
      client = Web3Client(newUrl, Client());
    }
  }

  void _updatePrivateKey(String newKey) {
    if (_privateKey != newKey) {
      _privateKey = newKey;
      credentials = EthPrivateKey.fromHex(newKey);
    }
  }

  void _updateContractAddress(String newAddress) {
    _contractAddress = newAddress;
  }

  BlockchainService._internal() {
    // Initialize with defaults
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

  // final Map<String, VoteRecord> _voteRecords = {};
  final Map<String, bool> _registeredVoters = {};
  final List<BlockchainTransaction> _transactions = [];

  bool get isConnected => _isConnected;
  String? get walletAddress => _walletAddress;


  Future<String?> getWalletAddress() async {
    try {
    _walletAddress = _generateAddress();      
    return _walletAddress;
    } catch (e) {
      print('Error getting wallet address: $e');
      return null;
    }
  }

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

  Future<Map<String, String>> generateSecureHash(String password) async {
    try {
      // Generate a random salt
      final saltBytes = List<int>.generate(32, (_) => _random.nextInt(256));
      final salt = base64.encode(saltBytes);

      // Hash the password with the salt
      final passwordBytes = utf8.encode(password);
      final saltedBytes = [...passwordBytes, ...saltBytes];
      final hash = sha256.convert(saltedBytes).toString();

      return {
        'hash': hash,
        'salt': salt,
      };
    } catch (e) {
      print('Error generating secure hash: $e');
      throw Exception("Failed to generate secure hash: ${e.toString()}");
    }
  }


  Future<bool> storeHashOnBlockchain(String aadhaarNumber, String hash) async {
    try {
      // In a real app, this would interact with a smart contract
      // For demo, we store in a collection simulating blockchain storage
      // await _db.collection('blockchain_data').doc(aadhaarNumber).set({
      //   'hash': hash,
      //   'timestamp': FieldValue.serverTimestamp(),
      //   'type': 'credential_hash',
      // });

      return true;
    } catch (e) {
      print('Error storing hash on blockchain: $e');
      return false;
    }
  }

  Future<bool> storeSaltInFirebase(String aadhaarNumber, String salt) async {
    try {
      // await _firestore.collection('user_security').doc(aadhaarNumber).set({
      //   'salt': salt,
      //   'created': FieldValue.serverTimestamp(),
      //   'lastUpdated': FieldValue.serverTimestamp(),
      // });

      return true;
    } catch (e) {
      print('Error storing salt in Firebase: $e');
      return false;
    }
  }

  Future<bool> disconnectWallet() async {
    try {
      // SharedPreferences prefs = await SharedPreferences.getInstance();
      // await prefs.remove('wallet_address');
      return true;
    } catch (e) {
      print('Error disconnecting wallet: $e');
      return false;
    }
  }

  Future<bool> isWalletConnected() async {
    try {
      // SharedPreferences prefs = await SharedPreferences.getInstance();
      // return prefs.containsKey('wallet_address') && prefs.getString('wallet_address')!.isNotEmpty;
      return true;
    } catch (e) {
      print('Error checking wallet connection: $e');
      return false;
    }
  }

  String generateSecurityMessage() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'E-Vote Authentication Request: $timestamp';
  }


    Future<String> signMessage(String message) async {
    try {
      // In a real app, this would interact with the wallet to sign the message
      // For demo, we're creating a mock signature
      final address = await getWalletAddress();
      if (address == null) {
        throw Exception("No wallet connected");
      }

      final bytes = utf8.encode(message);
      final digest = sha256.convert(bytes);

      // Mock signature - in reality, this would come from the wallet
      return '0x' + digest.toString() + address.substring(2, 10);
    } catch (e) {
      print('Error signing message: $e');
      throw Exception("Failed to sign message: ${e.toString()}");
    }
  }



  Future<bool> verifySignature(String message, String signature, String address) async {
    try {
      // In a real app, this would verify cryptographically
      // For demo, we check if the signature contains parts of the address
      return signature.contains(address.substring(2, 10));
    } catch (e) {
      print('Error verifying signature: $e');
      return false;
    }
  }


    Future<String?> getSaltFromFirebase(String aadhaarNumber) async {
    try {
      // final doc = await _firestore.collection('user_security').doc(aadhaarNumber).get();

      // if (!doc.exists || !doc.data()!.containsKey('salt')) {
      //   return null;
      // }

      // return doc.data()!['salt'] as String;
      return null;
    } catch (e) {
      print('Error getting salt from Firebase: $e');
      return null;
    }
  }

    Future<String?> getHashFromBlockchain(String aadhaarNumber) async {
    try {
      // In a real app, this would query the blockchain
      // For demo, we query our simulated blockchain collection
      // final doc = await _firestore.collection('blockchain_data').doc(aadhaarNumber).get();

      // if (!doc.exists || !doc.data()!.containsKey('hash')) {
      //   return null;
      // }

      // return doc.data()!['hash'] as String;
      return null;
    } catch (e) {
      print('Error getting hash from blockchain: $e');
      return null;
    }
  }


    Future<String> computePasswordHash(String password, String salt) async {
    try {
      final passwordBytes = utf8.encode(password);
      final saltBytes = base64.decode(salt);
      final saltedBytes = [...passwordBytes, ...saltBytes];

      return sha256.convert(saltedBytes).toString();
    } catch (e) {
      print('Error computing password hash: $e');
      throw Exception("Failed to compute password hash: ${e.toString()}");
    }
  }




//===========================================================================================================================
  Future<void> loadContract() async {
    print('\x1B[32m'
    'lib/services/blockchain_service.dart: loadContract() executed'
    '\x1B[0m');
    String abiString = await rootBundle.loadString("assets/abi.json");

    contract = DeployedContract(
      ContractAbi.fromJson(abiString, "EVoting"),
      EthereumAddress.fromHex(_contractAddress),
    );
  }


  Future<bool> verifyTransaction(String transactionHash) async { 
    print('\x1B[32m'
    'lib/services/blockchain_service.dart: loadContract() executed'
    '\x1B[0m'); 
    await Future.delayed(const Duration(milliseconds: 300)); 
    final tx = await getTransaction(transactionHash); 
    return tx != null && tx.status; 
  }

  String generateVoteHash({ 
    required String voterId, 
    required String candidateId, 
    required String electionId, 
    required DateTime timestamp, 
    }) { 
    print('\x1B[32m'
    'lib/services/blockchain_service.dart: generateVoteHash() executed'
    '\x1B[0m');
      final data = '$voterId:$candidateId:$electionId:${timestamp.millisecondsSinceEpoch}'; 
      return _generateHash(data); 
  }

  String generateCandidateHash(String candidateId) { 
    print('\x1B[32m'
    'lib/services/blockchain_service.dart: generateCandidateHash() executed'
    '\x1B[0m');

    try{

      return _generateHash('candidate:$candidateId'); 

    }catch(err){
      print('\x1B[31m'
    'lib/services/blockchain_service.dart: generateCandidateHash() fail'
    '\x1B[0m');
    print(err);

    return"";

    }
  }

  String generateVoterHash(String voterId) { 

    print('\x1B[32m'
    'lib/services/blockchain_service.dart: generateVoterHash() executed'
    '\x1B[0m');


    try{

      return _generateHash('voter:$voterId'); 

    }catch(err){

      print('\x1B[31m'
      'lib/services/blockchain_service.dart: generateVoterHash() fail'
      '\x1B[0m');
      print(err);
      

      return "";

    }
  }

  String _generateHash(String input) {
    print('\x1B[32m'
    'lib/services/blockchain_service.dart: _generateHash() executed'
    '\x1B[0m');

    try{

    final bytes = utf8.encode(input);
    return sha256.convert(bytes).toString();

    }catch(err){

      print('\x1B[31m'
    'lib/services/blockchain_service.dart: _generateHash() fail'
    '\x1B[0m');
    print(err);

    return"";

    }
  }
// need debug call
  String _generateTransactionHash() =>
      '0x${_generateHash(_uuid.v4()).substring(0, 64)}';
// need debug call
  String _generateBlockHash() =>
      '0x${_generateHash(_uuid.v4()).substring(0, 64)}';
// need debug call
  String _generateAddress() =>
      '0x${_generateHash(_uuid.v4()).substring(0, 40)}';

  Future<bool> connect() async {
    print('\x1B[32m'
    'lib/services/blockchain_service.dart: connect() executed'
    '\x1B[0m');
    await Future.delayed(const Duration(milliseconds: 500));
    _walletAddress = _generateAddress();
    _isConnected = true;
    return true;
  }

  Future<bool> registerVoter(String voterHash) async {
    print('\x1B[32m'
    'lib/services/blockchain_service.dart: registerVoter() executed'
    '\x1B[0m');
    if (!_isConnected) {
      throw Exception('Not connected');
    }

    if (_registeredVoters.containsKey(voterHash)) {
      return false;
    }

    _registeredVoters[voterHash] = true;
    _currentBlockNumber++;

    final tx = BlockchainTransaction(
      transactionHash: _generateTransactionHash(),
      blockHash: _generateBlockHash(),
      blockNumber: _currentBlockNumber,
      from: _walletAddress ?? '',
      to: contractAddress,
      data: 'registerVoter',
      timestamp: DateTime.now(),
      status: true,
    );

    _transactions.add(tx);
    return true;
  }

  Future<BlockchainTransaction?> castVote({
    required String voterHash,
    required String candidateHash,
    required String electionId,
  }) async {
    print('\x1B[32m'
    'lib/services/blockchain_service.dart: castVote() executed'
    '\x1B[0m');
    
    if (!_isConnected) {
      throw Exception('Not connected');
    }

    if (contract == null) {
      await loadContract();
    }

    final voterBytes =
        Uint8List.fromList(sha256.convert(utf8.encode(voterHash)).bytes);

    final candidateBytes =
        Uint8List.fromList(sha256.convert(utf8.encode(candidateHash)).bytes);

//safe_______________________________________________________________________________________
    

    final function = contract!.function("castVote");

print("CHECKPOINT:01 CODE HERE REACHED!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!11");
print("electionid:$electionId");
print("___________________________________________________________________________________");
print("credentials:$credentials");
print("function:$function");
print("voterBytes:$voterBytes");
print("candidateBytes:$candidateBytes");
print("electionId:$electionId");
print("___________________________________________________________________________________");


      final txHash = await client.sendTransaction(
      credentials,
      Transaction.callContract(
        contract: contract!,
        function: function,
        parameters: [voterBytes, candidateBytes, electionId],
      ),
      chainId: 1337,
    );

print("CHECKPOINT:02 CODE HERE REACHED!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!11");

    final receipt =
        await client.getTransactionReceipt(txHash);

print("CHECKPOINT:03 CODE HERE REACHED!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!11");

    if (receipt == null) {
      throw Exception("Transaction failed");
    }

print("CHECKPOINT:04 CODE HERE REACHED!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!11");

    final senderAddress = credentials.address;

print("CHECKPOINT:05 CODE HERE REACHED!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!11");

    final transaction = BlockchainTransaction(
      transactionHash: txHash,
      blockHash: receipt.blockHash.toString(),
      blockNumber:
          receipt.blockNumber.blockNum,
      from: senderAddress.hex,
      to: contractAddress,
      data: 'castVote',
      timestamp: DateTime.now(),
      status: receipt.status ?? false,
    );

    print("CHECKPOINT:06 CODE HERE REACHED!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!11");

        _transactions.add(transaction);

    print("CHECKPOINT:07 CODE HERE REACHED!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!11");

    return transaction;
  }

  Future<void> createElectionOnBlockchain(String electionId) async {
    print('\x1B[32m'
    'lib/services/blockchain_service.dart: createElectionOnBlockchain() executed'
    '\x1B[0m');

    if (contract == null) {
    await loadContract();
  }

  final function = contract!.function("createElection");

  final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
  final end = now + 3600;


  await client.sendTransaction(
    credentials,
    Transaction.callContract(
      contract: contract!,
      function: function,
      parameters: [
        electionId,
        BigInt.from(now),
        BigInt.from(end)
      ],
    ),
    chainId: 1337,
  );


  print("✅ Blockchain election created: $electionId");
}

  validateBlockchainIntegrity(String electionId) async { 
    print('\x1B[32m'
    'lib/services/blockchain_service.dart: validateBlockchainIntegrity() executed'
    '\x1B[0m');
    await Future.delayed(const Duration(milliseconds: 500)); 
    return true; 
  }

  Future<BlockchainTransaction?> getTransaction(String transactionHash) async { 
    print('\x1B[32m'
    'lib/services/blockchain_service.dart: getTransaction() executed'
    '\x1B[0m');
    await Future.delayed(const Duration(milliseconds: 200)); 
    try { 
      return _transactions.firstWhere((t) => t.transactionHash == transactionHash); 
    } catch (e) { 
        return null; 
    } 
  } 

  Future<List<BlockchainTransaction>>getTransactionHistory() async {
        print('\x1B[32m'
        'lib/services/blockchain_service.dart: getTransactionHistory() executed'
        '\x1B[0m');
    return List.from(_transactions.reversed);
  }

  Future<int> getBlockNumber() async {
    print('\x1B[32m'
    'lib/services/blockchain_service.dart: getBlockNumber() executed'
    '\x1B[0m');
    return _currentBlockNumber;
  }

  Future<String?> getBalance() async {
    print('\x1B[32m'
    'lib/services/blockchain_service.dart: getBalance() executed'
    '\x1B[0m');
    if (!_isConnected) return null;
    return '${(_random.nextDouble() * 100).toStringAsFixed(4)} ETH';
  }
}
