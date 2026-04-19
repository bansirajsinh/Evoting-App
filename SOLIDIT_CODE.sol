// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title EVoting Smart Contract
 * @author E-Vote System
 * @notice A secure blockchain-based voting system
 * @dev Implements voter registration, vote casting, and result tallying
 */
contract EVoting {
    
    // Contract owner
    address public owner;
    
    // Struct to store vote information
    struct VoteInfo {
        bytes32 candidateHash;
        uint256 timestamp;
        bool exists;
    }
    
    // Struct to store election information
    struct Election {
        string electionId;
        bool isActive;
        uint256 startTime;
        uint256 endTime;
        uint256 totalVotes;
    }
    
    // Mapping of voter hash to registration status
    mapping(bytes32 => bool) public registeredVoters;
    
    // Mapping of voter hash + election ID to vote info
    // Key: keccak256(voterHash, electionId)
    mapping(bytes32 => VoteInfo) public votes;
    
    // Mapping of election ID to election info
    mapping(string => Election) public elections;
    
    // Mapping of candidate hash to vote count per election
    // Key: keccak256(candidateHash, electionId)
    mapping(bytes32 => uint256) public candidateVotes;
    
    // Array to store all candidate hashes for an election
    mapping(string => bytes32[]) public electionCandidates;
    
    // Events
    event VoterRegistered(bytes32 indexed voterHash, uint256 timestamp);
    event VoteCast(
        bytes32 indexed voterHash,
        bytes32 indexed candidateHash,
        string indexed electionId,
        uint256 timestamp
    );
    event ElectionCreated(string electionId, uint256 startTime, uint256 endTime);
    event ElectionStatusChanged(string electionId, bool isActive);
    
    // Modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can perform this action");
        _;
    }
    
    modifier electionExists(string memory electionId) {
        require(bytes(elections[electionId].electionId).length > 0, "Election does not exist");
        _;
    }
    
    modifier electionActive(string memory electionId) {
        require(elections[electionId].isActive, "Election is not active");
        require(block.timestamp >= elections[electionId].startTime, "Election has not started");
        require(block.timestamp <= elections[electionId].endTime, "Election has ended");
        _;
    }
    
    /**
     * @dev Constructor sets the contract owner
     */
    constructor() {
        owner = msg.sender;
    }
    
    /**
     * @dev Create a new election
     * @param electionId Unique identifier for the election
     * @param startTime Unix timestamp for election start
     * @param endTime Unix timestamp for election end
     */
    function createElection(
        string memory electionId,
        uint256 startTime,
        uint256 endTime
    ) external onlyOwner {
        require(bytes(elections[electionId].electionId).length == 0, "Election already exists");
        require(startTime < endTime, "Invalid time range");
        require(endTime > block.timestamp, "End time must be in the future");
        
        elections[electionId] = Election({
            electionId: electionId,
            isActive: true,
            startTime: startTime,
            endTime: endTime,
            totalVotes: 0
        });
        
        emit ElectionCreated(electionId, startTime, endTime);
    }
    
    /**
     * @dev Set election active status
     * @param electionId The election ID
     * @param isActive New active status
     */
    function setElectionStatus(string memory electionId, bool isActive) 
        external 
        onlyOwner 
        electionExists(electionId) 
    {
        elections[electionId].isActive = isActive;
        emit ElectionStatusChanged(electionId, isActive);
    }
    
    /**
     * @dev Register a voter using their hashed identity
     * @param voterHash SHA-256 hash of voter's identity (Aadhaar)
     * @return success Boolean indicating registration success
     */
    function registerVoter(bytes32 voterHash) external returns (bool success) {
        require(voterHash != bytes32(0), "Invalid voter hash");
        require(!registeredVoters[voterHash], "Voter already registered");
        
        registeredVoters[voterHash] = true;
        
        emit VoterRegistered(voterHash, block.timestamp);
        
        return true;
    }
    
    /**
     * @dev Check if a voter is registered
     * @param voterHash The voter's hash
     * @return Boolean indicating if voter is registered
     */
    function isRegistered(bytes32 voterHash) external view returns (bool) {
        return registeredVoters[voterHash];
    }
    
    /**
     * @dev Cast a vote for a candidate in an election
     * @param voterHash Hash of the voter's identity
     * @param candidateHash Hash of the candidate's identity
     * @param electionId The election identifier
     * @return success Boolean indicating vote success
     */
    function castVote(
        bytes32 voterHash,
        bytes32 candidateHash,
        string memory electionId
    ) 
        external 
        electionExists(electionId)
        electionActive(electionId)
        returns (bool success) 
    {
        require(voterHash != bytes32(0), "Invalid voter hash");
        require(candidateHash != bytes32(0), "Invalid candidate hash");
        require(registeredVoters[voterHash], "Voter not registered");
        
        // Create unique key for this voter's vote in this election
        bytes32 voteKey = keccak256(abi.encodePacked(voterHash, electionId));
        require(!votes[voteKey].exists, "Voter has already voted in this election");
        
        // Record the vote
        votes[voteKey] = VoteInfo({
            candidateHash: candidateHash,
            timestamp: block.timestamp,
            exists: true
        });
        
        // Increment candidate vote count
        bytes32 candidateKey = keccak256(abi.encodePacked(candidateHash, electionId));
        candidateVotes[candidateKey]++;
        
        // Increment total votes for election
        elections[electionId].totalVotes++;
        
        // Track candidate in election if not already tracked
        bool candidateTracked = false;
        bytes32[] storage candidates = electionCandidates[electionId];
        for (uint i = 0; i < candidates.length; i++) {
            if (candidates[i] == candidateHash) {
                candidateTracked = true;
                break;
            }
        }
        if (!candidateTracked) {
            electionCandidates[electionId].push(candidateHash);
        }
        
        emit VoteCast(voterHash, candidateHash, electionId, block.timestamp);
        
        return true;
    }
    
    /**
     * @dev Check if a voter has voted in a specific election
     * @param voterHash The voter's hash
     * @param electionId The election identifier
     * @return Boolean indicating if voter has voted
     */
    function hasVoted(bytes32 voterHash, string memory electionId) 
        external 
        view 
        returns (bool) 
    {
        bytes32 voteKey = keccak256(abi.encodePacked(voterHash, electionId));
        return votes[voteKey].exists;
    }
    
    /**
     * @dev Get vote count for a specific candidate in an election
     * @param candidateHash The candidate's hash
     * @param electionId The election identifier
     * @return Vote count for the candidate
     */
    function getCandidateVotes(bytes32 candidateHash, string memory electionId)
        external
        view
        returns (uint256)
    {
        bytes32 candidateKey = keccak256(abi.encodePacked(candidateHash, electionId));
        return candidateVotes[candidateKey];
    }
    
    /**
     * @dev Get results for an election
     * @param electionId The election identifier
     * @return candidateHashes Array of candidate hashes
     * @return voteCounts Array of vote counts corresponding to each candidate
     */
    function getResults(string memory electionId)
        external
        view
        electionExists(electionId)
        returns (bytes32[] memory candidateHashes, uint256[] memory voteCounts)
    {
        bytes32[] storage candidates = electionCandidates[electionId];
        uint256 length = candidates.length;
        
        candidateHashes = new bytes32[](length);
        voteCounts = new uint256[](length);
        
        for (uint i = 0; i < length; i++) {
            candidateHashes[i] = candidates[i];
            bytes32 candidateKey = keccak256(abi.encodePacked(candidates[i], electionId));
            voteCounts[i] = candidateVotes[candidateKey];
        }
        
        return (candidateHashes, voteCounts);
    }
    
    /**
     * @dev Get election information
     * @param electionId The election identifier
     * @return Election struct containing election details
     */
    function getElection(string memory electionId)
        external
        view
        electionExists(electionId)
        returns (
            string memory,
            bool,
            uint256,
            uint256,
            uint256
        )
    {
        Election storage e = elections[electionId];
        return (e.electionId, e.isActive, e.startTime, e.endTime, e.totalVotes);
    }
    
    /**
     * @dev Get total number of votes in an election
     * @param electionId The election identifier
     * @return Total number of votes cast
     */
    function getTotalVotes(string memory electionId)
        external
        view
        electionExists(electionId)
        returns (uint256)
    {
        return elections[electionId].totalVotes;
    }
    
    /**
     * @dev Transfer contract ownership
     * @param newOwner Address of the new owner
     */
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Invalid address");
        owner = newOwner;
    }
}
